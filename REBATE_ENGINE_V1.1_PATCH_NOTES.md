# REBATE ENGINE V1.1 — PATCH NOTES

Complete fixes for all logic errors discovered in V1, required before moving to V2.

---

## 1. Direction Detection Fix

Old logic:

```
if(totalBuyLots > totalSellLots * 1.5) direction = BUY
```

Issue:

* Causes "direction = 0" too often → EA stalls.

Fix:

```
double diff = totalBuyLots - totalSellLots;
if(diff > 0.2) direction = BUY;
else if(diff < -0.2) direction = SELL;
else direction = 0; // neutral zone
```

---

## 2. Hedge Lot Calculation Fix

Old code incorrectly used `totalLotsDir` which can flip/shift when hedge alters structure.

Fix:

```
double GetMainDirectionLots()
{
    // Only count true main-direction orders
}
hedgeLot = GetMainDirectionLots(direction) * HedgeFactor;
```

---

## 3. Hedge Close Condition Fix

Old:

```
if(floatingProfit >= 0) close hedge
```

Issue: hedge closes TOO EARLY → deadly.

Fix:

```
if(floatingProfit >= AccountEquity()*0.003 && TrendFlip)
    CloseHedge();
```

---

## 4. Grid Reference Fix

Old grid uses avgPriceDir (which changes when micro fills).

Fix:
Add:

```
double BasketInitialPrice;
```

Only set ONCE when basket is opened:

```
BasketInitialPrice = OrderOpenPrice() of first order.
```

Grid reference:

```
Ask - BasketInitialPrice >= ATRGridStep
```

---

## 5. Zero-Hedge Exact Matching

Old code closes entire orders only → overshoot lots.

Fix: Implement partial close:

```
if(closedLots + lots > lotsToClose)
    OrderClose(ticket, lotsToClose - closedLots);
else
    OrderClose(ticket, lots);
```

---

## 6. Basket TP Safety

Rule added:

**Do not close basket while hedge is active.**

```
if(state.totalLotsHedge > 0) return; 
```

---

## 7. TrendFlip Whipsaw

Fix: require two-bar confirmation.

```
TrendFlip if MA20 > MA50 for 2 consecutive bars
```

---

## 8. Spread Calculation Fix

Normalize spread using Digits:

```
spread = (Ask - Bid) / MarketInfo(Symbol(), MODE_POINT)
```

---

## 9. Dashboard Optimization

Update every 1s instead of every tick.

---

## 10. Update BasketStartEquity on Hedge Entry

Freeze BasketStartEquity when hedge begins.

---

## 11. BlockNewEntries Logic Improved

Block remains until:

```
marginLevel > (MinMarginLevelPercent + buffer) AND no hedge active
```

---

These fixes are required as the foundation for V2.
