# GPARTNER API DATA MAPPING  
Version 1.0

---

## 1. Revenue Data → `/partner/revenue`
Used for:
- Dashboard  
- Usage report  
- Charger performance  
- Wallet usage  

Fields:
- transactionId  
- startTimestamp / stopTimestamp  
- meterStart / meterStop  
- totalFinal  
- Connector.chargePoint  
- Rated.User.email  
- Station.id  

Derived:
- kWh = (meterStop - meterStart) / 1000  
- Duration = stop - start  
- Efficiency = kWh / duration  

---

## 2. Top-up Data → `/partner/revenue/top-up`
Used for:
- Wallet summary  
- Top-up report  

Fields:
- topUpId  
- createdAt  
- totalFinal  
- paymentMethod  
- paymentStatus  

---

## 3. Charger Data → `/partner/charge-point`
Used for:
- Realtime status  
- LINE notification  

Fields:
- chargePointId  
- ConnectorActivity.status  
- ConnectorActivity.errorCode  

---

## Polling Logic for LINE Alerts
Every 30–60 seconds:
- fetch /partner/charge-point  
- compare last status  
- if changed → send LINE Notify  
