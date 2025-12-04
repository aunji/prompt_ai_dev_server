//+------------------------------------------------------------------+
//|                                              RebateEngineV1.mq4 |
//|                                      Copyright 2025, Aunji Team |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Aunji Team"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

// General
input int    MagicNumber              = 202501;
input string TradeSymbol              = "XAUUSD";
input bool   OnlyCurrentSymbol        = true;

// Session control
input bool   UseTradingSession        = true;
input int    SessionStartHour         = 2;    // server time
input int    SessionEndHour           = 22;   // server time

// Rebate & Target (for stats)
input double RebatePerLotUSD          = 7.0;
input double DailyRebateTargetUSD     = 100.0;

// Risk & Margin (Account-level)
input double MaxDrawdownPercent       = 40.0;
input double MinMarginLevelPercent    = 250.0;

// Basket-level risk
input double BasketMaxDDPercent       = 15.0;
input double BasketTP_EquityPercent   = 0.7;
input double BasketTP_Money           = 0.0;

// Lots & Scaling
input double BaseLot                  = 0.03;
input double GridLotFactor            = 1.2;
input double MaxTotalLots             = 5.0;
input int    MaxOpenOrders            = 50;

// Micro Entry
input bool   UseMicroEntries          = true;
input int    MicroDistancePoints      = 300;
input int    MicroCooldownBars        = 1;

// Grid Entry
input bool   UseGrid                  = true;
input int    GridStepPoints           = 500;
input int    MaxGridDepth             = 7;

// Smart Hedge (Partial)
input bool   UseHedge                 = true;
input double HedgeDDTriggerPercent    = 8.0;
input double HedgeMarginTriggerLevel  = 400.0;
input double HedgeLotFactor           = 0.5;
input int    MinBarsBetweenHedges     = 5;

// Trend / Zone Filters
input bool   UseTrendFilter           = true;
input ENUM_TIMEFRAMES TrendTF         = PERIOD_H4;
input int    TrendLookbackBars        = 20;

// Basket close conditions
input bool   CloseBasketOnTrendFlip   = true;
input bool   CloseBasketOnOppZoneHit  = true;

// Weekend Protection
input bool   UseWeekendProtection     = true;
input int    FridayStopHour           = 21;
input int    FridayZeroHedgeHour      = 22;
input int    MaxSpreadForTrading      = 150;

// Recovery Engine
input bool   UseRecoveryEngine        = true;
input double DefaultBasketTPPercent   = 0.7;
input double RecoveryMaxBoostPercent  = 0.5;
input int    RecoveryBasketDivider    = 20;

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+

double BasketStartEquity = 0;
double RecoveryLoss = 0;
datetime BasketStartTime = 0;
datetime LastMicroEntryTime = 0;
datetime LastHedgeTime = 0;
bool BlockNewEntries = false;
int LastGridLevel = 0;
double TotalLotsToday = 0;
datetime LastDayReset = 0;

//+------------------------------------------------------------------+
//| STRUCTURES                                                       |
//+------------------------------------------------------------------+

struct BasketState
{
   int    direction;        // 1 = Buy, -1 = Sell, 0 = None
   double totalLotsDir;     // main direction lots
   double totalLotsHedge;   // hedge lots
   double totalLotsAll;
   double floatingProfit;
   double ddPercent;
   double avgPriceDir;
   double avgPriceHedge;
   datetime lastHedgeOpenTime;
   int    openOrders;
   int    gridDepth;
};

//+------------------------------------------------------------------+
//| EXPERT INITIALIZATION FUNCTION                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("RebateEngineV1 initialized on ", Symbol());
   Print("Magic Number: ", MagicNumber);
   Print("Base Lot: ", BaseLot);

   if(RecoveryLoss > 0)
      Print("Recovery Mode Active - Loss to recover: $", DoubleToStr(RecoveryLoss, 2));

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| EXPERT DEINITIALIZATION FUNCTION                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   Print("RebateEngineV1 stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| EXPERT TICK FUNCTION                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Daily lot counter reset
   ResetDailyLotCounter();

   // Symbol validation
   if(!IsOurSymbol()) return;

   // Session check
   if(!IsTradeAllowedNow()) return;

   // Global risk limits
   if(!CheckGlobalRiskLimits()) return;

   // Weekend protection
   if(UseWeekendProtection)
      HandleWeekendProtection();

   // Main basket management
   if(HasOpenBasket())
   {
      ManageHedge();
      ManageGrid();
      ManageMicroFills();
      TryCloseBasket();
   }
   else
   {
      TryOpenNewBasket();
   }

   // Update dashboard
   UpdateDashboard();
}

//+------------------------------------------------------------------+
//| UTILITY FUNCTIONS                                                |
//+------------------------------------------------------------------+

bool IsOurSymbol()
{
   if(OnlyCurrentSymbol && Symbol() != TradeSymbol)
      return false;
   return true;
}

bool IsTradeAllowedNow()
{
   if(!UseTradingSession) return true;

   int hour = TimeHour(TimeCurrent());
   if(hour >= SessionStartHour && hour < SessionEndHour)
      return true;

   return false;
}

bool CheckGlobalRiskLimits()
{
   // Check account drawdown
   double accDD = GetAccountDDPercent();
   if(accDD > MaxDrawdownPercent)
   {
      Print("EMERGENCY: Account DD exceeded ", MaxDrawdownPercent, "% - Closing all positions!");
      CloseAllOrders();
      return false;
   }

   // Check margin level
   double marginLevel = GetMarginLevel();
   if(marginLevel < MinMarginLevelPercent && marginLevel > 0)
   {
      Print("WARNING: Low margin level: ", DoubleToStr(marginLevel, 2), "%");
      BlockNewEntries = true;
   }
   else
   {
      if(BlockNewEntries && marginLevel > MinMarginLevelPercent + 50)
         BlockNewEntries = false;
   }

   return true;
}

double GetAccountDDPercent()
{
   double balance = AccountBalance();
   double equity = AccountEquity();

   if(balance <= 0) return 0;

   double dd = ((balance - equity) / balance) * 100.0;
   return dd > 0 ? dd : 0;
}

double GetMarginLevel()
{
   double margin = AccountMargin();
   if(margin == 0) return 10000;

   return (AccountEquity() / margin) * 100.0;
}

int GetCurrentSpreadPoints()
{
   return (int)((Ask - Bid) / Point);
}

double NormalizeLot(double lot)
{
   double minLot = MarketInfo(TradeSymbol, MODE_MINLOT);
   double maxLot = MarketInfo(TradeSymbol, MODE_MAXLOT);
   double lotStep = MarketInfo(TradeSymbol, MODE_LOTSTEP);

   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);
   lot = NormalizeDouble(lot / lotStep, 0) * lotStep;

   return lot;
}

void ResetDailyLotCounter()
{
   datetime today = iTime(Symbol(), PERIOD_D1, 0);
   if(LastDayReset != today)
   {
      TotalLotsToday = 0;
      LastDayReset = today;
   }
}

//+------------------------------------------------------------------+
//| BASKET STATE FUNCTIONS                                           |
//+------------------------------------------------------------------+

BasketState GetBasketState()
{
   BasketState state;
   state.direction = 0;
   state.totalLotsDir = 0;
   state.totalLotsHedge = 0;
   state.totalLotsAll = 0;
   state.floatingProfit = 0;
   state.ddPercent = 0;
   state.avgPriceDir = 0;
   state.avgPriceHedge = 0;
   state.lastHedgeOpenTime = LastHedgeTime;
   state.openOrders = 0;
   state.gridDepth = 0;

   double totalBuyLots = 0, totalSellLots = 0;
   double buyWeightedPrice = 0, sellWeightedPrice = 0;
   double buyProfit = 0, sellProfit = 0;
   int buyCount = 0, sellCount = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;

      double lots = OrderLots();
      double profit = OrderProfit() + OrderSwap() + OrderCommission();

      if(OrderType() == OP_BUY)
      {
         totalBuyLots += lots;
         buyWeightedPrice += OrderOpenPrice() * lots;
         buyProfit += profit;
         buyCount++;
      }
      else if(OrderType() == OP_SELL)
      {
         totalSellLots += lots;
         sellWeightedPrice += OrderOpenPrice() * lots;
         sellProfit += profit;
         sellCount++;
      }

      state.openOrders++;
      state.floatingProfit += profit;
   }

   state.totalLotsAll = totalBuyLots + totalSellLots;

   // Determine direction
   if(totalBuyLots > totalSellLots * 1.5)
   {
      state.direction = 1;
      state.totalLotsDir = totalBuyLots;
      state.totalLotsHedge = totalSellLots;
      if(totalBuyLots > 0)
         state.avgPriceDir = buyWeightedPrice / totalBuyLots;
      if(totalSellLots > 0)
         state.avgPriceHedge = sellWeightedPrice / totalSellLots;
   }
   else if(totalSellLots > totalBuyLots * 1.5)
   {
      state.direction = -1;
      state.totalLotsDir = totalSellLots;
      state.totalLotsHedge = totalBuyLots;
      if(totalSellLots > 0)
         state.avgPriceDir = sellWeightedPrice / totalSellLots;
      if(totalBuyLots > 0)
         state.avgPriceHedge = buyWeightedPrice / totalBuyLots;
   }

   // Calculate DD
   if(BasketStartEquity > 0)
   {
      double currentEquity = AccountEquity();
      state.ddPercent = ((BasketStartEquity - currentEquity) / BasketStartEquity) * 100.0;
      if(state.ddPercent < 0) state.ddPercent = 0;
   }

   return state;
}

bool HasOpenBasket()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() == MagicNumber && OrderSymbol() == TradeSymbol)
         return true;
   }
   return false;
}

void UpdateBasketStartEquityIfNeeded()
{
   if(!HasOpenBasket())
   {
      BasketStartEquity = AccountEquity();
      BasketStartTime = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| ORDER MANAGEMENT FUNCTIONS                                       |
//+------------------------------------------------------------------+

bool OpenOrder(int type, double lots, string comment)
{
   if(BlockNewEntries) return false;

   // Check spread
   if(GetCurrentSpreadPoints() > MaxSpreadForTrading)
   {
      Print("Spread too high: ", GetCurrentSpreadPoints(), " points");
      return false;
   }

   // Normalize lot
   lots = NormalizeLot(lots);
   if(lots < MarketInfo(TradeSymbol, MODE_MINLOT))
      return false;

   // Check max lots
   BasketState state = GetBasketState();
   if(state.totalLotsAll + lots > MaxTotalLots)
   {
      Print("Max total lots reached: ", MaxTotalLots);
      return false;
   }

   // Check max orders
   if(state.openOrders >= MaxOpenOrders)
   {
      Print("Max open orders reached: ", MaxOpenOrders);
      return false;
   }

   double price = (type == OP_BUY) ? Ask : Bid;
   int slippage = 30;

   int ticket = OrderSend(TradeSymbol, type, lots, price, slippage, 0, 0, comment, MagicNumber, 0, clrNONE);

   if(ticket > 0)
   {
      Print("Order opened: ", comment, " Type: ", type, " Lots: ", lots, " Price: ", price);
      TotalLotsToday += lots;

      // Update basket start equity if this is first order
      UpdateBasketStartEquityIfNeeded();

      return true;
   }
   else
   {
      Print("Order failed: ", GetLastError(), " - ", comment);
      return false;
   }
}

void CloseAllOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;

      CloseOrder(OrderTicket());
   }
}

bool CloseOrder(int ticket)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return false;

   double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
   bool result = OrderClose(ticket, OrderLots(), closePrice, 30, clrNONE);

   if(!result)
      Print("Failed to close order: ", ticket, " Error: ", GetLastError());

   return result;
}

void CloseBasket()
{
   BasketState state = GetBasketState();
   double profit = state.floatingProfit;

   Print("Closing basket - Profit: $", DoubleToStr(profit, 2), " Orders: ", state.openOrders);

   CloseAllOrders();

   // Handle recovery
   OnBasketClosed(profit);

   // Reset basket variables
   BasketStartEquity = 0;
   BasketStartTime = 0;
   LastGridLevel = 0;
}

//+------------------------------------------------------------------+
//| BASKET OPENING LOGIC                                             |
//+------------------------------------------------------------------+

void TryOpenNewBasket()
{
   if(BlockNewEntries) return;

   // Determine direction based on market structure
   int direction = DetermineMarketDirection();

   if(direction == 0) return; // No clear direction

   // Open first micro entry
   int orderType = (direction == 1) ? OP_BUY : OP_SELL;
   string comment = (direction == 1) ? "MICRO_BUY_INIT" : "MICRO_SELL_INIT";

   if(OpenOrder(orderType, BaseLot, comment))
   {
      Print("New basket opened - Direction: ", (direction == 1 ? "BUY" : "SELL"));
   }
}

int DetermineMarketDirection()
{
   if(!UseTrendFilter)
      return (MathRand() % 2 == 0) ? 1 : -1; // Random if no filter

   // Simple trend detection using moving averages
   double ma20 = iMA(TradeSymbol, TrendTF, TrendLookbackBars, 0, MODE_SMA, PRICE_CLOSE, 0);
   double ma50 = iMA(TradeSymbol, TrendTF, TrendLookbackBars * 2, 0, MODE_SMA, PRICE_CLOSE, 0);

   double currentPrice = (Ask + Bid) / 2;

   // Bullish: Price above MAs and MA20 > MA50
   if(currentPrice > ma20 && ma20 > ma50)
      return 1;

   // Bearish: Price below MAs and MA20 < MA50
   if(currentPrice < ma20 && ma20 < ma50)
      return -1;

   return 0;
}

//+------------------------------------------------------------------+
//| MICRO ENTRY MANAGEMENT                                           |
//+------------------------------------------------------------------+

void ManageMicroFills()
{
   if(!UseMicroEntries) return;

   BasketState state = GetBasketState();
   if(state.openOrders <= 0) return;
   if(state.totalLotsAll >= MaxTotalLots) return;
   if(GetCurrentSpreadPoints() > MaxSpreadForTrading) return;
   if(BlockNewEntries) return;

   // Check cooldown
   int barsPassed = (int)((TimeCurrent() - LastMicroEntryTime) / PeriodSeconds(Period()));
   if(barsPassed < MicroCooldownBars) return;

   int dir = state.direction;

   if(dir == -1) // Basket Sell
   {
      if(ShouldOpenMicroSell())
      {
         if(OpenOrder(OP_SELL, BaseLot, "MICRO_SELL"))
            LastMicroEntryTime = TimeCurrent();
      }
   }
   else if(dir == 1) // Basket Buy
   {
      if(ShouldOpenMicroBuy())
      {
         if(OpenOrder(OP_BUY, BaseLot, "MICRO_BUY"))
            LastMicroEntryTime = TimeCurrent();
      }
   }
}

bool ShouldOpenMicroSell()
{
   // Check if price is in supply zone or showing rejection
   double rsi = iRSI(TradeSymbol, Period(), 14, PRICE_CLOSE, 0);

   // Sell conditions: RSI overbought or rejection candle
   bool rsiCondition = (rsi > 60);
   bool rejectionCandle = IsRejectionCandleDown();
   bool priceCondition = (Ask < iHigh(TradeSymbol, TrendTF, 1));

   return (rsiCondition || rejectionCandle) && priceCondition;
}

bool ShouldOpenMicroBuy()
{
   // Check if price is in demand zone or showing rejection
   double rsi = iRSI(TradeSymbol, Period(), 14, PRICE_CLOSE, 0);

   // Buy conditions: RSI oversold or rejection candle
   bool rsiCondition = (rsi < 40);
   bool rejectionCandle = IsRejectionCandleUp();
   bool priceCondition = (Bid > iLow(TradeSymbol, TrendTF, 1));

   return (rsiCondition || rejectionCandle) && priceCondition;
}

bool IsRejectionCandleDown()
{
   double open = iOpen(TradeSymbol, Period(), 1);
   double close = iClose(TradeSymbol, Period(), 1);
   double high = iHigh(TradeSymbol, Period(), 1);
   double low = iLow(TradeSymbol, Period(), 1);

   double body = MathAbs(close - open);
   double upperWick = high - MathMax(open, close);
   double range = high - low;

   if(range == 0) return false;

   // Bearish rejection: long upper wick, small body
   return (upperWick > body * 2 && close < open);
}

bool IsRejectionCandleUp()
{
   double open = iOpen(TradeSymbol, Period(), 1);
   double close = iClose(TradeSymbol, Period(), 1);
   double high = iHigh(TradeSymbol, Period(), 1);
   double low = iLow(TradeSymbol, Period(), 1);

   double body = MathAbs(close - open);
   double lowerWick = MathMin(open, close) - low;
   double range = high - low;

   if(range == 0) return false;

   // Bullish rejection: long lower wick, small body
   return (lowerWick > body * 2 && close > open);
}

//+------------------------------------------------------------------+
//| GRID ENTRY MANAGEMENT                                            |
//+------------------------------------------------------------------+

void ManageGrid()
{
   if(!UseGrid) return;

   BasketState state = GetBasketState();
   if(state.openOrders <= 0) return;
   if(state.totalLotsAll >= MaxTotalLots) return;
   if(GetCurrentSpreadPoints() > MaxSpreadForTrading) return;
   if(BlockNewEntries) return;

   if(state.direction == -1) // Basket Sell
   {
      if(ShouldOpenGridSell(state))
      {
         double nextLot = CalcNextGridLot(state);
         if(OpenOrder(OP_SELL, nextLot, "GRID_SELL"))
            LastGridLevel++;
      }
   }
   else if(state.direction == 1) // Basket Buy
   {
      if(ShouldOpenGridBuy(state))
      {
         double nextLot = CalcNextGridLot(state);
         if(OpenOrder(OP_BUY, nextLot, "GRID_BUY"))
            LastGridLevel++;
      }
   }
}

bool ShouldOpenGridSell(BasketState &state)
{
   if(state.avgPriceDir == 0) return false;
   if(LastGridLevel >= MaxGridDepth) return false;

   // Price moved against us (up for sell)
   double distance = (Ask - state.avgPriceDir) / Point;
   double requiredDistance = GridStepPoints * (LastGridLevel + 1);

   return (distance >= requiredDistance);
}

bool ShouldOpenGridBuy(BasketState &state)
{
   if(state.avgPriceDir == 0) return false;
   if(LastGridLevel >= MaxGridDepth) return false;

   // Price moved against us (down for buy)
   double distance = (state.avgPriceDir - Bid) / Point;
   double requiredDistance = GridStepPoints * (LastGridLevel + 1);

   return (distance >= requiredDistance);
}

double CalcNextGridLot(BasketState &state)
{
   double lastLot = GetLastOrderLot(state.direction);
   if(lastLot == 0) lastLot = BaseLot;

   double nextLot = lastLot * GridLotFactor;
   return NormalizeLot(nextLot);
}

double GetLastOrderLot(int direction)
{
   int orderType = (direction == 1) ? OP_BUY : OP_SELL;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;
      if(OrderType() != orderType) continue;

      return OrderLots();
   }

   return 0;
}

//+------------------------------------------------------------------+
//| HEDGE MANAGEMENT                                                 |
//+------------------------------------------------------------------+

void ManageHedge()
{
   if(!UseHedge) return;

   BasketState state = GetBasketState();
   if(state.openOrders <= 0) return;

   // Check if we should open hedge
   double marginLevel = GetMarginLevel();
   bool ddTrigger = (state.ddPercent >= HedgeDDTriggerPercent);
   bool marginTrigger = (marginLevel < HedgeMarginTriggerLevel);

   if(!ddTrigger && !marginTrigger)
   {
      // Try to close hedge if conditions improve
      TryCloseHedges();
      return;
   }

   // Check cooldown
   int barsPassed = (int)((TimeCurrent() - LastHedgeTime) / PeriodSeconds(Period()));
   if(barsPassed < MinBarsBetweenHedges) return;

   // Calculate hedge lot
   int hedgeType = (state.direction == 1) ? OP_SELL : OP_BUY;
   double hedgeLot = state.totalLotsDir * HedgeLotFactor;
   hedgeLot = NormalizeLot(hedgeLot);

   if(hedgeLot <= 0) return;

   // Check if we already have enough hedge
   if(state.totalLotsHedge >= hedgeLot * 0.9) return;

   // Open hedge
   if(OpenOrder(hedgeType, hedgeLot, "HEDGE"))
   {
      LastHedgeTime = TimeCurrent();
      Print("Hedge opened - DD: ", DoubleToStr(state.ddPercent, 2), "% Margin: ", DoubleToStr(marginLevel, 2), "%");
   }
}

void TryCloseHedges()
{
   BasketState state = GetBasketState();
   if(state.totalLotsHedge <= 0) return;

   bool cond1 = (state.floatingProfit >= 0);
   bool cond2 = PriceInOppositeZone(state.direction);
   bool cond3 = TrendFlipDetected(state.direction);

   if(cond1 || cond2 || cond3)
   {
      CloseAllHedgeOrders(state.direction);
   }
}

void CloseAllHedgeOrders(int mainDirection)
{
   int hedgeType = (mainDirection == 1) ? OP_SELL : OP_BUY;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;
      if(OrderType() != hedgeType) continue;

      CloseOrder(OrderTicket());
   }

   Print("Hedge orders closed");
}

bool PriceInOppositeZone(int direction)
{
   double ma20 = iMA(TradeSymbol, TrendTF, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
   double currentPrice = (Ask + Bid) / 2;

   if(direction == 1) // Buy basket - check if price in supply zone
      return (currentPrice > ma20 * 1.01);
   else // Sell basket - check if price in demand zone
      return (currentPrice < ma20 * 0.99);
}

bool TrendFlipDetected(int currentDirection)
{
   int newDirection = DetermineMarketDirection();
   return (newDirection != 0 && newDirection != currentDirection);
}

//+------------------------------------------------------------------+
//| BASKET CLOSE LOGIC                                               |
//+------------------------------------------------------------------+

void TryCloseBasket()
{
   BasketState state = GetBasketState();
   if(state.openOrders <= 0) return;

   // Check TP conditions
   if(IsBasketTPHit(state))
   {
      Print("Basket TP hit - Closing basket");
      CloseBasket();
      return;
   }

   // Check structure-based close conditions
   if(CloseBasketOnTrendFlip && TrendFlipDetected(state.direction))
   {
      Print("Trend flip detected - Closing basket");
      CloseBasket();
      return;
   }

   if(CloseBasketOnOppZoneHit && PriceInOppositeZone(state.direction))
   {
      Print("Opposite zone hit - Closing basket");
      CloseBasket();
      return;
   }

   // Check max DD
   if(state.ddPercent > BasketMaxDDPercent)
   {
      Print("Basket max DD exceeded - Closing basket");
      CloseBasket();
      return;
   }
}

bool IsBasketTPHit(BasketState &state)
{
   // Money-based TP
   if(BasketTP_Money > 0 && state.floatingProfit >= BasketTP_Money)
      return true;

   // Equity-based TP with recovery
   if(BasketStartEquity <= 0) return false;

   double eqStart = BasketStartEquity;
   double eqNow = AccountEquity();
   double gainPct = ((eqNow - eqStart) / eqStart) * 100.0;

   double targetPct = CalcBasketTPPercent();

   return (gainPct >= targetPct);
}

//+------------------------------------------------------------------+
//| RECOVERY ENGINE                                                  |
//+------------------------------------------------------------------+

double CalcBasketTPPercent()
{
   double tpPercent = DefaultBasketTPPercent;

   if(UseRecoveryEngine && RecoveryLoss > 0)
   {
      double eqNow = AccountEquity();
      if(eqNow <= 0) return tpPercent;

      double boostMoney = RecoveryLoss / RecoveryBasketDivider;
      double boostPercent = (boostMoney / eqNow) * 100.0;

      // Cap boost
      if(boostPercent > RecoveryMaxBoostPercent)
         boostPercent = RecoveryMaxBoostPercent;

      tpPercent += boostPercent;
   }

   return tpPercent;
}

void OnBasketClosed(double basketProfit)
{
   if(!UseRecoveryEngine) return;

   if(basketProfit < 0)
   {
      // Add to recovery loss
      RecoveryLoss += MathAbs(basketProfit);
      Print("Basket closed with loss: $", DoubleToStr(basketProfit, 2), " - Total recovery needed: $", DoubleToStr(RecoveryLoss, 2));
   }
   else if(basketProfit > 0)
   {
      // Use profit to reduce recovery loss
      double applied = MathMin(basketProfit, RecoveryLoss);
      RecoveryLoss -= applied;

      if(RecoveryLoss < 0) RecoveryLoss = 0;

      Print("Basket closed with profit: $", DoubleToStr(basketProfit, 2), " - Remaining recovery: $", DoubleToStr(RecoveryLoss, 2));
   }
}

//+------------------------------------------------------------------+
//| WEEKEND PROTECTION                                               |
//+------------------------------------------------------------------+

void HandleWeekendProtection()
{
   if(!UseWeekendProtection) return;

   int dow = TimeDayOfWeek(TimeCurrent());
   int hour = TimeHour(TimeCurrent());

   // Block new entries after Friday stop hour
   if(dow == 5 && hour >= FridayStopHour)
   {
      BlockNewEntries = true;
   }

   // Make zero hedge before market close
   if(dow == 5 && hour >= FridayZeroHedgeHour)
   {
      MakeZeroHedgeExposure();
   }

   // Unblock on Monday
   if(dow == 1 && hour >= SessionStartHour)
   {
      BlockNewEntries = false;
   }
}

void MakeZeroHedgeExposure()
{
   double totalBuy = GetTotalLots(OP_BUY);
   double totalSell = GetTotalLots(OP_SELL);

   double diff = totalBuy - totalSell;

   if(MathAbs(diff) <= 0.0001)
   {
      Print("Already zero hedged - Buy: ", totalBuy, " Sell: ", totalSell);
      return;
   }

   Print("Making zero hedge - Current Buy: ", totalBuy, " Sell: ", totalSell, " Diff: ", diff);

   if(diff > 0)
   {
      // Buy > Sell - close buy positions
      CloseLotsFromSide(OP_BUY, diff);
   }
   else
   {
      // Sell > Buy - close sell positions
      CloseLotsFromSide(OP_SELL, MathAbs(diff));
   }
}

double GetTotalLots(int orderType)
{
   double total = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;
      if(OrderType() != orderType) continue;

      total += OrderLots();
   }

   return total;
}

void CloseLotsFromSide(int orderType, double lotsToClose)
{
   double closedLots = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(closedLots >= lotsToClose) break;

      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;
      if(OrderType() != orderType) continue;

      double lots = OrderLots();

      if(CloseOrder(OrderTicket()))
      {
         closedLots += lots;
         Print("Closed ", lots, " lots from ", (orderType == OP_BUY ? "BUY" : "SELL"), " side");
      }
   }

   Print("Total closed: ", closedLots, " lots");
}

//+------------------------------------------------------------------+
//| DASHBOARD DISPLAY                                                |
//+------------------------------------------------------------------+

void UpdateDashboard()
{
   BasketState state = GetBasketState();

   string info = "\n";
   info += "========================================\n";
   info += "   REBATE ENGINE V1\n";
   info += "========================================\n";
   info += "Account Equity: $" + DoubleToStr(AccountEquity(), 2) + "\n";
   info += "Account DD: " + DoubleToStr(GetAccountDDPercent(), 2) + "%\n";
   info += "Margin Level: " + DoubleToStr(GetMarginLevel(), 2) + "%\n";
   info += "----------------------------------------\n";
   info += "Basket Direction: " + (state.direction == 1 ? "BUY" : (state.direction == -1 ? "SELL" : "NONE")) + "\n";
   info += "Open Orders: " + IntegerToString(state.openOrders) + "\n";
   info += "Total Lots: " + DoubleToStr(state.totalLotsAll, 2) + "\n";
   info += "  Main: " + DoubleToStr(state.totalLotsDir, 2) + "\n";
   info += "  Hedge: " + DoubleToStr(state.totalLotsHedge, 2) + "\n";
   info += "Floating P/L: $" + DoubleToStr(state.floatingProfit, 2) + "\n";
   info += "Basket DD: " + DoubleToStr(state.ddPercent, 2) + "%\n";
   info += "Grid Level: " + IntegerToString(LastGridLevel) + "/" + IntegerToString(MaxGridDepth) + "\n";
   info += "----------------------------------------\n";
   info += "Recovery Loss: $" + DoubleToStr(RecoveryLoss, 2) + "\n";
   info += "Current TP Target: " + DoubleToStr(CalcBasketTPPercent(), 2) + "%\n";
   info += "----------------------------------------\n";
   info += "Today's Lots: " + DoubleToStr(TotalLotsToday, 2) + "\n";
   info += "Est. Rebate: $" + DoubleToStr(TotalLotsToday * RebatePerLotUSD, 2) + "\n";
   info += "Daily Target: $" + DoubleToStr(DailyRebateTargetUSD, 2) + "\n";
   info += "----------------------------------------\n";
   info += "Spread: " + IntegerToString(GetCurrentSpreadPoints()) + " pts\n";
   info += "Blocked: " + (BlockNewEntries ? "YES" : "NO") + "\n";
   info += "========================================\n";

   Comment(info);
}

//+------------------------------------------------------------------+
