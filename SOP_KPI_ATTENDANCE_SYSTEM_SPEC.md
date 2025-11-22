act you is senior dev top of world

droplet is 159.65.132.177

use aunji ssh key

you must build app to deploy on automate not ask me
and save coding log always in .md and when you come back to coding again please read log coding before think anything

📄 SOP_KPI_ATTENDANCE_SYSTEM_SPEC.md

Project Goal:
สร้างระบบจัดการพนักงานร้านหมูกระทะแบบครบวงจรบนเว็บ (Mobile-First)
ครอบคลุม SOP + KPI + Attendance (เข้างาน/เลิกงาน) + Daily Report
ใช้งานจากมือถือผ่าน LINE กลุ่มได้ทันที
งานทุกชิ้นต้องมีหลักฐานรูปถ่าย (ไม่อนุญาตอัปโหลดจากแกลลอรี่)

0. RULES (IMPORTANT)

ห้ามถามคำถามกลับ

เลือกเทคโนโลยีที่เหมาะสมโดยอัตโนมัติ

ทำ Frontend + Backend + Database + API ให้ครบ

ใช้ Camera-only capture (ไม่ใช้ gallery)

ทุกฟีเจอร์ต้องรองรับ Mobile-first 100%

ออกแบบให้พร้อมใช้งานจริงในร้านอาหาร

เน้นความเร็ว, ใช้งานง่าย, ปุ่มใหญ่

ความปลอดภัยเหมาะสม (ตรวจสอบ user, anti-cheat)

ทำให้เสร็จสมบูรณ์ พร้อม deploy

1. SYSTEM OVERVIEW

ระบบนี้ประกอบด้วย 4 Core Modules:

Attendance System

เข้างาน (ถ่ายรูป + GPS + เวลา)

เลิกงาน (ถ่ายรูป + GPS + เวลา)

คำนวณ ชั่วโมงทำงาน / มาสาย / OT

ดึงเข้า KPI อัตโนมัติ

SOP Management

SOP ครัว

SOP บริการ

SOP เตรียมของ

SOP เก็บโต๊ะใน 2 นาที

SOP เปิด–ปิดร้าน

Checklist + รูปถ่ายหลักฐาน

บันทึก Task → คำนวณ KPI

KPI Engine

KPI Attendance

KPI งานประจำวัน

KPI ความเร็วเก็บโต๊ะ

KPI คุณภาพงาน

KPI รวมรายวัน / รายเดือน

Export PDF / Dashboard (Optional)

Daily Report

ของหมด

ปัญหาในร้าน

ความสะอาด

ข้อเสนอแนะ

ส่งรายงานทุกวันก่อนปิดร้าน

2. USER ROLES
Role	Permissions
Owner	Access all modules, KPI report, attendance, export
Manager	Approve tasks, verify attendance, view KPI
Staff (Kitchen)	ดู SOP ครัว, ลงงาน, ถ่ายรูป
Staff (Service)	ดู SOP บริการ, เก็บโต๊ะ, เติมของ
Staff (Cleaner)	SOP ล้างจาน, ความสะอาด
Staff (Cashier)	Daily report, ปิดร้าน
3. FRONTEND PAGES (MOBILE FIRST)
3.1 Dashboard (Today Overview)

ชื่อพนักงาน

รูปโปรไฟล์

เวลางานวันนี้: xx:xx–xx:xx

ปุ่มใหญ่:

เข้างาน

เลิกงาน

สถานะ:

มาสายกี่นาที

ชั่วโมงทำงาน

Section:

SOP วันนี้

Tasks ที่ต้องทำ

สรุป KPI วันนี้

3.2 Attendance Page
Check-in Flow:

เปิดกล้องทันที (capture="environment")

ถ่ายรูปหน้า/ยูนิฟอร์ม

บันทึกเวลา + GPS

แสดงสถานะ "เข้างานแล้ว"

Check-out Flow:

เปิดกล้อง (optional)

บันทึกเวลาออก

สรุปเวลาทำงาน:

เวลารวม

มาสายกี่นาที

OT กี่นาที

3.3 SOP List Page

Grouped by department:

Kitchen

เตรียมเนื้อ

เตรียมลูกชิ้น

เตรียมผัก

เตรียมน้ำจิ้ม

เติมของ

ทำความสะอาด

ปิดครัว

Service

เก็บโต๊ะ 2 นาที

เติมน้ำ

เติมของ

เช็ดโต๊ะ

เปิดร้าน

ปิดร้าน

3.4 SOP Task Detail Page

ชื่อ SOP

ขั้นตอนทีละข้อ (checkbox)

Timer (ถ้ามี เช่น SOP เก็บโต๊ะ)

ปุ่ม ถ่ายรูปยืนยัน

ปุ่ม ส่งงาน

ระบบให้คะแนนอัตโนมัติ

3.5 Daily Report Page

Fields:

วันนี้ร้านมีปัญหาอะไร?

ของที่กำลังจะหมด?

ความสะอาด OK ไหม?

ลูกค้าบ่นอะไรไหม?

รูปปัญหา (ถ่ายจากกล้อง)

3.6 KPI Page
Daily KPI

Attendance Score

Task Completion Score

Speed Score

Quality Score

Total Score

Monthly KPI

การมาสาย %

ชั่วโมงทำงานรวม

งานสำเร็จ %

งานไม่ส่ง / ขาดส่ง

4. CAMERA-ONLY IMAGE CAPTURE (REQUIRED)

ใช้:

<input type="file" accept="image/*" capture="environment">


คุณสมบัติ:

เปิดกล้องโดยตรง

ป้องกันเลือกภาพเก่า

รองรับ LINE WebView

รองรับ iOS/Android ทุกเครื่อง

ระบบต้องทำ:

บีบอัดรูป (compress >= 50%)

ใส่ timestamp watermark

ใส่ user_id และ task_id บนรูป

อัปโหลดเข้าสู่ Storage

5. DATABASE SCHEMA (COMPLETE)
5.1 employees
{
  "id": "uuid",
  "name": "string",
  "phone": "string",
  "role": "kitchen|service|cleaner|cashier|manager|owner",
  "avatar_url": "string",
  "line_user_id": "string",
  "active": true
}

5.2 shifts
{
  "id": "uuid",
  "employee_id": "uuid",
  "date": "date",
  "planned_start": "time",
  "planned_end": "time"
}

5.3 attendance_records
{
  "id": "uuid",
  "employee_id": "uuid",
  "shift_id": "uuid",
  "check_in_at": "datetime",
  "check_in_photo_url": "string",
  "check_in_lat": "float",
  "check_in_lng": "float",

  "check_out_at": "datetime",
  "check_out_photo_url": "string",
  "check_out_lat": "float",
  "check_out_lng": "float",

  "worked_minutes": "int",
  "late_minutes": "int",
  "overtime_minutes": "int",
  "attendance_score": "int"
}

5.4 sop_categories
{
  "id": "uuid",
  "name": "kitchen|service|cleaning|opening|closing"
}

5.5 sop_items
{
  "id": "uuid",
  "category_id": "uuid",
  "title": "string",
  "description": "text",
  "expected_minutes": "int",
  "require_photo": true
}

5.6 sop_steps
{
  "id": "uuid",
  "sop_item_id": "uuid",
  "step_number": "int",
  "content": "text"
}

5.7 task_records
{
  "id": "uuid",
  "employee_id": "uuid",
  "sop_item_id": "uuid",
  "timestamp": "datetime",
  "timer_seconds": "int",
  "photo_url": "string",
  "hash": "string",
  "score": "int"
}

5.8 daily_reports
{
  "id": "uuid",
  "employee_id": "uuid",
  "date": "date",
  "problems": "text",
  "out_of_stock": "text",
  "cleanliness": "text",
  "customer_complaints": "text",
  "photo_url": "string"
}

6. KPI FORMULA
6.1 Attendance Score
if late_minutes = 0 → score = 10  
if late ≤ 5 min → 8  
late ≤ 15 min → 5  
late > 15 min → 2  
absent → 0

6.2 Task Score

Task สำเร็จ = 2 คะแนน

ถ่ายรูปถูกต้อง = 2

ทำงานเร็วกว่าเวลา = +1

ส่งช้ากว่าเวลา = -1

6.3 Total Daily KPI
total_score = attendance_score + task_score_sum

7. API SPEC
POST /attendance/check-in

ใช้กล้อง

บันทึกเวลา

ส่งรูป storage URL

return score ชั่วคราว

POST /attendance/check-out

คำนวณเวลาทำงาน

อัปเดต OT/late

Return KPI summary

GET /sop/list

หมวด → รายการ SOP

GET /sop/{id}

รายละเอียด + Steps

POST /task/submit

ส่ง checklist

ถ่ายรูป

เก็บ timer

คำนวณคะแนน

POST /daily-report

ข้อมูลรายวัน + รูปถ่าย

GET /kpi/daily/{employee_id}
GET /kpi/monthly/{employee_id}
8. SECURITY RULES

พนักงานต้องอยู่ในรัศมีร้าน (optional)

ต้อง login ผ่าน LINE

รูปทุกใบต้องใส่ timestamp watermark

ห้ามเลือกรูปจาก gallery

ห้ามแก้เวลา client → ทุกเวลาใช้ server time

9. DEPLOYMENT

แนะนำ Stack:

Frontend: Next.js / React
Backend: Firebase Functions หรือ Laravel
Database: Firestore / Supabase / MySQL
Storage: Firebase Storage หรือ DO Spaces
Auth: LINE Login

ต้องรองรับ:

PWA (ติดตั้งบนมือถือ)

Mobile-first UI

ใช้ผ่าน LINE WebView ได้

10. TASK FOR DEVELOPER (CLAUDE)

ให้ Claude ทำสิ่งนี้ ไม่ต้องถาม:

สร้างโครง Frontend (Next.js App Router)

ทำ UI Mobile-first ทุกหน้า

ทำระบบถ่ายรูป (camera only)

ทำระบบ Login ด้วย LINE

ทำ Backend API ให้ครบ

ทำ Database Schema

ทำระบบ KPI Engine

ทำระบบ Daily Report

ทำระบบ Attendance เชื่อม KPI

Deploy ตัวอย่าง Demo ให้พร้อมใช้งาน

END OF FILE

SOP_KPI_ATTENDANCE_SYSTEM_SPEC.md
