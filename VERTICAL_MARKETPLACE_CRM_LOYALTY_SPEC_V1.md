
> ระบบ Marketplace เฉพาะกลุ่ม + CRM + Loyalty + Ads  
> Tech: Laravel 11 API + Flutter (2 apps) + Firebase + DigitalOcean

---

## 0. OVERVIEW

แพลตฟอร์มนี้คือระบบ:

- **Vertical Marketplace** – รวมร้านค้าหมวดเดียวกันในแอปเดียว (เช่น ร้านขายมะพร้าว/สินค้าเฉพาะกลุ่ม)
- **Loyalty & Coupon** – สะสมแต้มด้วย QR + ใช้แต้มแลกคูปองแบบ KFC/McD (1 คูปองใช้ได้ครั้งเดียว ภายใน 24 ชม.)
- **Targeted Ads** – ร้านค้าซื้อแคมเปญดันร้าน/โปรโมชันแบบจ่ายเป็นครั้ง ๆ
- **Anti-Fraud** – ป้องกันโกงแต้มและคูปองด้วยกฎและ log ระดับแพลตฟอร์ม
- **Admin Backend** – ดูแลร้านค้า, ผู้ใช้, คูปอง, โฆษณา, รายงาน, fraud

ระบบต้อง:

- ออกแบบให้ **ขยายง่าย**, **ไม่แก้ migration ย้อนหลัง**, **ใช้ event/log เป็นหลัก**
- ประกอบด้วย **8 Milestones** ตามแผนการชำระเงิน (ด้านล่าง)

---

## 1. TECH & ARCHITECTURE

### 1.1 Backend

- Laravel 11, PHP 8.2
- DB: MySQL 8
- Auth: Laravel Sanctum หรือ Passport (เลือกแบบเหมาะ API-only)
- Queue: Laravel Queue (Redis หรือ database queue ช่วงแรก)
- Cache: Laravel Cache (file/Redis)
- Env: แยก `.env.local`, `.env.staging`, `.env.production`

### 1.2 Mobile Apps

- Flutter (ล่าสุดที่รองรับ Stable)
- โปรเจคเดียว แยกเป็น 2 flavor:
  - `user_app`
  - `merchant_app`
- ใช้ Firebase:
  - Authentication (Email/Password, Social ได้ในอนาคต)
  - Cloud Messaging (Push Notification)

### 1.3 Infra

- DigitalOcean Droplet (เริ่ม 1 vCPU / 1GB RAM)
- Caddy / Nginx + PHP-FPM
- HTTPS (Let’s Encrypt)
- Git repo แยก:
  - `vertical-backend`
  - `vertical-user-app`
  - `vertical-merchant-app`

### 1.4 Coding Conventions (ให้ Claude ทำตาม)

- ใช้ PSR-12, Laravel best practices
- ทุก feature สำคัญต้องมี:
  - Migration
  - Model
  - Service/Action class (logic)
  - Controller + Request validation
  - Feature test (อย่างน้อย flow หลัก)
- ห้ามแก้ migration ย้อนหลัง **เด็ดขาด**  
  ถ้าต้องเปลี่ยน schema → สร้าง migration ใหม่เสมอ
- ใช้ soft delete เฉพาะ entity หลัก (users, stores) ข้อมูลสำคัญใช้ flag/status ดีกว่าลบ

---

## 2. DOMAIN MODEL (LEVEL HIGH)

### 2.1 Users & Merchants

- `users`
  - id
  - name
  - email
  - phone
  - role: `user`, `merchant_owner`, `merchant_staff`, `admin`
  - firebase_uid (optional)
  - created_at, updated_at

- `merchants`
  - id
  - owner_user_id
  - name
  - description
  - category
  - logo_url
  - is_active
  - created_at, updated_at

- `stores`
  - id
  - merchant_id
  - name
  - description
  - address_text
  - lat, lng
  - phone
  - open_hours_json
  - is_active
  - created_at, updated_at

- `store_staff`
  - id
  - store_id
  - user_id (staff)
  - role_in_store (`owner`, `manager`, `staff`)
  - is_active

### 2.2 Marketplace & Reviews

- `store_views`
  - id
  - store_id
  - user_id (nullable)
  - source (`search_list`, `map`, `direct`, `ad_campaign`)
  - created_at

- `store_view_stats_daily`
  - id
  - store_id
  - date
  - views_count

- `store_reviews`
  - id
  - store_id
  - user_id
  - rating (1–5)
  - comment
  - created_at

### 2.3 Loyalty – Points

แนวคิด: **1 user มี point account ต่อ platform** (ไม่แยกร้าน) แต่ต้อง track ว่ามาจากร้านไหน

- `user_points_accounts`
  - id
  - user_id
  - total_points_balance (รวมทั้งหมด)
  - created_at, updated_at

- `user_points_ledger`
  - id
  - user_id
  - store_id
  - type: `earn`, `redeem`, `adjustment`
  - points_delta (บวก/ลบ)
  - reason (`purchase`, `coupon_redeem`, `admin_adjust`, etc.)
  - related_coupon_id (nullable)
  - meta_json (backup data)
  - created_at

> **Important:** ไม่แก้ไข ledger ย้อนหลัง ใช้เพิ่ม row เสมอ

### 2.4 Loyalty – Earn QR

- ไม่มี POS, ร้านแค่ “สแกน QR ของ user” แล้วให้แต้มตามที่กำหนด
- กติกาแต้มต่อร้านเก็บใน:

- `store_point_rules`
  - id
  - store_id
  - earn_mode: `manual_fixed` (phase 1) / รองรับ `per_purchase` ภายหลัง
  - default_points_per_visit (int)
  - daily_limit_per_user (nullable int)
  - monthly_limit_per_user (nullable int)
  - created_at, updated_at

Earn QR token ไม่ต้องเก็บ table สำหรับทุก QR แค่ sign แล้ว validate จาก server side (stateless)

### 2.5 Coupon & Redeem

- `rewards_catalog`
  - id
  - store_id (คูปองของร้านนี้)
  - name
  - description
  - points_cost
  - is_active
  - created_at, updated_at

- `user_coupons`
  - id
  - user_id
  - store_id
  - reward_id
  - status: `unused`, `used`, `expired`, `blocked`
  - issued_at
  - expires_at (24h จาก issued)
  - used_at (nullable)
  - used_by_store_staff_id (nullable)
  - used_device_info (nullable)
  - created_at, updated_at

Coupon QR = token ที่อ้างอิง `user_coupons.id` + signature

### 2.6 Ads & Payment

- `ad_campaigns`
  - id
  - store_id
  - type: `store_boost`, `reward_boost`
  - title
  - description
  - target_area_json (เช่น radius, geo bounding)
  - start_at
  - end_at
  - status: `pending_payment`, `active`, `finished`, `cancelled`
  - created_at, updated_at

- `ad_payments`
  - id
  - ad_campaign_id
  - amount
  - currency
  - gateway (`omise`, etc.)
  - gateway_txn_id
  - status: `pending`, `paid`, `failed`, `refunded`
  - paid_at (nullable)
  - created_at, updated_at

### 2.7 Fraud & Monitoring

- `fraud_flags`
  - id
  - type: `user_store_points`, `coupon_abuse`, `store_abuse`
  - user_id (nullable)
  - store_id (nullable)
  - related_coupon_id (nullable)
  - severity: `low`, `medium`, `high`
  - status: `open`, `reviewed`, `closed`
  - reason_code
  - details_json
  - created_at, updated_at

---

## 3. API & SECURITY PRINCIPLES

- ใช้ JSON REST API
- ทุก endpoint auth ผ่าน:
  - Bearer token (Sanctum / Passport)
- Validation ด้วย Form Requests
- QR token:
  - รูป: `base64url( JSON )` + HMAC signature
  - ข้อมูล:
    - สำหรับ Earn: `{ user_id, issued_at, expires_at }`
    - สำหรับ Coupon: `{ coupon_id, issued_at }`
  - ใช้ secret key ใน Laravel config
- ป้องกัน replay:
  - Coupon → check `status = unused` และ transaction lock (DB transaction + `SELECT ... FOR UPDATE`)

---

## 4. MILESTONES (TIED TO PAYMENT)

> สำคัญ: ทุก Milestone ต้อง:
> - โค้ด push git พร้อม tag หรือ branch ตาม milestone
> - มี CHANGELOG อัปเดต
> - มี README ระบุวิธีรัน/ทดสอบ ณ จุดนั้น

---

### M1 – Setup + Architecture (15%)

**เป้าหมาย:** ระบบ skeleton รันได้บน DO, Auth/โครงสร้างพร้อม, Firebase/Maps wired-in (ขั้นต่ำ)

#### Backend

- สร้าง Laravel project
- ตั้งค่า:
  - `.env.example` ครบ
  - ค่ามาตรฐาน DB, cache, queue
- สร้างฐานโครงสร้าง:
  - Users
    - Migration: `users` (ตามด้านบน, ยังไม่จำเป็นต้องครบทุก field ยิบย่อย)
    - Model: `User`
  - Basic Auth skeleton (ไม่ต้อง full yet)
- สร้าง `merchants`, `stores` migration + model แบบ basic (ยังไม่ต้องใส่ rule logic)
- สร้าง basic route:
  - `GET /health` → `{ status: "ok" }`
  - `GET /version` → app version จาก config

#### Infra

- Droplet DO + docker หรือ bare metal Laravel stack
- Domain ชั่วคราว (เช่น `api.staging.domain.com`)
- HTTPS OK

#### Mobile

- สร้าง Flutter projects:
  - `user_app/`
  - `merchant_app/`
- ตั้งค่า:
  - Firebase project (staging)
  - Google Maps key (staging)
- สร้างหน้าเปล่า:
  - Splash
  - Login page (UI-only ยังไม่เชื่อม backend)

---

### M2 – Auth System (10%)

**เป้าหมาย:** Login/Signup ใช้งานได้จริงทั้ง User & Merchant, role-based

#### Backend

- Implement Auth (เลือกอย่างใดอย่างหนึ่ง):
  - Laravel Sanctum (SPA/API tokens)
- Endpoint ที่ต้องมี:
  - `POST /auth/register` (user)
  - `POST /auth/login`
  - `POST /auth/logout`
  - `GET /me`
- แยก role:
  - `merchant_owner` สามารถสร้าง `merchant`+`store`
- Migration update `users` เพิ่ม:
  - `role`
  - `firebase_uid` (nullable)
- Protect route ด้วย middleware role-based (เช่น `role:merchant_owner`)

#### Mobile – User App

- เชื่อม Login/Signup กับ backend
- เก็บ token securely (secure storage)
- หลัง login → navigate ไปหน้า Home (stub)

#### Mobile – Merchant App

- Login ด้วย email/password (ของ merchant owner หรือ staff)
- Stub หน้า Home ร้าน

---

### M3 – Marketplace Core (10%)

**เป้าหมาย:** ค้นหาร้าน + map + โปรไฟล์ร้าน + review basic

#### Backend

- Table/Model:
  - `merchants`, `stores`, `store_reviews`, `store_views`, `store_view_stats_daily`
- Endpoint:
  - `GET /stores` (filter: keyword, lat/lng, radius, can_redeem_points=bool)
  - `GET /stores/{id}`
  - `GET /stores/{id}/reviews`
  - `POST /stores/{id}/reviews` (เฉพาะ user)
- เมื่อเรียก `GET /stores/{id}`:
  - บันทึก `store_views`
  - สร้าง service job สำหรับ aggregate stat daily
- Basic review (rating + comment)

#### Mobile – User App

- หน้า Home:
  - แสดง list ร้าน
  - สามารถกดดู map
- หน้า Store Detail:
  - ข้อมูลร้าน
  - รีวิว (อ่าน/เขียน)
  - ปุ่ม:
    - “รับแต้ม”
    - “ใช้แต้ม/คูปอง”

---

### M4 – Earn QR System (10%)

**เป้าหมาย:** Flow รับแต้มครบ: User → QR → Merchant scan → เพิ่มแต้ม + ledger

#### Backend

- Table:
  - `user_points_accounts`
  - `user_points_ledger`
  - `store_point_rules`
- Logic:
  - สร้าง service `PointsService`:
    - `earnPoints(User $user, Store $store, int $points, string $reason, array $meta = [])`
- Endpoint:

  - User:
    - `GET /user/points/summary` → total balance, history summary
    - `GET /user/points/ledger` → รายการ detail (paginate)

  - QR Earn:
    - `GET /user/earn-qr` (auth user) → return token (QR payload) + expires_in (เช่น 30 วินาที)
    - `POST /merchant/earn-from-qr`:
      - body: `qr_token`, `store_id`, optional `points_override` (phase1 ให้ manual)
      - ตรวจ:
        - QR valid & not expired
        - ตรวจ limit (*phase2 สามารถเพิ่ม*)
      - ถ้า OK:
        - สร้าง ledger + update account balance
      - return result + new balance

#### Mobile

- User App:
  - หน้า “รับแต้ม”:
    - แสดง QR dynamic
    - countdown หมดเวลา
  - หน้า “แต้มของฉัน”: แสดงยอดรวม + history สรุป

- Merchant App:
  - หน้า “ให้แต้มลูกค้า”:
    - เปิดกล้องสแกน QR user
    - สอบถามจำนวนแต้ม (หรือใช้ default จาก rules)
    - ส่ง `earn-from-qr` แล้วแสดง result

---

### M5 – Coupon Redeem System (10%)

**เป้าหมาย:** ใช้แต้มแลกคูปอง, คูปองใช้ได้ครั้งเดียวด้วย QR

#### Backend

- Table:
  - `rewards_catalog`
  - `user_coupons`
- Rules:
  - แลกคูปอง:
    - เช็คว่ามีแต้ม >= costs
    - สร้าง `user_coupons` status `unused`
    - สร้าง ledger `redeem` (points_delta = -cost)
    - expire = 24 ชม. จาก issued_at
- Endpoint:

  - Catalog:
    - `GET /stores/{id}/rewards`
  - Redeem:
    - `POST /stores/{id}/rewards/{reward_id}/redeem`
      - สร้างคูปอง + หักแต้ม
    - `GET /user/coupons` (filter: active, expired, used)
    - `GET /user/coupons/{id}/qr` → payload สำหรับ QR

  - Validate Coupon (ฝั่ง merchant):
    - `POST /merchant/coupons/validate-and-use`
      - body: `qr_token`, `store_id`
      - ตรวจ:
        - coupon belong to store
        - status = `unused`
        - not expired
      - ใน transaction:
        - lock row coupon
        - เปลี่ยนเป็น `used`
        - set `used_at`, `used_by_store_staff_id`
      - return result: OK / already_used / expired / invalid

- Cron job:
  - mark coupons expired (status `expired`) เมื่อ `now > expires_at` (หรือใช้ query filter แทน)

#### Mobile

- User App:
  - หน้า “คูปอง/Rewards”:
    - แสดงรายการ rewards ของร้าน (จากหน้า store)
  - Flow Redeem:
    - แสดงแต้มที่ต้องใช้
    - confirm modal “แต้มจะถูกหักทันที”
    - หลัง redeem สำเร็จ → ไปหน้า “คูปองของฉัน”
  - “คูปองของฉัน”:
    - แสดง QR ของคูปองนั้น (ใช้ภาพเดิมตอน redeem ได้)

- Merchant App:
  - หน้า “ใช้คูปอง”:
    - เปิดสแกน QR
    - ส่งไป validate
    - แสดง:
      - สำเร็จ (สีเขียว)
      - แดงถ้าใช้แล้ว/หมดอายุ/ไม่ใช่ร้านนี้

---

### M6 – Ads + Payment (10%)

**เป้าหมาย:** ร้านซื้อโฆษณา → จ่ายเงิน → store ถูก boost ใน search

#### Backend

- Table:
  - `ad_campaigns`
  - `ad_payments`
- Endpoint:

  - สร้าง campaign:
    - `POST /merchant/ad-campaigns`
      - body: `type`, `store_id`, `duration_days`, `title`, `description`
      - คำนวณราคา (simple: base_rate_per_day * days)
      - สร้าง `ad_campaign` status `pending_payment`
      - สร้าง `ad_payment` status `pending`
      - คืน payment intent / payment_url

  - Webhook Payment Gateway:
    - `POST /payments/webhook`
      - ตาม provider ที่ใช้
      - หากจ่ายสำเร็จ:
        - mark payment `paid`
        - set campaign status `active`, start_at, end_at

- Ranking Search:
  - ใน `GET /stores`:
    - ranking = base relevance + boost score
    - ถ้าร้านมี `ad_campaign` active:
      - +weight เพื่อดันขึ้น (ไม่ต้องโชว์คำว่า “sponsor”)

#### Mobile – Merchant App

- หน้า “โปรโมทร้าน/โปรโมชัน”:
  - list campaigns ปัจจุบัน/เก่า
  - ปุ่ม “สร้างแคมเปญใหม่”
  - Flow ไปยัง payment (webview หรือ SDK)

---

### M7 – Admin Panel + Analytics (10%)

**เป้าหมาย:** Admin จัดการระบบ + ดูรายงาน + monitor fraud

#### Backend

- ใช้ Laravel + Filament / Nova / Backpack (เลือก 1)
- Module Admin:

  - Users:
    - list, view, ban (is_active flag)

  - Merchants & Stores:
    - approve / deactivate stores
    - แก้ไขข้อมูลเบื้องต้น

  - Coupons:
    - filter by status, store, user
    - ดู details

  - Points:
    - ดู ledger by user/store

  - Ads:
    - list campaigns
    - ดู payment

  - Fraud Flags:
    - list flags
    - mark reviewed/closed

- Analytics (basic):

  - จำนวนผู้เข้าดูร้านรายวัน/เดือน
  - Top stores by views
  - จำนวนคูปองที่ใช้ / หมดอายุ
  - จำนวนแต้มที่แจก vs ใช้

#### Fraud Basic Rules (batch job / service)

- สร้าง service job ที่รันทุกคืน:

  - Rule ตัวอย่าง:
    - ถ้า user คนเดียวได้รับแต้มจาก store เดียว > X แต้มใน 7 วัน
      → สร้าง `fraud_flags` type `user_store_points`
    - ถ้า coupon ถูก reject because already_used หลายครั้ง
      → flag type `coupon_abuse`

---

### M8 – Final QA + Store Upload + Go-Live (25%)

**เป้าหมาย:** ระบบพร้อมจริงสำหรับผู้ใช้จริง, performance + security ok

#### Checklist

- Backend:
  - run all tests pass
  - ตรวจ env ไม่หลุด dev key
  - ปิด debug
  - log level เหมาะสม

- Mobile:
  - แก้ UX friction
  - Loading states / error states ครบ
  - ตรวจ Flow สำคัญทุก combination:
    - สมัคร → รับแต้ม → ใช้แต้ม → ใช้คูปอง
    - ซื้อ campaign → ร้านติดอันดับ

- Security Basic:
  - rate-limit API สำคัญ (auth, earn-from-qr, coupon validate)
  - QR token verify key อยู่ใน config ไม่ hardcode
  - ป้องกัน user แก้ store_id ข้ามร้าน

- Deployment:
  - production environment
  - backup plan / snapshot DO
  - deploy script (bash) ให้ใช้คำสั่งเดียว

- Store Upload:
  - เตรียม icon, screenshot, description
  - ส่ง binary ขึ้น Google Play & App Store ด้วย package name ที่ลูกค้าต้องการ

---

## 5. NOTES FOR AI CODING AGENT (CLAUDE CODE)

> ส่วนนี้ไว้เป็น “คำสั่งทั่วไป” สำหรับ AI dev ที่จะ implement ระบบ

- คุณคือ Senior Fullstack Engineer
- ห้ามถามย้ำ requirement ซ้ำ ๆ ให้ใช้ spec นี้เป็น source of truth
- ทำงานเป็น **Milestone ตามหัวข้อ M1–M8**
- ทุก Milestone:
  - อัปเดต `CHANGELOG.md`
  - อัปเดต `docs/` ถ้ามีสิ่งใหม่
  - run test ก่อน commit
- ห้ามแก้ migration ย้อนหลัง
- ถ้าต้อง refactor:
  - สร้าง class ใหม่ หรือ migration ใหม่
  - เขียน test ครอบก่อนเปลี่ยน
- log ไฟล์สำคัญ:
  - `docs/API_REFERENCE.md`
  - `docs/ERD.md`
  - `docs/DEPLOYMENT.md`

---

จบ SPEC เวอร์ชัน V1  
