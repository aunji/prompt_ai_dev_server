# GPARTNER — REPORTING & DASHBOARD MASTER PLAN  
Version: 1.0  
Scope: Partner Reporting + Dashboard + LINE Alerts  
Backend: ใช้เฉพาะ Partner API ปัจจุบัน (ไม่แก้ Backend)

---

## 1. DASHBOARD (Daily / Monthly)
- รายรับรวมวันนี้ / เดือนนี้  
- kWh รวมวันนี้ / เดือนนี้  
- Total sessions  
- รายได้แยกตามตู้  
- kWh ใช้แยกตามตู้  
- Peak hour usage (Heatmap)  
- Charging efficiency (kWh/min)

---

## 2. WALLET SUMMARY (PER PARTNER)
- Total Top-up  
- Total Usage  
- Outstanding Wallet  
- Wallet by User  
- Wallet History (ledger + running balance)

---

## 3. TOP-UP REPORT
- topUpId  
- createdAt  
- amount  
- paymentMethod  
- paymentStatus  

*หมายเหตุ:* ไม่มีข้อมูล Payment Fee → ไม่คำนวณ NET

---

## 4. CHARGING SESSION REPORT
- Session ID  
- Start–End timestamp  
- User email  
- chargePoint  
- kWh used  
- Duration (minutes)  
- Revenue per session  

*Promotion ไม่มีข้อมูล → ตัดออก*

---

## 5. TOP-UP VS USAGE COMPARISON
- Line graph: Top-up vs Usage  
- Outstanding trend  
- Consumption trend  
- Revenue vs Estimated cost (ถ้าใช้ input จาก partner → ตอนนี้ตัดออก)

---

## 6. CHARGER PERFORMANCE
- ChargePoint ID  
- Total revenue  
- Total kWh  
- Sessions count  
- Charging Utilization = sum(duration)

*ข้อจำกัด:*  
- ไม่มี Offline history  
- ไม่มี Error history

---

## 7. ELECTRICITY COST REPORT  
*ตัดออกทั้งหมด เนื่องจากข้อมูล TOU / FT / Demand Charge ไม่รองรับ*

---

## 8. LINE ALERT SYSTEM
### Function:
- Partner login กด “Connect LINE Notify”
- ระบบเก็บ LINE access token
- Polling API `/partner/charge-point` ทุก 30–60 วินาที
- หากสถานะ Online → Offline หรือ ErrorCode เปลี่ยน → แจ้งเตือน

### Example Message:
```
Charger Alert
Station: ChiangMai-Nimman
Charger: CP-002
Status: Offline
Time: 14:22
```

---

## 9. EXPORT FUNCTIONS
- XLSX / CSV / PDF สำหรับทุกหน้า report  
- Dashboard PDF  
- Wallet Summary Excel  
- Charging Report Excel  
- Charger Performance PDF  

---

## NOT SUPPORTED (ต้องตัดออก)
- Payment Gateway Fee  
- TOU Rate / FT / Demand Charge  
- Error Log History  
- VAT report / e-tax  
- Promotion usage tracking  

---

## TIMELINE (12–16 days)
- Day 1–3: Dashboard base + API integration  
- Day 4–7: Wallet Summary + Top-up report  
- Day 8–10: Charger Performance + Heatmap  
- Day 11–13: LINE Notification  
- Day 14–16: Export, polishing, QA  
