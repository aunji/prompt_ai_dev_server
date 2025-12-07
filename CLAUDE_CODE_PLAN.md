# CLAUDE CODE IMPLEMENTATION PLAN  
Version: 1.0  
Purpose: เพื่อให้ Claude Code เขียนโค้ดได้อย่างถูกต้อง ไม่มีบั๊ก

---

## RULES
1. ใช้ Nuxt 3 + Vue 3 (setup script)  
2. ไม่ใช้ Pinia → ใช้ composables ตามโครงเดิม  
3. ใช้ useApi ที่มีแล้ว  
4. UI = Vuetify 3  
5. ใช้ dayjs สำหรับ date handling  
6. PDF = jsPDF  
7. XLSX = SheetJS  

---

## MODULES TO CREATE

### 1) Composables  
- useDashboard()  
- useWallet()  
- useTopupReport()  
- useUsageReport()  
- useChargerPerformance()  
- useLineAlert()  

### 2) Utils  
- kWh calculator  
- duration calculator  
- trend builder  
- exportXLSX  
- exportPDF  

### 3) Components  
- DashboardCards.vue  
- LineChart.vue  
- Heatmap.vue  
- ChargerBarChart.vue  
- WalletSummaryTable.vue  
- WalletHistory.vue  
- TopupTable.vue  
- UsageTable.vue  

### 4) Pages  
ตาม UI_PAGE_STRUCTURE.md

---

## IMPLEMENTATION ORDER
1. Integrate all partner APIs  
2. Build Dashboard data layer  
3. Build Wallet Summary  
4. Build Top-up Report  
5. Build Usage Report  
6. Build Charger Performance  
7. Add Export (XLSX/PDF)  
8. Implement LINE Notify OAuth + polling  
9. Final QA + optimize  

---

## TESTING
- Mock API responses  
- Validate all date filters  
- Validate grouping by charger  
- Validate Wallet calculations  
- Manual test LINE Alert  
