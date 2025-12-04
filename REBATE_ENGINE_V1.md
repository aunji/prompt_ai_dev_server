# REBATE_ENGINE_V1.md  
**Rebate Engine EA (Smart Hedge + Smart Order Fill + Weekend Zero Hedge + Recovery Engine)**  
Platform: **MT4 / MQL4** 
Symbol Target: **XAUUSD**  
Mode: **Fully Auto**

---

## 0. META & OBJECTIVE

สร้าง EA ชื่อ `RebateEngineV1` สำหรับ MT4 โดยมีเป้าหมาย:

1. **ปั่น LOT เพื่อกิน Rebate เป็นหลัก**
   - LOT/วัน สูง (เช่น ≥ 15 lots/day)
   - รายได้หลักมาจาก rebate (เช่น 7 USD/lot)
2. **ไม่ล้างพอร์ต**: คุม DD, Margin, และ Gap เสาร์–อาทิตย์
3. ใช้โครงสร้างตลาดแบบ Demand/Supply + Trend เป็น “กรอบ”  
   (กรองทิศ/โซนให้ไม่มั่ว แต่ไม่ต้องแม่นระดับสไนเปอร์)
4. มี 4 กลไกสำคัญ:
   - **Smart Micro Entry** – เปิดไม้เล็กบ่อย ๆ เพื่อปั่น LOT
   - **Smart Grid** – เติมไม้เฉลี่ยแบบคูณนุ่มไม่ใช่ Martingale
   - **Smart Partial Hedge** – ลด DD โดยไม่หยุดความเคลื่อนไหว
   - **Weekend Zero Hedge Mode** – กัน GAP เสาร์–อาทิตย์
   - **Recovery Engine** – จำยอดขาดทุน และค่อย ๆ ชดเชยด้วยกำไร Basket
5. EA ทำงานแบบ **Auto 100%** ไม่ต้องถามระหว่างรัน

---

## 1. ACCOUNT & SYMBOL ASSUMPTIONS

- Account leverage: ประมาณ 1:2000
- Symbol: `"XAUUSD"` (ค่าเริ่มต้น)
- ใช้ `Point`, `MODE_TICKVALUE` จาก MT4ในการคำนวณจุด / ค่าเงิน

---

## 2. KEY CONCEPTS

### 2.1 Basket

**Basket** = กลุ่ม order ของ symbol เดียวกัน (XAUUSD) + MagicNumber เดียวกัน:

- ฝั่งทิศหลัก (direction) = Buy หรือ Sell
- รวม:
  - Micro entries
  - Grid entries
  - Hedge entries (ฝั่งตรงข้าม แต่ถือเป็นส่วนของ Basket)

EA จะ “คิดกำไร/ขาดทุน” และตัดสินใจปิดแบบ **ยกชุด (Close Basket)**

---

### 2.2 Order Types

1. **Micro Entry**  
   - ไม้เล็ก เปิดบ่อย  
   - ใช้จังหวะแตะ Zone, Imbalance, Rejection, RSI เพื่อปั่น LOT

2. **Grid Entry**  
   - เพิ่มไม้ในทิศทางเดิมเมื่อราคาวิ่งสวน  
   - ใช้คูณ lot แบบนุ่ม (1.1–1.3x) ไม่ใช่ Martingale

3. **Hedge Entry (Smart Partial Hedge)**  
   - เปิดสวนทิศหลักเมื่อ DD หรือ MarginLevel เข้าพื้นที่เสี่ยง  
   - ไม่ Zero Hedge ทันที แต่ใช้ HedgeLotFactor (เช่น 0.5) เพื่อลดความชัน DD

4. **Weekend Zero Hedge**  
   - เฉพาะก่อนตลาดปิดวันศุกร์ EA จะปรับ Basket ให้ exposure = 0  
   - โดยปิดทิศที่เกินจน **จำนวน lot Buy = Sell**  
   - ค้าง Zero Hedge ข้ามเสาร์–อาทิตย์

---

## 3. INPUT PARAMETERS

```mql4
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
input double DailyRebateTargetUSD     = 100.0; // ใช้แสดงผลเท่านั้น

// Risk & Margin (Account-level)
input double MaxDrawdownPercent       = 40.0;  // ปิดหมดทุก order เมื่อเกิน DD นี้
input double MinMarginLevelPercent    = 250.0; // ต่ำกว่านี้ หยุดเปิดไม้เพิ่ม

// Basket-level risk
input double BasketMaxDDPercent       = 15.0;  // DD% ต่อ Basket ที่ยอมรับได้
input double BasketTP_EquityPercent   = 0.7;   // TP Basket (% จาก equity ตอนเริ่ม Basket)
input double BasketTP_Money           = 0.0;   // ถ้า >0 ใช้เป็น TP เงินแทน (% จะ ignore)

// Lots & Scaling
input double BaseLot                  = 0.03;  // micro lot เริ่มต้น
input double GridLotFactor            = 1.2;   // ตัวคูณ lot สำหรับ Grid
input double MaxTotalLots             = 5.0;   // ลอตรวมสูงสุดใน Basket
input int    MaxOpenOrders            = 50;    // จำนวนออเดอร์สูงสุดใน Basket

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
input double HedgeDDTriggerPercent    = 8.0;    // DD% Basket ที่ให้เริ่ม hedge
input double HedgeMarginTriggerLevel  = 400.0;  // MarginLevel % ต่ำกว่านี้ hedge ได้
input double HedgeLotFactor           = 0.5;    // hedgeLot = totalDirLots * factor
input int    MinBarsBetweenHedges     = 5;

// Trend / Zone Filters (simplified)
input bool   UseTrendFilter           = true;
input ENUM_TIMEFRAMES TrendTF         = PERIOD_H4;
input int    TrendLookbackBars        = 20;

// Basket close conditions (structure-based)
input bool   CloseBasketOnTrendFlip   = true;
input bool   CloseBasketOnOppZoneHit  = true;

// Weekend Protection
input bool   UseWeekendProtection     = true;
input int    FridayStopHour           = 21;    // หลังชั่วโมงนี้จะไม่เปิดไม้ใหม่
input int    FridayZeroHedgeHour      = 22;    // เริ่มทำ Zero Hedge ก่อนตลาดปิด
input int    MaxSpreadForTrading      = 150;   // จุด ถ้าเกิน ให้ block การเทรดใหม่

// Recovery Engine
input bool   UseRecoveryEngine        = true;
input double DefaultBasketTPPercent   = 0.7;   // baseline TP% เดิม
input double RecoveryMaxBoostPercent  = 0.5;   // เพิ่ม TP% สูงสุดจาก recovery
input int    RecoveryBasketDivider    = 20;    // แบ่งขาดทุนเป็นกี่ Basket (ความช้า/เร็วของการคืน)
4. BASKET STATE & STRUCTURES
struct BasketState {
   int    direction;        // 1 = Buy, -1 = Sell, 0 = None
   double totalLotsDir;     // ฝั่งทิศหลัก
   double totalLotsHedge;   // ฝั่ง hedge
   double totalLotsAll;
   double floatingProfit;
   double ddPercent;        // จาก BasketStartEquity
   double avgPriceDir;
   double lastHedgeOpenTime;
   int    openOrders;
};
ต้องมีตัวแปร global:
double BasketStartEquity = 0;
double RecoveryLoss       = 0; // ใช้โดย Recovery Engine
datetime BasketStartTime  = 0;
ฟังก์ชัน:

BasketState GetBasketState();

bool HasOpenBasket();

double GetBasketDDPercent();

double GetAccountDDPercent();

double GetMarginLevel();

void UpdateBasketStartEquityIfNeeded();
5. CORE FLOW (OnTick)
void OnTick() {
    if(!IsOurSymbol()) return;
    if(!IsTradeAllowedNow()) return;
    if(!CheckGlobalRiskLimits()) return;

    UpdateBasketState();

    if(UseWeekendProtection)
        HandleWeekendProtection(); // zero hedge + block การเปิดไม้ช่วงศุกร์

    if(HasOpenBasket()) {
        ManageHedge();
        ManageGrid();
        ManageMicroFills();
        TryCloseBasket();
    } else {
        TryOpenNewBasket();
    }

    UpdateDashboard();
}

6. SMART HEDGE ENGINE (Partial Hedge)
เงื่อนไขเปิด Hedge
void ManageHedge() {
    if(!UseHedge) return;
    BasketState basket = GetBasketState();
    if(basket.openOrders <= 0) return;

    double marginLevel = GetMarginLevel();
    if(basket.ddPercent < HedgeDDTriggerPercent && marginLevel > HedgeMarginTriggerLevel)
        return;

    if(TimeCurrent() - basket.lastHedgeOpenTime < MinBarsBetweenHedges * PeriodSeconds(Period()))
        return;

    int hedgeType = (basket.direction == 1) ? OP_SELL : OP_BUY;

    double hedgeLot = basket.totalLotsDir * HedgeLotFactor;
    hedgeLot = NormalizeLot(hedgeLot);
    if(hedgeLot <= 0) return;

    OpenOrder(hedgeType, hedgeLot, "HEDGE");
    basket.lastHedgeOpenTime = TimeCurrent();
}

เงื่อนไขปิด Hedge
void TryCloseHedges() {
    BasketState basket = GetBasketState();
    if(basket.totalLotsHedge <= 0) return;

    bool cond1 = (basket.floatingProfit >= 0);
    bool cond2 = PriceInOppositeZone();
    bool cond3 = TrendFlipDetected();

    if(cond1 || cond2 || cond3) {
        CloseAllHedgeOrders();
    }
}

7. SMART ORDER FILL ENGINE (Micro + Grid)
7.1 Micro Entries (ฝั่งถูกทาง)

เปิดเมื่อมี Basket อยู่แล้ว

ทำตามทิศทางเทรนด์ใหญ่ (ถ้า UseTrendFilter)

ใช้ Zone/Imbalance/RSI/แท่ง Rejection เป็นเงื่อนไข

เว้นระยะจาก micro ก่อนหน้า MicroDistancePoints

ไม่เกิน MaxTotalLots และ MaxOpenOrders

ตัวอย่าง SELL:

void ManageMicroFills() {
    if(!UseMicroEntries) return;
    BasketState basket = GetBasketState();
    if(basket.openOrders <= 0) return;

    if(basket.totalLotsAll >= MaxTotalLots) return;

    // Spread guard
    if(GetCurrentSpreadPoints() > MaxSpreadForTrading) return;

    int dir = basket.direction;
    if(dir == -1) {
        // Basket Sell → เปิด Micro Sell เมื่อราคาเข้า SZ / rejection ลง
        if(ShouldOpenMicroSell())
            OpenOrder(OP_SELL, BaseLot, "MICRO_SELL");
    } else if(dir == 1) {
        // Basket Buy → เปิด Micro Buy เมื่อเข้า DZ / rejection ขึ้น
        if(ShouldOpenMicroBuy())
            OpenOrder(OP_BUY, BaseLot, "MICRO_BUY");
    }
}

7.2 Grid Entries (เมื่อราคาวิ่งสวน)

ตัวอย่าง Basket Sell:

ถ้า Ask > avgPriceDir + n * GridStepPoints

ยังไม่ถึง MaxGridDepth

ยังไม่เกิน MaxTotalLots
→ เปิด Grid Sell lot = lastGridLot * GridLotFactor

void ManageGrid() {
    if(!UseGrid) return;
    BasketState basket = GetBasketState();
    if(basket.openOrders <= 0) return;
    if(basket.totalLotsAll >= MaxTotalLots) return;
    if(GetCurrentSpreadPoints() > MaxSpreadForTrading) return;

    if(basket.direction == -1) {
        if(ShouldOpenGridSell(basket))
            OpenOrder(OP_SELL, CalcNextGridLot(), "GRID_SELL");
    } else if(basket.direction == 1) {
        if(ShouldOpenGridBuy(basket))
            OpenOrder(OP_BUY, CalcNextGridLot(), "GRID_BUY");
    }
}

8. WEEKEND ZERO HEDGE MODE

เป้าหมาย:

ป้องกัน GAP เสาร์–อาทิตย์ โดยทำให้ Exposure = 0 ก่อนตลาดปิด

8.1 Logic การปิด/Zero Hedge วันศุกร์

ฟังก์ชัน HandleWeekendProtection():

void HandleWeekendProtection() {
    if(!UseWeekendProtection) return;

    int dow  = TimeDayOfWeek(TimeCurrent());
    int hour = TimeHour(TimeCurrent());

    // ไม่เปิดไม้ใหม่หลังเวลาที่กำหนด
    if(dow == 5 && hour >= FridayStopHour) {
        BlockNewEntries = true; // ใช้ flag ภายใน
    }

    // ช่วงทำ Zero Hedge
    if(dow == 5 && hour >= FridayZeroHedgeHour) {
        MakeZeroHedgeExposure();
    }
}

8.2 ฟังก์ชัน MakeZeroHedgeExposure()

หลักการ:

คำนวณ totalBuy และ totalSell (ทุก order ของ EA)

ถ้า Buy > Sell → ปิดส่วนเกินของ Buy

ถ้า Sell > Buy → ปิดส่วนเกินของ Sell

เลือกปิดแบบ “จำนวน lot” ไม่สนว่ากำไรหรือขาดทุน

หลังจากนั้นต้องได้ totalBuy ≈ totalSell (ในระดับ lot step)

void MakeZeroHedgeExposure() {
    double totalBuy  = GetTotalLots(OP_BUY);
    double totalSell = GetTotalLots(OP_SELL);

    double diff = totalBuy - totalSell;
    if(MathAbs(diff) <= 0.0001) return; // already hedged

    if(diff > 0) {
        // Buy มากกว่า → ปิด Buy diff lot
        CloseLotsFromSide(OP_BUY, diff);
    } else {
        // Sell มากกว่า → ปิด Sell |diff| lot
        CloseLotsFromSide(OP_SELL, MathAbs(diff));
    }
}


CloseLotsFromSide(type, lotsToClose):

loop order ฝั่งนั้น

ปิดทีละ order ตามลำดับ (FIFO/LIFO ก็ได้)

รวม lot ที่ปิดจนถึง lotsToClose

ไม่สนกำไร/ขาดทุนตอนปิด

8.3 วันจันทร์

ไม่ต้องทำอะไรพิเศษ:
EA จะเห็นว่า exposure = 0 (Buy = Sell)

สามารถให้ TryOpenNewBasket() เปิด Basket ใหม่ตามราคาวันจันทร์

หรือจะเพิ่ม logic ปิด Zero Hedge ทั้งหมดก่อนเริ่มรันใหม่ (optional):

void CloseAllWeekendHedgesOnMonday() {
    int dow = TimeDayOfWeek(TimeCurrent());
    if(dow == 1) {
        // ปิดทุก order Buy/Sell ของ EA (Option ถ้าต้องการ reset)
    }
}


(แล้วค่อยเปิด Basket ใหม่จากศูนย์)

9. RECOVERY ENGINE (ชดเชยขาดทุนอัตโนมัติ)

เป้าหมาย:

ถ้ามี Basket ขาดทุน (เช่น -300$) ให้ EA “จำตัวเลขนี้” แล้วค่อย ๆ เพิ่ม TP ของ Basket ในอนาคตเล็กน้อย เพื่อชดเชยคืน โดย ไม่ต้องเพิ่ม lot หรือใช้ Martingale

9.1 การตั้งค่า

ใช้ global:

double RecoveryLoss = 0; // ถ้าขาดทุน 300 → RecoveryLoss = 300

9.2 อัปเดต RecoveryLoss เมื่อปิด Basket

ถ้า Basket ปิดขาดทุน (P/L < 0):

void OnBasketClosed(double basketProfit) {
    if(basketProfit < 0 && UseRecoveryEngine) {
        RecoveryLoss += MathAbs(basketProfit);
    } else if(basketProfit > 0 && UseRecoveryEngine) {
        // ใช้กำไรช่วยลด RecoveryLoss
        double applied = MathMin(basketProfit, RecoveryLoss);
        RecoveryLoss -= applied;
    }
}

9.3 ปรับ TP ของ Basket ตาม RecoveryLoss

ใน TryCloseBasket() หรือฟังก์ชันที่ใช้คำนวณ TP:

double CalcBasketTPPercent() {
    double tpPercent = DefaultBasketTPPercent; // เช่น 0.7%

    if(UseRecoveryEngine && RecoveryLoss > 0) {
        // boost = RecoveryLoss / RecoveryBasketDivider เทียบกับทุน
        double eqNow = AccountEquity();
        double boostMoney = RecoveryLoss / RecoveryBasketDivider;
        double boostPercent = (boostMoney / eqNow) * 100.0;

        // จำกัด boost ไม่ให้เกิน RecoveryMaxBoostPercent
        if(boostPercent > RecoveryMaxBoostPercent)
            boostPercent = RecoveryMaxBoostPercent;

        tpPercent += boostPercent;
    }
    return(tpPercent);
}


แล้วใช้ CalcBasketTPPercent() แทน BasketTP_EquityPercent ตรง ๆ

9.4 เงื่อนไข TP ของ Basket
bool IsBasketTPHit(BasketState basket) {
    double eqStart = BasketStartEquity;
    double eqNow   = AccountEquity();
    double gainPct = (eqNow - eqStart) / eqStart * 100.0;

    double targetPct = CalcBasketTPPercent();

    if(BasketTP_Money > 0 && basket.floatingProfit >= BasketTP_Money)
        return(true);

    if(targetPct > 0 && gainPct >= targetPct)
        return(true);

    return(false);
}


เมื่อตัดสินใจปิด Basket:

double profit = basket.floatingProfit;
CloseBasket();
OnBasketClosed(profit);


ผลลัพธ์:

ขาดทุน 300$ → RecoveryLoss = 300

TP ต่อ Basket ถูกเพิ่มเล็กน้อย เช่น จาก 0.7% → 1.0–1.2%

เมื่อได้กำไรแต่ละ Basket → RecoveryLoss ค่อย ๆ ลดลง

พอ RecoveryLoss = 0 → EA กลับไปใช้ TP เดิม (DefaultBasketTPPercent)

ไม่มีการเพิ่ม lot เพิ่ม risk แค่ใช้ “กำไรตามปกติ” ช่วยคืนทุน

10. BASKET CLOSE CONDITIONS (สรุป)

Basket จะถูกปิดเมื่อ:

TP ถึง

ตาม CalcBasketTPPercent() หรือ BasketTP_Money

ราคาแตะ Opposite Zone (ถ้าใช้ CloseBasketOnOppZoneHit)

Trend Flip ชัดเจน (ถ้าใช้ CloseBasketOnTrendFlip)

Weekend Protection ต้องการปิดก่อนตลาดปิด (optional scenario)

Account DD > MaxDrawdownPercent → ปิดหมดทุก order

11. GLOBAL SAFETY

ถ้า DD ทั้งบัญชี > MaxDrawdownPercent → ปิดทุก order ทันที

ถ้า MarginLevel < MinMarginLevelPercent → หยุดเปิด order ใหม่ทุกประเภท

ถ้า Spread > MaxSpreadForTrading → ไม่เปิด Micro/Grid/Hedge

12. IMPLEMENTATION NOTES

ใช้ไฟล์เดียว RebateEngineV1.mq4

แยกโค้ดเป็นฟังก์ชันชัดเจน:

IsTradeAllowedNow(), HandleWeekendProtection(), MakeZeroHedgeExposure()

ManageHedge(), ManageGrid(), ManageMicroFills()

TryOpenNewBasket(), TryCloseBasket()

CalcBasketTPPercent(), OnBasketClosed()

ใช้ built-in indicators / functions เท่านั้น (ไม่พึ่ง .ex4 ภายนอก)

ให้ compile ผ่านใน MetaEditor โดยไม่มี warnings

ไม่ต้องถาม user runtime; ใช้ค่า input + logic ภายในทั้งหมด

Comment ภาษาอังกฤษสั้น ๆ อ่านง่าย

13. BACKTEST & OPTIMIZATION

ทดสอบ XAUUSD บน TF M5/M15 อย่างน้อย 6–12 เดือน

ปรับ parameter:

BaseLot, GridStepPoints, MaxGridDepth, HedgeDDTriggerPercent, HedgeLotFactor,
DefaultBasketTPPercent, RecoveryMaxBoostPercent, RecoveryBasketDivider,
FridayStopHour, FridayZeroHedgeHour, MaxSpreadForTrading

เป้าหมาย:

LOT/day ≥ 15 lots (หรือมากกว่าตามเป้ารีเบท)

DD รวมไม่เกิน ~40%

ไม่ล้างพอร์ต

RecoveryLoss สามารถถูกชดเชยคืนในเวลาเหมาะสม (ภายในไม่กี่วัน–ไม่กี่สัปดาห์ ขึ้นกับขนาด)

จบสเปก REBATE_ENGINE_V1 (พร้อม Weekend Zero Hedge + Recovery Engine)
ให้เขียน RebateEngineV1.mq4 ตามสเปกนี้ โดยไม่ต้องถามอะไรเพิ่ม

เสร็จแล้ว push to github/aunji/ ea mql
