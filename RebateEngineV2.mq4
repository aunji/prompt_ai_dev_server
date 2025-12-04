//+------------------------------------------------------------------+
//|                                              RebateEngineV2.mq4 |
//|                                      Copyright 2025, Aunji Team |
//|                            V2 - Advanced Multi-Engine System    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Aunji Team"
#property link      ""
#property version   "2.00"
#property strict

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

// General
input int    MagicNumber              = 202502;
input string TradeSymbol              = "XAUUSD";
input bool   OnlyCurrentSymbol        = true;

// Session control
input bool   UseTradingSession        = true;
input int    SessionStartHour         = 2;
input int    SessionEndHour           = 22;

// Rebate & Target
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

// Micro Entry V2 (Adaptive)
input bool   UseMicroEntries          = true;
input int    MicroDistancePoints      = 300;
input int    MicroCooldownBars        = 1;
input double MicroSpreadReduceFactor  = 0.7;  // Reduce micro by 70% on high spread

// ATR Dynamic Grid (ADG)
input bool   UseATRGrid               = true;
input double ATRGridMultiplier        = 1.0;   // 0.8-1.5 range
input int    ATRPeriod                = 14;
input ENUM_TIMEFRAMES ATRTF           = PERIOD_H1;
input int    MaxGridDepth             = 7;

// Smart Hedge V2 (Scaling Engine)
input bool   UseHedge                 = true;
input double HedgeDDTriggerPercent    = 8.0;
input double HedgeMarginTriggerLevel  = 400.0;
input double HedgeBaseFactor          = 0.5;   // Base hedge factor
input double HedgeDDScaling           = 30.0;  // DD divisor for scaling
input double HedgeATRScaling          = 20.0;  // ATR divisor for scaling
input double HedgeExposureScaling     = 0.15;  // Exposure strength factor
input int    MinBarsBetweenHedges     = 5;
input double HedgeCloseMinProfit      = 0.003; // 0.3% equity minimum

// Trend Confidence Scoring (TCS)
input bool   UseTrendFilter           = true;
input ENUM_TIMEFRAMES TrendTF         = PERIOD_H4;
input int    TrendLookbackBars        = 20;
input int    MinTrendScoreForBasket   = 60;    // 0-100 scale
input int    MinTrendScoreForMicro    = 40;

// Smart Exposure Engine (SEE)
input double ExposureNeutralThreshold = 0.2;   // ±0.2 lot tolerance

// Basket close conditions
input bool   CloseBasketOnTrendFlip   = true;
input bool   CloseBasketOnOppZoneHit  = true;
input bool   BlockTPIfHedgeActive     = true;  // V1.1 safety

// Weekend Protection V2
input bool   UseWeekendProtection     = true;
input int    FridayStopHour           = 21;
input int    FridayZeroHedgeHour      = 22;
input int    MaxSpreadForTrading      = 150;

// Recovery Engine V2
input bool   UseRecoveryEngine        = true;
input double DefaultBasketTPPercent   = 0.7;
input double RecoveryMaxBoostPercent  = 0.5;
input int    RecoveryBasketDivider    = 20;

// Basket Aging V2
input bool   UseBasketAging           = true;
input int    BasketAgeReduceTP_Hours  = 3;     // Start reducing TP
input int    BasketAgeStopGrid_Hours  = 6;     // Stop grid
input int    BasketAgeForceClose_Hours = 12;   // Force close

// Spread Adaptive Mode V2
input bool   UseSpreadAdaptive        = true;
input int    SpreadNormal             = 100;
input int    SpreadHigh               = 200;

// Correlation Mode (DXY)
input bool   UseDXYCorrelation        = false;  // Optional
input string DXYSymbol                = "DXY";

// Risk Tier Auto Switching
input bool   UseRiskTierSwitching     = true;
input double LowRiskATRThreshold      = 0.015;  // 1.5%
input double HighRiskATRThreshold     = 0.030;  // 3.0%

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
datetime LastDashboardUpdate = 0;
double BasketInitialPrice = 0;  // V1.1 fix
bool BasketEquityFrozen = false; // V1.1 fix
int TrendFlipConfirmCount = 0;   // V1.1 whipsaw prevention

// Risk tier
enum RISK_TIER {
   RISK_LOW,
   RISK_NORMAL,
   RISK_HIGH
};
RISK_TIER CurrentRiskTier = RISK_NORMAL;

//+------------------------------------------------------------------+
//| STRUCTURES                                                       |
//+------------------------------------------------------------------+

struct BasketStateV2
{
   int    direction;        // 1 = Buy, -1 = Sell, 0 = None/Neutral
   double totalLotsDir;     // main direction lots
   double totalLotsHedge;   // hedge lots
   double totalLotsAll;
   double buyLots;          // explicit buy
   double sellLots;         // explicit sell
   double exposure;         // buyLots - sellLots (SEE)
   double floatingProfit;
   double ddPercent;
   double avgPriceDir;
   double avgPriceHedge;
   datetime lastHedgeOpenTime;
   int    openOrders;
   int    gridDepth;
   int    trendScore;       // TCS 0-100
   double atrValue;         // Current ATR
   double gridStepDynamic;  // ATR-based grid step
   int    basketAge;        // seconds
   bool   hedgeActive;
   double dxyTrend;         // DXY correlation
};

//+------------------------------------------------------------------+
//| EXPERT INITIALIZATION FUNCTION                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("  RebateEngineV2 - Advanced System");
   Print("========================================");
   Print("Symbol: ", TradeSymbol);
   Print("Magic Number: ", MagicNumber);
   Print("Base Lot: ", BaseLot);
   Print("ATR Grid: ", (UseATRGrid ? "ENABLED" : "DISABLED"));
   Print("Trend Scoring: ", (UseTrendFilter ? "ENABLED" : "DISABLED"));
   Print("Risk Tier Switching: ", (UseRiskTierSwitching ? "ENABLED" : "DISABLED"));
   Print("DXY Correlation: ", (UseDXYCorrelation ? "ENABLED" : "DISABLED"));

   if(RecoveryLoss > 0)
      Print("Recovery Mode Active - Loss: $", DoubleToStr(RecoveryLoss, 2));

   Print("========================================");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| EXPERT DEINITIALIZATION FUNCTION                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   Print("RebateEngineV2 stopped. Reason: ", reason);
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

   // Update risk tier
   if(UseRiskTierSwitching)
      UpdateRiskTier();

   // Main basket management V2
   if(HasOpenBasket())
   {
      ManageHedgeV2();
      ManageGridV2();
      ManageMicroFillsV2();
      TryCloseBasketV2();
   }
   else
   {
      TryOpenNewBasketV2();
   }

   // Update dashboard (1-second interval)
   if(TimeCurrent() - LastDashboardUpdate >= 1)
   {
      UpdateDashboardV2();
      LastDashboardUpdate = TimeCurrent();
   }
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
      // V1.1 fix: Require buffer + no active hedges to unblock
      BasketStateV2 state = GetBasketStateV2();
      if(BlockNewEntries && marginLevel > MinMarginLevelPercent + 50 && !state.hedgeActive)
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
   // V1.1 fix: Normalize using MODE_POINT
   double point = MarketInfo(TradeSymbol, MODE_POINT);
   if(point == 0) point = Point;
   return (int)((Ask - Bid) / point);
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
//| BASKET STATE V2 FUNCTIONS                                        |
//+------------------------------------------------------------------+

BasketStateV2 GetBasketStateV2()
{
   BasketStateV2 state;
   state.direction = 0;
   state.totalLotsDir = 0;
   state.totalLotsHedge = 0;
   state.totalLotsAll = 0;
   state.buyLots = 0;
   state.sellLots = 0;
   state.exposure = 0;
   state.floatingProfit = 0;
   state.ddPercent = 0;
   state.avgPriceDir = 0;
   state.avgPriceHedge = 0;
   state.lastHedgeOpenTime = LastHedgeTime;
   state.openOrders = 0;
   state.gridDepth = LastGridLevel;
   state.trendScore = CalcTrendScore();
   state.atrValue = iATR(TradeSymbol, ATRTF, ATRPeriod, 0);
   state.gridStepDynamic = CalcATRGrid(state.atrValue);
   state.basketAge = (BasketStartTime > 0) ? (int)(TimeCurrent() - BasketStartTime) : 0;
   state.hedgeActive = false;
   state.dxyTrend = GetDXYTrend();

   double buyWeightedPrice = 0, sellWeightedPrice = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;

      double lots = OrderLots();
      double profit = OrderProfit() + OrderSwap() + OrderCommission();

      if(OrderType() == OP_BUY)
      {
         state.buyLots += lots;
         buyWeightedPrice += OrderOpenPrice() * lots;
      }
      else if(OrderType() == OP_SELL)
      {
         state.sellLots += lots;
         sellWeightedPrice += OrderOpenPrice() * lots;
      }

      state.openOrders++;
      state.floatingProfit += profit;
   }

   state.totalLotsAll = state.buyLots + state.sellLots;

   // Calculate exposure (SEE)
   state.exposure = state.buyLots - state.sellLots;

   // V1.1 fix: Direction based on differential threshold
   if(state.exposure > ExposureNeutralThreshold)
   {
      state.direction = 1;  // Bullish
      state.totalLotsDir = state.buyLots;
      state.totalLotsHedge = state.sellLots;
      if(state.buyLots > 0)
         state.avgPriceDir = buyWeightedPrice / state.buyLots;
      if(state.sellLots > 0)
         state.avgPriceHedge = sellWeightedPrice / state.sellLots;
      if(state.sellLots > 0.01)
         state.hedgeActive = true;
   }
   else if(state.exposure < -ExposureNeutralThreshold)
   {
      state.direction = -1;  // Bearish
      state.totalLotsDir = state.sellLots;
      state.totalLotsHedge = state.buyLots;
      if(state.sellLots > 0)
         state.avgPriceDir = sellWeightedPrice / state.sellLots;
      if(state.buyLots > 0)
         state.avgPriceHedge = buyWeightedPrice / state.buyLots;
      if(state.buyLots > 0.01)
         state.hedgeActive = true;
   }
   else
   {
      state.direction = 0;  // Neutral
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
      BasketEquityFrozen = false;
      BasketInitialPrice = 0;  // Will be set on first order
   }
}

double CalcExposure()
{
   BasketStateV2 state = GetBasketStateV2();
   return state.exposure;
}

//+------------------------------------------------------------------+
//| TREND CONFIDENCE SCORING V2 (TCS)                                |
//+------------------------------------------------------------------+

int CalcTrendScore()
{
   if(!UseTrendFilter) return 50;  // Neutral if disabled

   int score = 50;  // Start neutral

   // Component 1: MA positioning and spacing (max ±20 points)
   double ma20 = iMA(TradeSymbol, TrendTF, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
   double ma50 = iMA(TradeSymbol, TrendTF, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   double currentPrice = (Ask + Bid) / 2;

   double maSpacing = MathAbs(ma20 - ma50) / ma50 * 100.0;

   if(ma20 > ma50)
   {
      score += 10;  // Bullish alignment
      if(currentPrice > ma20) score += 5;
      if(maSpacing > 0.5) score += 5;  // Strong separation
   }
   else if(ma20 < ma50)
   {
      score -= 10;  // Bearish alignment
      if(currentPrice < ma20) score -= 5;
      if(maSpacing > 0.5) score -= 5;
   }

   // Component 2: MA slopes (max ±15 points)
   double ma20_prev = iMA(TradeSymbol, TrendTF, 20, 0, MODE_SMA, PRICE_CLOSE, 5);
   double ma50_prev = iMA(TradeSymbol, TrendTF, 50, 0, MODE_SMA, PRICE_CLOSE, 5);

   if(ma20 > ma20_prev) score += 7; else score -= 7;
   if(ma50 > ma50_prev) score += 8; else score -= 8;

   // Component 3: RSI slope (max ±10 points)
   double rsi = iRSI(TradeSymbol, TrendTF, 14, PRICE_CLOSE, 0);
   double rsi_prev = iRSI(TradeSymbol, TrendTF, 14, PRICE_CLOSE, 3);

   if(rsi > rsi_prev && rsi > 50) score += 10;
   else if(rsi < rsi_prev && rsi < 50) score -= 10;

   // Component 4: Higher highs / Lower lows (max ±15 points)
   double high0 = iHigh(TradeSymbol, TrendTF, 0);
   double high1 = iHigh(TradeSymbol, TrendTF, 1);
   double high5 = iHigh(TradeSymbol, TrendTF, 5);
   double low0 = iLow(TradeSymbol, TrendTF, 0);
   double low1 = iLow(TradeSymbol, TrendTF, 1);
   double low5 = iLow(TradeSymbol, TrendTF, 5);

   if(high0 > high5 && low0 > low5) score += 15;  // Higher highs & higher lows
   else if(high0 < high5 && low0 < low5) score -= 15;  // Lower highs & lower lows

   // Component 5: DXY correlation (max ±10 points)
   if(UseDXYCorrelation)
   {
      double dxyTrend = GetDXYTrend();
      if(dxyTrend < -0.001) score += 10;  // DXY falling = gold bullish
      else if(dxyTrend > 0.001) score -= 10;  // DXY rising = gold bearish
   }

   // Clamp to 0-100
   if(score < 0) score = 0;
   if(score > 100) score = 100;

   return score;
}

//+------------------------------------------------------------------+
//| ATR DYNAMIC GRID V2 (ADG)                                        |
//+------------------------------------------------------------------+

double CalcATRGrid(double atrValue)
{
   if(!UseATRGrid) return GridStepPoints * Point;  // Fallback to static

   // ATR-based grid step
   double gridStep = atrValue * ATRGridMultiplier;

   // Minimum step protection
   double minStep = 300 * Point;
   if(gridStep < minStep) gridStep = minStep;

   return gridStep;
}

//+------------------------------------------------------------------+
//| RISK TIER SWITCHING V2                                           |
//+------------------------------------------------------------------+

void UpdateRiskTier()
{
   if(!UseRiskTierSwitching)
   {
      CurrentRiskTier = RISK_NORMAL;
      return;
   }

   double currentPrice = (Ask + Bid) / 2;
   if(currentPrice == 0) return;

   double atrValue = iATR(TradeSymbol, ATRTF, ATRPeriod, 0);
   double atrPercent = atrValue / currentPrice;

   RISK_TIER oldTier = CurrentRiskTier;

   if(atrPercent < LowRiskATRThreshold)
      CurrentRiskTier = RISK_LOW;
   else if(atrPercent > HighRiskATRThreshold)
      CurrentRiskTier = RISK_HIGH;
   else
      CurrentRiskTier = RISK_NORMAL;

   if(CurrentRiskTier != oldTier)
   {
      string tierName = (CurrentRiskTier == RISK_LOW) ? "LOW" :
                        (CurrentRiskTier == RISK_HIGH) ? "HIGH" : "NORMAL";
      Print("Risk Tier switched to: ", tierName, " (ATR: ", DoubleToStr(atrPercent * 100, 2), "%)");
   }
}

string GetRiskTierName()
{
   if(CurrentRiskTier == RISK_LOW) return "LOW";
   if(CurrentRiskTier == RISK_HIGH) return "HIGH";
   return "NORMAL";
}

//+------------------------------------------------------------------+
//| DXY CORRELATION V2                                               |
//+------------------------------------------------------------------+

double GetDXYTrend()
{
   if(!UseDXYCorrelation) return 0;

   double dxy0 = iClose(DXYSymbol, PERIOD_H1, 0);
   double dxy5 = iClose(DXYSymbol, PERIOD_H1, 5);

   if(dxy0 == 0 || dxy5 == 0) return 0;

   return (dxy0 - dxy5) / dxy5;  // Percentage change
}

//+------------------------------------------------------------------+
//| ORDER MANAGEMENT FUNCTIONS                                       |
//+------------------------------------------------------------------+

bool OpenOrder(int type, double lots, string comment)
{
   if(BlockNewEntries) return false;

   // Check spread
   int spread = GetCurrentSpreadPoints();
   if(spread > MaxSpreadForTrading)
   {
      Print("Spread too high: ", spread, " points");
      return false;
   }

   // Normalize lot
   lots = NormalizeLot(lots);
   if(lots < MarketInfo(TradeSymbol, MODE_MINLOT))
      return false;

   // Check max lots
   BasketStateV2 state = GetBasketStateV2();
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

      // Set initial price for grid reference (V1.1 fix)
      if(BasketInitialPrice == 0)
         BasketInitialPrice = price;

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
   BasketStateV2 state = GetBasketStateV2();
   double profit = state.floatingProfit;

   Print("Closing basket - Profit: $", DoubleToStr(profit, 2), " Orders: ", state.openOrders);

   CloseAllOrders();

   // Handle recovery
   OnBasketClosedV2(profit);

   // Reset basket variables
   BasketStartEquity = 0;
   BasketStartTime = 0;
   LastGridLevel = 0;
   BasketInitialPrice = 0;
   BasketEquityFrozen = false;
   TrendFlipConfirmCount = 0;
}

//+------------------------------------------------------------------+
//| BASKET OPENING LOGIC V2                                          |
//+------------------------------------------------------------------+

void TryOpenNewBasketV2()
{
   if(BlockNewEntries) return;

   // Check if conditions allow new basket
   if(!ShouldOpenBasketV2()) return;

   // Determine direction
   int direction = DetermineMarketDirectionV2();

   if(direction == 0) return;

   // Open first micro entry
   int orderType = (direction == 1) ? OP_BUY : OP_SELL;
   string comment = (direction == 1) ? "MICRO_BUY_INIT" : "MICRO_SELL_INIT";

   if(OpenOrder(orderType, BaseLot, comment))
   {
      Print("New basket V2 opened - Direction: ", (direction == 1 ? "BUY" : "SELL"),
            " TrendScore: ", CalcTrendScore());
   }
}

bool ShouldOpenBasketV2()
{
   // Check trend score
   int trendScore = CalcTrendScore();
   if(trendScore < MinTrendScoreForBasket)
   {
      Print("TrendScore too low for new basket: ", trendScore);
      return false;
   }

   // Check exposure is neutral
   double exposure = CalcExposure();
   if(MathAbs(exposure) > ExposureNeutralThreshold)
   {
      Print("Exposure not neutral: ", DoubleToStr(exposure, 2));
      return false;
   }

   // Check spread
   int spread = GetCurrentSpreadPoints();
   if(spread > MaxSpreadForTrading)
   {
      Print("Spread too high: ", spread);
      return false;
   }

   // Check ATR not extreme
   double currentPrice = (Ask + Bid) / 2;
   double atrValue = iATR(TradeSymbol, ATRTF, ATRPeriod, 0);
   double atrPercent = atrValue / currentPrice;

   // Don't open basket in HIGH risk tier
   if(CurrentRiskTier == RISK_HIGH)
   {
      Print("Risk tier HIGH - blocking new basket");
      return false;
   }

   // Check no active hedge
   BasketStateV2 state = GetBasketStateV2();
   if(state.hedgeActive)
   {
      Print("Hedge active - blocking new basket");
      return false;
   }

   return true;
}

int DetermineMarketDirectionV2()
{
   int trendScore = CalcTrendScore();

   // Strong bullish
   if(trendScore > 65)
      return 1;

   // Strong bearish
   if(trendScore < 35)
      return -1;

   // Neutral - no direction
   return 0;
}

//+------------------------------------------------------------------+
//| MICRO ENTRY V2 (ADAPTIVE)                                        |
//+------------------------------------------------------------------+

void ManageMicroFillsV2()
{
   if(!UseMicroEntries) return;

   BasketStateV2 state = GetBasketStateV2();
   if(state.openOrders <= 0) return;
   if(state.totalLotsAll >= MaxTotalLots) return;

   // MAM: Block micro if hedge active
   if(state.hedgeActive)
   {
      return;
   }

   // Check spread adaptive
   int spread = GetCurrentSpreadPoints();
   if(UseSpreadAdaptive && spread > SpreadNormal)
   {
      // High spread reduces micro frequency
      if(spread > SpreadHigh) return;  // Block completely

      // Reduce by 70% - random skip
      if(MathRand() % 100 < 70) return;
   }

   // Check trend score for micro
   if(state.trendScore < MinTrendScoreForMicro)
      return;

   // Check ATR adaptive spacing
   double currentPrice = (Ask + Bid) / 2;
   double atrPercent = state.atrValue / currentPrice;
   double microDistance = MicroDistancePoints * Point;

   if(atrPercent > HighRiskATRThreshold)
      microDistance *= 1.5;  // Increase spacing in high volatility

   // Check cooldown
   int barsPassed = (int)((TimeCurrent() - LastMicroEntryTime) / PeriodSeconds(Period()));
   if(barsPassed < MicroCooldownBars) return;

   // Block in HIGH risk tier
   if(CurrentRiskTier == RISK_HIGH) return;

   int dir = state.direction;

   if(dir == -1)  // Basket Sell
   {
      if(ShouldOpenMicroSellV2(state))
      {
         if(OpenOrder(OP_SELL, BaseLot, "MICRO_SELL"))
            LastMicroEntryTime = TimeCurrent();
      }
   }
   else if(dir == 1)  // Basket Buy
   {
      if(ShouldOpenMicroBuyV2(state))
      {
         if(OpenOrder(OP_BUY, BaseLot, "MICRO_BUY"))
            LastMicroEntryTime = TimeCurrent();
      }
   }
}

bool ShouldOpenMicroSellV2(BasketStateV2 &state)
{
   // Check exposure alignment
   if(state.exposure > 0) return false;  // Want bearish exposure for sell

   // RSI check
   double rsi = iRSI(TradeSymbol, Period(), 14, PRICE_CLOSE, 0);
   bool rsiCondition = (rsi > 55);

   // Rejection candle
   bool rejectionCandle = IsRejectionCandleDown();

   // Price in supply zone
   bool priceCondition = (Ask < iHigh(TradeSymbol, TrendTF, 1));

   return (rsiCondition || rejectionCandle) && priceCondition;
}

bool ShouldOpenMicroBuyV2(BasketStateV2 &state)
{
   // Check exposure alignment
   if(state.exposure < 0) return false;  // Want bullish exposure for buy

   // RSI check
   double rsi = iRSI(TradeSymbol, Period(), 14, PRICE_CLOSE, 0);
   bool rsiCondition = (rsi < 45);

   // Rejection candle
   bool rejectionCandle = IsRejectionCandleUp();

   // Price in demand zone
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

   return (lowerWick > body * 2 && close > open);
}

//+------------------------------------------------------------------+
//| GRID ENTRY V2 (ATR DYNAMIC)                                      |
//+------------------------------------------------------------------+

void ManageGridV2()
{
   if(!UseATRGrid) return;

   BasketStateV2 state = GetBasketStateV2();
   if(state.openOrders <= 0) return;
   if(state.totalLotsAll >= MaxTotalLots) return;
   if(GetCurrentSpreadPoints() > MaxSpreadForTrading) return;
   if(BlockNewEntries) return;

   // Check basket aging - stop grid after time limit
   if(UseBasketAging && state.basketAge > BasketAgeStopGrid_Hours * 3600)
   {
      return;
   }

   // Block grid in HIGH risk tier
   if(CurrentRiskTier == RISK_HIGH) return;

   if(state.direction == -1)  // Basket Sell
   {
      if(ShouldOpenGridSellV2(state))
      {
         double nextLot = CalcNextGridLot(state);
         if(OpenOrder(OP_SELL, nextLot, "GRID_SELL"))
            LastGridLevel++;
      }
   }
   else if(state.direction == 1)  // Basket Buy
   {
      if(ShouldOpenGridBuyV2(state))
      {
         double nextLot = CalcNextGridLot(state);
         if(OpenOrder(OP_BUY, nextLot, "GRID_BUY"))
            LastGridLevel++;
      }
   }
}

bool ShouldOpenGridSellV2(BasketStateV2 &state)
{
   // V1.1 fix: Use BasketInitialPrice instead of avgPriceDir
   if(BasketInitialPrice == 0) return false;
   if(LastGridLevel >= MaxGridDepth) return false;

   // Calculate distance using ATR-based grid step
   double distance = Ask - BasketInitialPrice;
   double requiredDistance = state.gridStepDynamic * (LastGridLevel + 1);

   // Adjust grid distance in different risk tiers
   if(CurrentRiskTier == RISK_HIGH)
      requiredDistance *= 2.0;  // Double distance in high risk

   return (distance >= requiredDistance);
}

bool ShouldOpenGridBuyV2(BasketStateV2 &state)
{
   // V1.1 fix: Use BasketInitialPrice
   if(BasketInitialPrice == 0) return false;
   if(LastGridLevel >= MaxGridDepth) return false;

   // Calculate distance
   double distance = BasketInitialPrice - Bid;
   double requiredDistance = state.gridStepDynamic * (LastGridLevel + 1);

   // Adjust in risk tiers
   if(CurrentRiskTier == RISK_HIGH)
      requiredDistance *= 2.0;

   return (distance >= requiredDistance);
}

double CalcNextGridLot(BasketStateV2 &state)
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
//| HEDGE MANAGEMENT V2 (SCALING ENGINE)                            |
//+------------------------------------------------------------------+

void ManageHedgeV2()
{
   if(!UseHedge) return;

   BasketStateV2 state = GetBasketStateV2();
   if(state.openOrders <= 0) return;

   // Check if we should open hedge
   if(ShouldOpenHedgeV2(state))
   {
      // Check cooldown
      int barsPassed = (int)((TimeCurrent() - LastHedgeTime) / PeriodSeconds(Period()));
      if(barsPassed < MinBarsBetweenHedges) return;

      // Calculate dynamic hedge lot
      double hedgeLot = CalcHedgeLotV2(state);
      hedgeLot = NormalizeLot(hedgeLot);

      if(hedgeLot <= 0) return;

      // Check if we already have enough hedge
      if(state.totalLotsHedge >= hedgeLot * 0.9) return;

      // Open hedge
      int hedgeType = (state.direction == 1) ? OP_SELL : OP_BUY;
      if(OpenOrder(hedgeType, hedgeLot, "HEDGE_V2"))
      {
         LastHedgeTime = TimeCurrent();

         // V1.1 fix: Freeze equity when hedge activates
         if(!BasketEquityFrozen)
         {
            BasketStartEquity = AccountEquity();
            BasketEquityFrozen = true;
         }

         Print("Hedge V2 opened - DD: ", DoubleToStr(state.ddPercent, 2),
               "% TrendScore: ", state.trendScore, " HedgeLot: ", hedgeLot);
      }
   }
   else
   {
      // Try to close hedge if conditions improve
      TryCloseHedgesV2(state);
   }
}

bool ShouldOpenHedgeV2(BasketStateV2 &state)
{
   double marginLevel = GetMarginLevel();

   // Trigger 1: DD threshold
   bool ddTrigger = (state.ddPercent >= HedgeDDTriggerPercent);

   // Trigger 2: Margin threshold
   bool marginTrigger = (marginLevel < HedgeMarginTriggerLevel);

   // Trigger 3: Trend score threshold (weak trend)
   bool trendTrigger = (state.trendScore < 35 || state.trendScore > 65);

   return (ddTrigger || marginTrigger || !trendTrigger);
}

double CalcHedgeLotV2(BasketStateV2 &state)
{
   // V1.1 fix: Count only true main direction lots
   double mainLots = GetTrueMainDirectionLots(state.direction);

   // Base factor
   double hedgeFactor = HedgeBaseFactor;

   // Add DD scaling
   if(state.ddPercent > 0)
      hedgeFactor += (state.ddPercent / HedgeDDScaling);

   // Add ATR volatility scaling
   double currentPrice = (Ask + Bid) / 2;
   if(currentPrice > 0)
   {
      double atrPercent = state.atrValue / currentPrice;
      hedgeFactor += (atrPercent / (HedgeATRScaling / 100.0));
   }

   // Add exposure strength scaling
   double exposureStrength = MathAbs(state.exposure);
   hedgeFactor += (exposureStrength * HedgeExposureScaling);

   // Apply risk tier modifiers
   if(CurrentRiskTier == RISK_HIGH)
      hedgeFactor *= 2.0;  // Double hedge in high risk
   else if(CurrentRiskTier == RISK_LOW)
      hedgeFactor *= 0.7;  // Reduce hedge in low risk

   // Calculate final hedge lot
   double hedgeLot = mainLots * hedgeFactor;

   return hedgeLot;
}

double GetTrueMainDirectionLots(int direction)
{
   int orderType = (direction == 1) ? OP_BUY : OP_SELL;
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

void TryCloseHedgesV2(BasketStateV2 &state)
{
   if(state.totalLotsHedge <= 0) return;

   // V1.1 fix: Enhanced close conditions
   bool cond1 = (state.floatingProfit >= AccountEquity() * HedgeCloseMinProfit);  // 0.3% equity minimum
   bool cond2 = TrendFlipDetectedV2(state.direction);  // Requires 2-bar confirmation
   bool cond3 = MathAbs(state.exposure) < ExposureNeutralThreshold * 0.5;  // Exposure rebalanced

   if(cond1 && (cond2 || cond3))
   {
      CloseAllHedgeOrders(state.direction);
      BasketEquityFrozen = false;  // Unfreeze equity
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

   Print("Hedge V2 orders closed");
}

//+------------------------------------------------------------------+
//| BASKET CLOSE LOGIC V2                                            |
//+------------------------------------------------------------------+

void TryCloseBasketV2()
{
   BasketStateV2 state = GetBasketStateV2();
   if(state.openOrders <= 0) return;

   // V1.1 safety: Block TP if hedge active
   if(BlockTPIfHedgeActive && state.hedgeActive)
   {
      // Can't close basket while hedge is active
      // Only allow closure for emergency conditions
      if(state.ddPercent > BasketMaxDDPercent)
      {
         Print("Emergency: Max DD exceeded with hedge active - Force closing");
         CloseBasket();
         return;
      }

      // Check aging force close
      if(UseBasketAging && state.basketAge > BasketAgeForceClose_Hours * 3600)
      {
         Print("Basket age limit exceeded - Force closing");
         CloseBasket();
         return;
      }

      return;  // Otherwise wait for hedge to close first
   }

   // Check TP conditions
   if(IsBasketTPHitV2(state))
   {
      Print("Basket TP V2 hit - Closing basket");
      CloseBasket();
      return;
   }

   // Check trend flip
   if(CloseBasketOnTrendFlip && TrendFlipDetectedV2(state.direction))
   {
      Print("Trend flip V2 detected - Closing basket");
      CloseBasket();
      return;
   }

   // Check opposite zone
   if(CloseBasketOnOppZoneHit && PriceInOppositeZoneV2(state))
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

   // Check aging force close
   if(UseBasketAging && state.basketAge > BasketAgeForceClose_Hours * 3600)
   {
      // Force close at breakeven or small loss
      Print("Basket age limit - Force closing at current level");
      CloseBasket();
      return;
   }
}

bool IsBasketTPHitV2(BasketStateV2 &state)
{
   // Money-based TP
   if(BasketTP_Money > 0 && state.floatingProfit >= BasketTP_Money)
      return true;

   // Equity-based TP with recovery and aging
   if(BasketStartEquity <= 0) return false;

   double eqStart = BasketStartEquity;
   double eqNow = AccountEquity();
   double gainPct = ((eqNow - eqStart) / eqStart) * 100.0;

   double targetPct = CalcBasketTPPercentV2(state);

   return (gainPct >= targetPct);
}

bool TrendFlipDetectedV2(int currentDirection)
{
   // V1.1 fix: Require 2-bar confirmation
   double ma20_now = iMA(TradeSymbol, TrendTF, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
   double ma50_now = iMA(TradeSymbol, TrendTF, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   double ma20_prev = iMA(TradeSymbol, TrendTF, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
   double ma50_prev = iMA(TradeSymbol, TrendTF, 50, 0, MODE_SMA, PRICE_CLOSE, 1);

   bool flipNow = (ma20_now > ma50_now && ma20_prev <= ma50_prev) ||
                  (ma20_now < ma50_now && ma20_prev >= ma50_prev);

   if(flipNow)
   {
      TrendFlipConfirmCount++;
      if(TrendFlipConfirmCount >= 2)
      {
         TrendFlipConfirmCount = 0;
         return true;
      }
   }
   else
   {
      TrendFlipConfirmCount = 0;
   }

   return false;
}

bool PriceInOppositeZoneV2(BasketStateV2 &state)
{
   double ma20 = iMA(TradeSymbol, TrendTF, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
   double currentPrice = (Ask + Bid) / 2;

   if(state.direction == 1)  // Buy basket
      return (currentPrice > ma20 * 1.015);  // 1.5% above MA
   else  // Sell basket
      return (currentPrice < ma20 * 0.985);  // 1.5% below MA
}

//+------------------------------------------------------------------+
//| RECOVERY ENGINE V2                                               |
//+------------------------------------------------------------------+

double CalcBasketTPPercentV2(BasketStateV2 &state)
{
   double tpPercent = DefaultBasketTPPercent;

   // Apply recovery boost
   if(UseRecoveryEngine && RecoveryLoss > 0)
   {
      double eqNow = AccountEquity();
      if(eqNow <= 0) return tpPercent;

      double boostMoney = RecoveryLoss / RecoveryBasketDivider;
      double boostPercent = (boostMoney / eqNow) * 100.0;

      if(boostPercent > RecoveryMaxBoostPercent)
         boostPercent = RecoveryMaxBoostPercent;

      tpPercent += boostPercent;
   }

   // Apply aging reduction
   if(UseBasketAging && state.basketAge > BasketAgeReduceTP_Hours * 3600)
   {
      double ageHours = state.basketAge / 3600.0;
      double reductionFactor = 0.6;  // Reduce TP by 40%

      if(ageHours > BasketAgeReduceTP_Hours)
         tpPercent *= reductionFactor;
   }

   return tpPercent;
}

void OnBasketClosedV2(double basketProfit)
{
   if(!UseRecoveryEngine) return;

   if(basketProfit < 0)
   {
      RecoveryLoss += MathAbs(basketProfit);
      Print("Basket closed with loss: $", DoubleToStr(basketProfit, 2),
            " - Total recovery needed: $", DoubleToStr(RecoveryLoss, 2));
   }
   else if(basketProfit > 0)
   {
      double applied = MathMin(basketProfit, RecoveryLoss);
      RecoveryLoss -= applied;

      if(RecoveryLoss < 0) RecoveryLoss = 0;

      Print("Basket closed with profit: $", DoubleToStr(basketProfit, 2),
            " - Remaining recovery: $", DoubleToStr(RecoveryLoss, 2));
   }
}

//+------------------------------------------------------------------+
//| WEEKEND PROTECTION V2                                            |
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
      ZeroHedgeV2();
   }

   // Unblock on Monday
   if(dow == 1 && hour >= SessionStartHour)
   {
      BlockNewEntries = false;

      // Close all remaining hedge positions from weekend
      CloseAllWeekendHedges();
   }
}

void ZeroHedgeV2()
{
   double totalBuy = GetTotalLots(OP_BUY);
   double totalSell = GetTotalLots(OP_SELL);

   double diff = totalBuy - totalSell;

   if(MathAbs(diff) <= 0.001)
   {
      Print("Already zero hedged - Buy: ", totalBuy, " Sell: ", totalSell);
      return;
   }

   Print("Zero Hedge V2 - Current Buy: ", totalBuy, " Sell: ", totalSell, " Diff: ", diff);

   // V1.1 fix: Partial order closure for exact matching
   if(diff > 0)
   {
      CloseLotsFromSideV2(OP_BUY, diff);
   }
   else
   {
      CloseLotsFromSideV2(OP_SELL, MathAbs(diff));
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

void CloseLotsFromSideV2(int orderType, double lotsToClose)
{
   double closedLots = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(closedLots >= lotsToClose - 0.001) break;

      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;
      if(OrderType() != orderType) continue;

      double lots = OrderLots();
      double neededLots = lotsToClose - closedLots;

      // V1.1 fix: Partial close if needed
      if(lots > neededLots + 0.001)
      {
         // Need partial close
         double partialLots = NormalizeLot(neededLots);
         if(OrderClose(OrderTicket(), partialLots, (orderType == OP_BUY ? Bid : Ask), 30, clrNONE))
         {
            closedLots += partialLots;
            Print("Partial closed ", partialLots, " lots from order ", OrderTicket());
         }
      }
      else
      {
         // Close entire order
         if(CloseOrder(OrderTicket()))
         {
            closedLots += lots;
            Print("Closed ", lots, " lots from ", (orderType == OP_BUY ? "BUY" : "SELL"));
         }
      }
   }

   Print("Zero Hedge V2 completed - Total closed: ", DoubleToStr(closedLots, 2), " lots");
}

void CloseAllWeekendHedges()
{
   // Close any remaining positions from weekend zero hedge
   int closed = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != TradeSymbol) continue;

      if(CloseOrder(OrderTicket()))
         closed++;
   }

   if(closed > 0)
      Print("Monday cleanup: Closed ", closed, " weekend hedge positions");
}

//+------------------------------------------------------------------+
//| DASHBOARD V2                                                     |
//+------------------------------------------------------------------+

void UpdateDashboardV2()
{
   BasketStateV2 state = GetBasketStateV2();

   string info = "\n";
   info += "========================================\n";
   info += "   REBATE ENGINE V2\n";
   info += "========================================\n";
   info += "Account Equity: $" + DoubleToStr(AccountEquity(), 2) + "\n";
   info += "Account DD: " + DoubleToStr(GetAccountDDPercent(), 2) + "%\n";
   info += "Margin Level: " + DoubleToStr(GetMarginLevel(), 2) + "%\n";
   info += "Risk Tier: " + GetRiskTierName() + "\n";
   info += "----------------------------------------\n";
   info += "Spread: " + IntegerToString(GetCurrentSpreadPoints()) + " pts";

   int spread = GetCurrentSpreadPoints();
   if(spread > SpreadHigh) info += " [EXTREME]";
   else if(spread > SpreadNormal) info += " [HIGH]";
   else info += " [NORMAL]";
   info += "\n";

   info += "----------------------------------------\n";
   info += "Basket Direction: ";
   if(state.direction == 1) info += "BUY";
   else if(state.direction == -1) info += "SELL";
   else info += "NEUTRAL";
   info += "\n";

   info += "Exposure (SEE): " + DoubleToStr(state.exposure, 2) + "\n";
   info += "Open Orders: " + IntegerToString(state.openOrders) + "\n";
   info += "Total Lots: " + DoubleToStr(state.totalLotsAll, 2) + "\n";
   info += "  Main: " + DoubleToStr(state.totalLotsDir, 2) + "\n";
   info += "  Hedge: " + DoubleToStr(state.totalLotsHedge, 2);
   if(state.hedgeActive) info += " [ACTIVE]";
   info += "\n";

   info += "Floating P/L: $" + DoubleToStr(state.floatingProfit, 2) + "\n";
   info += "Basket DD: " + DoubleToStr(state.ddPercent, 2) + "%\n";
   info += "----------------------------------------\n";

   info += "Trend Score: " + IntegerToString(state.trendScore) + "/100";
   if(state.trendScore > 70) info += " [STRONG]";
   else if(state.trendScore < 40) info += " [WEAK]";
   else info += " [MODERATE]";
   info += "\n";

   info += "ATR: " + DoubleToStr(state.atrValue, 2) + "\n";
   info += "Grid Step: " + DoubleToStr(state.gridStepDynamic / Point, 0) + " pts\n";
   info += "Grid Level: " + IntegerToString(state.gridDepth) + "/" + IntegerToString(MaxGridDepth) + "\n";

   if(state.basketAge > 0)
   {
      int ageHours = state.basketAge / 3600;
      int ageMinutes = (state.basketAge % 3600) / 60;
      info += "Basket Age: " + IntegerToString(ageHours) + "h " + IntegerToString(ageMinutes) + "m\n";
   }

   info += "----------------------------------------\n";
   info += "Recovery Loss: $" + DoubleToStr(RecoveryLoss, 2) + "\n";
   info += "Current TP Target: " + DoubleToStr(CalcBasketTPPercentV2(state), 2) + "%\n";

   if(UseDXYCorrelation)
      info += "DXY Trend: " + DoubleToStr(state.dxyTrend * 100, 2) + "%\n";

   info += "----------------------------------------\n";
   info += "Today's Lots: " + DoubleToStr(TotalLotsToday, 2) + "\n";
   info += "Est. Rebate: $" + DoubleToStr(TotalLotsToday * RebatePerLotUSD, 2) + "\n";
   info += "Daily Target: $" + DoubleToStr(DailyRebateTargetUSD, 2) + "\n";
   info += "----------------------------------------\n";

   info += "Status: ";
   if(BlockNewEntries) info += "BLOCKED";
   else info += "ACTIVE";
   info += "\n";

   if(BlockNewEntries)
   {
      info += "Block Reason: ";
      if(GetMarginLevel() < MinMarginLevelPercent) info += "Low Margin";
      else if(CurrentRiskTier == RISK_HIGH) info += "High Risk Tier";
      else if(state.hedgeActive) info += "Hedge Active";
      else if(TimeDayOfWeek(TimeCurrent()) == 5 && TimeHour(TimeCurrent()) >= FridayStopHour)
         info += "Weekend Protection";
      else info += "Other";
      info += "\n";
   }

   info += "========================================\n";

   Comment(info);
}

//+------------------------------------------------------------------+
