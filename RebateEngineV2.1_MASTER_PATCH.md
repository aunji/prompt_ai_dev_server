Purpose: ให้ Claude Code ปรับปรุง RebateEngineV2.mq4 → เป็น V2.1
รวมทุก Patch จาก Part1–5 + bug fixes + improvements + enhancements

-----------------------------------------------------
1. FILE TARGET
-----------------------------------------------------

Input file:
/home/aunji/prompt_ai_dev_server/RebateEngineV2.mq4

Output file:
/home/aunji/prompt_ai_dev_server/RebateEngineV2.1.mq4

-----------------------------------------------------
2. GLOBAL OBJECTIVE
-----------------------------------------------------

Upgrade EA จาก V2 → V2.1 โดย:

✅ รวมทุก patch ทั้งหมดจาก Part1–5
✅ Performance improvements
✅ Bug fixes (critical)
✅ Enhanced dashboard
✅ Improved hedge/grid logic
✅ Stronger basket aging
✅ Stability upgrade

Claude ต้อง:

อ่านไฟล์ RebateEngineV2.mq4 เดิมทั้งหมด

ทำการแก้ไขตาม instructions ด้านล่าง

สร้างไฟล์ใหม่ RebateEngineV2.1.mq4

Push GitHub พร้อม commit message:
"Upgrade: RebateEngine V2.1 (patch + stability + logic rewrite)"

-----------------------------------------------------
3. CORE PATCHES (APPLY ALL)
-----------------------------------------------------
PATCH 3.1 — Spread Calculation (unify)

Replace every instance of:

int spread = GetCurrentSpreadPoints();


Ensure all spread logic uses:

double point = MarketInfo(TradeSymbol, MODE_POINT);
if(point <= 0) point = Point;
int spread = (int)((Ask - Bid) / point);

PATCH 3.2 — BasketAge Calculation FIX

ปัญหาเดิม: basketAge คำนวณผิดหลัง restart MT4

แก้ไข:

สร้างฟังก์ชันใหม่:

datetime GetBasketStartTime()
{
    datetime first = 0;
    for(int i=OrdersTotal()-1; i>=0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS)) continue;
        if(OrderMagicNumber() != MagicNumber) continue;
        if(OrderSymbol() != TradeSymbol) continue;

        if(first == 0 || OrderOpenTime() < first)
            first = OrderOpenTime();
    }
    return first;
}


และแทนที่:

state.basketAge = (BasketStartTime > 0) ? (TimeCurrent() - BasketStartTime) : 0;


ด้วย:

state.basketAge = (int)(TimeCurrent() - GetBasketStartTime());

PATCH 3.3 — TrendFlipConfirmCount Logic Fix

Patch:

Reset counter when basket closed

Reset when flip false for 1 bar

Confirm only after 2 consecutive flips

Update TrendFlipDetectedV2:

static int flipCount = 0;

if(flipNow) {
    flipCount++;
    if(flipCount >= 2) {
        flipCount = 0;
        return true;
    }
} else {
    flipCount = 0;
}

PATCH 3.4 — HedgeActive Detection (more accurate)

Replace hedge detection to:

state.hedgeActive = (state.totalLotsHedge > state.totalLotsDir * 0.05);

PATCH 3.5 — BasketEquityFrozen Logic

เพิ่ม check:

if(!BasketEquityFrozen && state.totalLotsHedge > 0)
{
    BasketStartEquity = AccountEquity();
    BasketEquityFrozen = true;
}


Unfreeze only when hedge lots = 0:

if(state.totalLotsHedge <= 0.0001)
    BasketEquityFrozen = false;

-----------------------------------------------------
4. GRID SYSTEM PATCHES
-----------------------------------------------------
PATCH 4.1 — ATR Grid Distance Bug

Replace usage of:

distance = Ask - BasketInitialPrice;


with:

distance = MathAbs((Ask + Bid)/2 - BasketInitialPrice);


Apply same for Buy/Sell.

PATCH 4.2 — Risk Tier Grid Scaling

Insert inside ShouldOpenGridSellV2 & Buy:

if(CurrentRiskTier == RISK_LOW) requiredDistance *= 0.8;
if(CurrentRiskTier == RISK_HIGH) requiredDistance *= 2.0;

-----------------------------------------------------
5. MICRO ENTRY (MAM) PATCHES
-----------------------------------------------------
PATCH 5.1 — microDistance not used → FIX

Replace:

if(ShouldOpenMicroSellV2(...))


with condition requiring price distance:

if(distanceFromLastEntry >= microDistance && ShouldOpenMicroSellV2(...))


Define:

double lastEntryPrice = GetLastEntryPrice(dir);
double distanceFromLastEntry = MathAbs((Ask + Bid)/2 - lastEntryPrice);

PATCH 5.2 — MicroSpreadReduceFactor Enhancement

If spread > SpreadNormal:

microDistance *= (1.0 + MicroSpreadReduceFactor);

-----------------------------------------------------
6. HEDGE SYSTEM PATCHES
-----------------------------------------------------
PATCH 6.1 — Incorrect Condition in ShouldOpenHedgeV2

Replace:

return (ddTrigger || marginTrigger || !trendTrigger);


with:

return (ddTrigger || marginTrigger);


Reason: TrendScore ไม่ควรเปิด hedge เอง

PATCH 6.2 — Hedge Close Condition Upgrade

Replace cond1:

state.floatingProfit >= AccountEquity() * HedgeCloseMinProfit


with:

state.floatingProfit >= MathAbs(state.totalLotsHedge * 0.5)


เพื่อให้ hedge ปิดเร็วขึ้นถ้า hedge ช่วยเฉลี่ยดีขึ้น

-----------------------------------------------------
7. BASKET CLOSING PATCHES
-----------------------------------------------------
PATCH 7.1 — TP Progress Display

Add to dashboard:

double tpProgress = gainPct / targetPct * 100;


Show:

"TP Progress: " + DoubleToStr(tpProgress, 1) + "%\n"

PATCH 7.2 — Distance to BreakEven

Compute:

double breakEvenPrice = (state.avgPriceDir * state.totalLotsDir 
                       - state.avgPriceHedge * state.totalLotsHedge)
                        / (state.totalLotsDir - state.totalLotsHedge);

double distToBE = MathAbs(((Ask + Bid)/2) - breakEvenPrice) / Point;


Add to dashboard:

"Dist to BE: " + DoubleToStr(distToBE, 0) + " pts\n"

-----------------------------------------------------
8. DASHBOARD V2.1 PATCH
-----------------------------------------------------
เพิ่ม:

Hedge Ratio:

"Hedge Ratio: " + DoubleToStr(state.totalLotsHedge/state.totalLotsDir*100,1) + "%\n"


Basket Start Equity:

"Start Equity: $" + DoubleToStr(BasketStartEquity,2) + "\n"


Equity Frozen:

if(BasketEquityFrozen) info += "[EQUITY FROZEN]\n";


Aged Stage:

if(age > 12h) “[STAGE 3: FORCE CLOSE]”
if(age > 6h) “[STAGE 2: NO GRID]”
if(age > 3h) “[STAGE 1: REDUCE TP]”

-----------------------------------------------------
9. FINAL TASK FOR CLAUDE
-----------------------------------------------------
Claude ต้องทำทั้งหมดนี้:

โหลด RebateEngineV2.mq4

Apply patches ทุกข้อด้านบน

Refactor ให้อ่านง่าย

สร้างไฟล์ใหม่:

RebateEngineV2.1.mq4


Push GitHub:

git add .
git commit -m "Upgrade: RebateEngine V2.1 (all patches + stability)"
git push

-----------------------------------------------------
10. OUTPUT CONFIRMATION

เมื่อเสร็จ Claude ต้องแจ้ง:

[OK] RebateEngineV2.1.mq4 created & compiled successfully.
[OK] All patches applied.
[OK] GitHub push completed.

🔥 เสร็จสมบูรณ์
