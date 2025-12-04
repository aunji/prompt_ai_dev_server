# REBATE ENGINE V2 — PROFESSIONAL ALGO SPEC

Complete Specification for Claude Code to generate `RebateEngineV2.mq4`.

---

# 0. SYSTEM OVERVIEW

RebateEngineV2 =
**Smart Hedge + Smart Grid + Smart Exposure + ATR Dynamic Engine + Adaptive Micro + Correlation Mode + Zero-Hedge Weekend Protection**

The EA is optimized for:

* High LOT/day generation
* Low DD
* Rebate farming
* Long-term stability
* XAUUSD primarily

---

# 1. CORE NEW ENGINES (MANDATORY)

## 1.1 Smart Exposure Engine (SEE)

Exposure = BuyLots – SellLots

Interpretation:

* > +0.2 → bullish exposure
* < –0.2 → bearish exposure
* Between –0.2 and +0.2 → neutral

Usage:

* Grid opens only if exposure confirms direction.
* Micro entries follow exposure bias.
* Hedge scaling uses exposure magnitude.
* Basket close checks exposure conflict.
* Basket cannot close if exposure ≠ 0 AND hedge active.

---

## 1.2 ATR Dynamic Grid (ADG)

ATR = iATR(Symbol, PERIOD_H1, 14)

```
GridStep = ATR * GridMultiplier
GridMultiplier = 0.8–1.5 (input)
```

Grid opens when:

* Opposite move ≥ GridStep × (level+1)
* Spread normal
* RiskTier != HIGH

---

## 1.3 Hedge Scaling Engine (HSE)

HedgeLot = MainLots × HedgeCurve

HedgeCurve (dynamic):

```
HedgeCurve = BaseFactor
            + (DDPercent / 30)
            + (ATRVolatility / ScalingDivisor)
            + ExposureStrengthFactor
```

Hedge opens only when:

* DD% > HedgeDD
* OR margin < threshold
* OR TrendScore < threshold
* AND no rapid-spam within cooldown

Hedge closes only when:

* TrendFlip confirmed (2 bars)
* FloatingProfit > Equity × 0.003
* Exposure rebalances

---

## 1.4 Trend Confidence Scoring (TCS)

Score 0–100

Components:

* MA20 slope
* MA50 slope
* MA spacing
* RSI slope
* Break of structure (HH/HL or LL/LH)
* DXY alignment
* Candle pattern confirmation

```
TrendScore = Σ weighted factors
```

Interpretation:

* Score > 70 = strong trend
* Score 40–70 = moderate
* Score < 40 = weak → avoid opening basket

---

## 1.5 Micro Entry AI Adaptive Mode (MAM)

Micro rules:

```
If HedgeActive → no micro
If SpreadHigh → micro reduce 70%
If TrendScore < 40 → micro off
If ATR high → micro spacing ×1.5
If sideway → micro minimal
```

Micro entries open only with:

* direction alignment
* exposure alignment
* rejection signals
* ATR normal
* RiskTier ≠ HIGH

---

# 2. ADVANCED SAFETY SYSTEMS

---

## 2.1 Smart Basket Aging

BasketAge = TimeCurrent – BasketStartTime

Rules:

```
Age > 3h: reduce TP by 40%
Age > 6h: stop grid
Age > 12h: force close at BE or small loss
```

---

## 2.2 Smart Spread-Adaptive Mode

```
Spread < 100 → normal
Spread 100–200 → micro 50% & grid slow
Spread > 200 → no new entries
```

---

## 2.3 Smart Correlation Mode (XAU + DXY)

DXY = iClose("DXY", PERIOD_H1, 0)

Rules:

* If XAU buy but DXY strong up → block basket
* If XAU sell & DXY up → strong confirmation
* Adds/subtracts TrendScore

---

## 2.4 Auto Risk Tier Switching

ATRVol = ATR / Price

Tiers:

### LOW RISK:

* grid slow
* hedge small
* TP aggressive

### NORMAL RISK:

* default parameters

### HIGH RISK:

* grid ×2 distance
* hedge ×2 strength
* no micro
* block new basket

---

# 3. BASKET ENGINE V2

Basket opens when:

* TrendScore > 60
* Exposure neutral
* Spread normal
* ATR normal
* No hedge active
* RiskTier != HIGH

Basket closes when:

* TP hit (adjusted by recovery)
* TrendFlip (2-bar confirm)
* OppZone hit
* MaxDD exceeded
* Aging limit reached
* **NOT allowed if hedge active**

---

# 4. ZERO HEDGE V2

Friday:

```
StopHour → block entries
ZeroHedgeHour → exact hedge
```

Exact hedge:

* Calculate diff = BuyLots – SellLots
* Partial close lot-by-lot until diff = 0
* Hold exposure=0 all weekend

Monday:

* Close all hedges
* Start new basket if TrendScore allows

---

# 5. RECOVERY ENGINE V2

RecoveryLoss accumulates only when:

```
basketProfit < 0
```

Recovery reduces only when:

```
basketProfit > 0
```

TP logic:

```
TP% = BaseTP + min(RecoveryLoss/Divider, MaxBoost)
```

No lot increase, no martingale.

---

# 6. DASHBOARD V2

Update every 1 second.

Display:

* Equity
* Account DD
* Margin
* Spread severity
* Basket direction
* Exposure
* Total lots
* Hedge lots
* TrendScore
* ATR
* GridStep
* RiskTier
* BasketAge
* RecoveryLoss
* TP%
* DXY trend
* NewEntryBlocked reason

---

# 7. CODE ARCHITECTURE

Single file:

```
RebateEngineV2.mq4
```

Recommended modules:

```
GetBasketStateV2()
CalcExposure()
CalcTrendScore()
CalcATRGrid()
CalcRiskTier()
CalcHedgeLotV2()
ShouldOpenBasketV2()
ShouldOpenMicroV2()
ShouldOpenGridV2()
ShouldOpenHedgeV2()
TryCloseBasketV2()
ZeroHedgeV2()
RecoveryEngineV2()
DashboardV2()
```

---

# 8. RULES FOR CLAUDE CODE (MANDATORY)

1. No prompts or questions during code generation.
2. Implement **all** features exactly as listed.
3. Use clean modular functions.
4. Compile without errors or warnings.
5. No external libraries.
6. No repaint indicators.
7. All numeric constants must be input parameters when appropriate.
8. Safety > performance > TP > entry.
9. Hedge must always be dynamic scaling.
10. Zero hedge must use exact partial close logic.
11. Dashboard update at 1-second intervals.
12. Code must be stable on live markets.

---

# END OF SPEC
