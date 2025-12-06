# API_REFERENCE.md

> API หลักของ Vertical Marketplace + CRM + Loyalty + Ads  
> Backend: Laravel 11, JSON REST, Auth ด้วย Bearer Token (Sanctum/Passport)

---

## 0. CONVENTIONS

- Base URL (ตัวอย่าง)
  - Staging: `https://api.staging.example.com`
  - Production: `https://api.example.com`
- ทุก request/response เป็น `application/json`
- Auth:
  - ส่วนใหญ่ใช้ `Authorization: Bearer <token>`
- การแบ่ง role:
  - `user`
  - `merchant_owner` / `merchant_staff`
  - `admin`

---

## 1. AUTH & USER

### 1.1 Register User

`POST /auth/register`

**Body:**

```json
{
  "name": "User Name",
  "email": "user@example.com",
  "password": "secret123",
  "password_confirmation": "secret123"
}
Response 201:

json
Copy code
{
  "user": {
    "id": 1,
    "name": "User Name",
    "email": "user@example.com",
    "role": "user"
  },
  "token": "xxxx"
}
1.2 Login
POST /auth/login

Body:

json
Copy code
{
  "email": "user@example.com",
  "password": "secret123"
}
Response 200:

json
Copy code
{
  "user": {
    "id": 1,
    "name": "User Name",
    "email": "user@example.com",
    "role": "user"
  },
  "token": "xxxx"
}
1.3 Logout
POST /auth/logout

Header: Bearer token

Response 200:

json
Copy code
{ "message": "Logged out" }
1.4 Get Me
GET /me

Header: Bearer token

Response 200:

json
Copy code
{
  "id": 1,
  "name": "User Name",
  "email": "user@example.com",
  "role": "user",
  "created_at": "2025-01-01T00:00:00Z"
}
2. MERCHANT & STORES
2.1 Create Merchant (merchant_owner เท่านั้น)
POST /merchant/merchants

Body:

json
Copy code
{
  "name": "Brand Name",
  "description": "About this brand"
}
Response 201:

json
Copy code
{
  "id": 1,
  "name": "Brand Name",
  "description": "About this brand"
}
2.2 Create Store
POST /merchant/stores

Body:

json
Copy code
{
  "merchant_id": 1,
  "name": "Store Chiang Mai",
  "description": "Branch CM",
  "address_text": "Somewhere",
  "lat": 18.78,
  "lng": 98.98,
  "phone": "0812345678",
  "open_hours_json": {
    "mon": "09:00-20:00",
    "tue": "09:00-20:00"
  }
}
Response 201:

json
Copy code
{
  "id": 10,
  "merchant_id": 1,
  "name": "Store Chiang Mai",
  "is_active": true
}
2.3 List Stores (Marketplace Search)
GET /stores

Query params:

q (optional): คำค้น

lat / lng (optional): location user

radius_km (optional)

can_redeem (optional, boolean): filter ร้านที่มี reward/คูปอง

page, per_page

Response 200:

json
Copy code
{
  "data": [
    {
      "id": 10,
      "name": "Store Chiang Mai",
      "description": "Branch",
      "lat": 18.78,
      "lng": 98.98,
      "distance_km": 2.1,
      "rating": 4.5,
      "review_count": 12,
      "has_rewards": true,
      "is_boosted": true
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5
  }
}
2.4 Get Store Detail
GET /stores/{id}

Response 200:

json
Copy code
{
  "id": 10,
  "name": "Store Chiang Mai",
  "description": "Branch CM",
  "address_text": "Somewhere",
  "lat": 18.78,
  "lng": 98.98,
  "phone": "0812345678",
  "rating": 4.5,
  "review_count": 12,
  "images": [],
  "rewards_count": 2
}
3. REVIEWS
3.1 List Reviews
GET /stores/{id}/reviews

Response 200:

json
Copy code
{
  "data": [
    {
      "id": 1,
      "user_name": "A",
      "rating": 5,
      "comment": "ดีมาก",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ]
}
3.2 Create Review (user)
POST /stores/{id}/reviews

Body:

json
Copy code
{
  "rating": 5,
  "comment": "ดีมาก"
}
Response 201:

json
Copy code
{
  "id": 2,
  "rating": 5,
  "comment": "ดีมาก"
}
4. POINTS (LOYALTY – USER SIDE)
4.1 Get Points Summary
GET /user/points/summary

Response 200:

json
Copy code
{
  "total_balance": 120,
  "last_updated_at": "2025-01-02T10:00:00Z"
}
4.2 Get Points Ledger
GET /user/points/ledger?page=1

Response 200:

json
Copy code
{
  "data": [
    {
      "id": 1,
      "store_id": 10,
      "store_name": "Store Chiang Mai",
      "type": "earn",
      "points_delta": 5,
      "reason": "purchase",
      "created_at": "2025-01-01T12:00:00Z"
    }
  ]
}
4.3 Get Earn QR (User)
GET /user/earn-qr

ใช้โดย User App เพื่อสร้าง QR ให้ร้านสแกน

Response 200:

json
Copy code
{
  "qr_token": "base64url-token",
  "expires_at": "2025-01-01T12:01:00Z",
  "expires_in_seconds": 60
}
5. POINTS (MERCHANT – GIVE POINTS)
5.1 Merchant Earn from QR
POST /merchant/earn-from-qr

Header: Bearer (merchant staff)

Body:

json
Copy code
{
  "store_id": 10,
  "qr_token": "base64url-token",
  "points": 5
}
Response 200:

json
Copy code
{
  "success": true,
  "user_id": 1,
  "new_balance": 125
}
6. REWARDS & COUPONS
6.1 List Rewards for Store (catalog)
GET /stores/{id}/rewards

Response 200:

json
Copy code
{
  "data": [
    {
      "id": 1,
      "name": "ส่วนลด 10 บาท",
      "description": "ใช้ได้กับทุกเมนู",
      "points_cost": 20,
      "is_active": true
    }
  ]
}
6.2 Redeem Reward → Create Coupon
POST /stores/{store_id}/rewards/{reward_id}/redeem

Body: (ไม่ต้องส่งอะไรเพิ่มก็ได้ ถ้าใช้แต้มตรง ๆ)

Response 201:

json
Copy code
{
  "coupon": {
    "id": 100,
    "store_id": 10,
    "reward_id": 1,
    "status": "unused",
    "issued_at": "2025-01-01T10:00:00Z",
    "expires_at": "2025-01-02T10:00:00Z"
  },
  "new_balance": 100
}
6.3 List User Coupons
GET /user/coupons?status=unused

Response 200:

json
Copy code
{
  "data": [
    {
      "id": 100,
      "store_id": 10,
      "store_name": "Store Chiang Mai",
      "reward_name": "ส่วนลด 10 บาท",
      "status": "unused",
      "issued_at": "2025-01-01T10:00:00Z",
      "expires_at": "2025-01-02T10:00:00Z"
    }
  ]
}
6.4 Get Coupon QR (User)
GET /user/coupons/{id}/qr

Response 200:

json
Copy code
{
  "qr_token": "base64url-token",
  "coupon_id": 100,
  "expires_at": "2025-01-02T10:00:00Z"
}
6.5 Merchant Validate & Use Coupon
POST /merchant/coupons/validate-and-use

Body:

json
Copy code
{
  "store_id": 10,
  "qr_token": "base64url-token"
}
Response 200:

กรณีสำเร็จ:

json
Copy code
{
  "status": "ok",
  "coupon": {
    "id": 100,
    "reward_name": "ส่วนลด 10 บาท",
    "used_at": "2025-01-01T12:00:00Z"
  }
}
กรณีผิดพลาด (ตัวอย่าง):

json
Copy code
{ "status": "already_used" }
{ "status": "expired" }
{ "status": "invalid" }
{ "status": "not_belong_to_store" }
7. ADS & PAYMENT
7.1 Create Ad Campaign
POST /merchant/ad-campaigns

Body:

json
Copy code
{
  "store_id": 10,
  "type": "store_boost",
  "title": "ดันร้าน 3 วัน",
  "description": "โปรโมชั่นเปิดร้านใหม่",
  "duration_days": 3
}
Response 201:

json
Copy code
{
  "campaign": {
    "id": 1,
    "store_id": 10,
    "type": "store_boost",
    "status": "pending_payment",
    "start_at": null,
    "end_at": null
  },
  "payment": {
    "id": 10,
    "amount": 29900,
    "currency": "THB",
    "payment_url": "https://pay.example.com/..."
  }
}
7.2 List Merchant Campaigns
GET /merchant/ad-campaigns

Response:

json
Copy code
{
  "data": [
    {
      "id": 1,
      "store_id": 10,
      "type": "store_boost",
      "status": "active",
      "start_at": "2025-01-01T00:00:00Z",
      "end_at": "2025-01-04T00:00:00Z"
    }
  ]
}
7.3 Payment Webhook
POST /payments/webhook

使用 payment gateway spec ไม่อธิบายละเอียดในนี้

Logic:

ถ้าชำระสำเร็จ:

mark ad_payments.status = paid

update ad_campaigns.status = active

set start_at, end_at

Response 200 (simple):

json
Copy code
{ "ok": true }
8. ADMIN API (เฉพาะ Admin Panel – อาจใช้ web guard ไม่ต้อง JSON ก็ได้)
ตัวอย่าง (ถ้าจำเป็นต้อง JSON API):

GET /admin/users

GET /admin/stores

GET /admin/fraud-flags

PATCH /admin/coupons/{id} (force block)

รายละเอียด deep-level ให้ไปกำหนดใน Admin framework (Filament/Nova) แทน API

yaml
Copy code

---

```markdown
# ERD.md

> ERD สำหรับ Vertical Marketplace + CRM + Loyalty + Ads

---

## 1. HIGH LEVEL DIAGRAM (TEXT)

```text
Users (user, merchant_owner, merchant_staff, admin)
  |
  | 1 - n (owner)
  v
Merchants
  |
  | 1 - n
  v
Stores ----< StoreReviews
  |  \
  |   \------< StoreViews >------ Users
  |
  +----< StorePointRules
  |
  +----< RewardsCatalog
  |           |
  |           v
Users >------ UserCoupons ----> UserPointsLedger
  ^
  |
UserPointsAccounts

Stores >---- AdCampaigns >---- AdPayments

FraudFlags (link to user/store/coupon)
2. TABLES + RELATIONSHIPS
2.1 users
id PK

name

email (unique)

password

phone (nullable)

role ENUM(user, merchant_owner, merchant_staff, admin)

firebase_uid (nullable)

timestamps

Relations:

1 user (merchant_owner) มีหลาย merchants

1 user (staff) อยู่ในหลาย store_staff records

1 user มี 1 user_points_accounts

1 user มีหลาย user_points_ledger

1 user มีหลาย user_coupons

1 user มีหลาย store_reviews

1 user มีหลาย store_views

1 user อาจผูกกับหลาย fraud_flags

2.2 merchants
id PK

owner_user_id FK → users.id

name

description (nullable)

logo_url (nullable)

is_active bool

timestamps

Relations:

1 merchant มีหลาย stores

2.3 stores
id PK

merchant_id FK → merchants.id

name

description

address_text

lat, lng

phone (nullable)

open_hours_json (json)

is_active bool

timestamps

Relations:

1 store มีหลาย store_staff

1 store มีหลาย store_reviews

1 store มีหลาย store_views

1 store มีหลาย store_point_rules (phase1 = 1 record)

1 store มีหลาย rewards_catalog

1 store มีหลาย user_coupons

1 store มีหลาย ad_campaigns

1 store อาจมีหลาย fraud_flags

2.4 store_staff
id PK

store_id FK → stores.id

user_id FK → users.id

role_in_store (owner, manager, staff)

is_active

timestamps

2.5 store_reviews
id PK

store_id FK → stores.id

user_id FK → users.id

rating int (1–5)

comment text

timestamps

2.6 store_views
id PK

store_id FK → stores.id

user_id FK → users.id (nullable, กรณี anonymous)

source (search_list, map, direct, ad_campaign)

timestamps

2.7 store_view_stats_daily
id PK

store_id FK → stores.id

date (date)

views_count int

2.8 user_points_accounts
id PK

user_id FK → users.id (unique)

total_points_balance bigint (ไม่ใช้ float)

timestamps

2.9 user_points_ledger
id PK

user_id FK → users.id

store_id FK → stores.id

type ENUM(earn, redeem, adjustment)

points_delta int (บวก/ลบ)

reason string

related_coupon_id FK → user_coupons.id (nullable)

meta_json json (nullable)

created_at timestamp

NOTE: ไม่มี updated_at เพราะ ledger ไม่ควรแก้ย้อนหลัง

2.10 store_point_rules
id PK

store_id FK → stores.id (unique per store)

earn_mode ENUM(manual_fixed)

default_points_per_visit int (เช่น 1–5 แต้ม)

daily_limit_per_user int nullable

monthly_limit_per_user int nullable

timestamps

2.11 rewards_catalog
id PK

store_id FK → stores.id

name

description

points_cost int

is_active bool

timestamps

2.12 user_coupons
id PK

user_id FK → users.id

store_id FK → stores.id

reward_id FK → rewards_catalog.id

status ENUM(unused, used, expired, blocked)

issued_at timestamp

expires_at timestamp

used_at timestamp nullable

used_by_store_staff_id FK → store_staff.id (nullable)

used_device_info text nullable

timestamps

2.13 ad_campaigns
id PK

store_id FK → stores.id

type ENUM(store_boost, reward_boost)

title

description text nullable

target_area_json json (radius, city, etc.)

start_at timestamp nullable

end_at timestamp nullable

status ENUM(pending_payment, active, finished, cancelled)

timestamps

2.14 ad_payments
id PK

ad_campaign_id FK → ad_campaigns.id

amount int (สตางค์)

currency string (THB)

gateway string (omise, ...)

gateway_txn_id string

status ENUM(pending, paid, failed, refunded)

paid_at timestamp nullable

timestamps

2.15 fraud_flags
id PK

type ENUM(user_store_points, coupon_abuse, store_abuse)

user_id FK → users.id (nullable)

store_id FK → stores.id (nullable)

related_coupon_id FK → user_coupons.id (nullable)

severity ENUM(low, medium, high)

status ENUM(open, reviewed, closed)

reason_code string

details_json json

timestamps

3. INDEXING SUGGESTIONS
users.email unique index

stores (lat, lng) spatial index (ภายหลัง)

user_points_accounts.user_id unique

user_points_ledger (user_id, created_at)

user_coupons (user_id, status, expires_at)

ad_campaigns (store_id, status, start_at, end_at)

fraud_flags (type, status)

4. FUTURE EXTENSIBILITY
สามารถเพิ่ม table:

store_categories

user_segments

ad_targeting_rules

สามารถเพิ่ม column ใน user_points_ledger เพื่อ reference order_id ถ้าในอนาคตเชื่อม POS/Order System

yaml
Copy code

---

```markdown
# CLAUDE_CODE_PROMPT.md

> Prompt สำหรับสั่ง Claude Code ให้พัฒนาระบบนี้แบบเป็นเฟส ๆ ไม่มีงง  
> ใช้ควบคู่กับ: `VERTICAL_MARKETPLACE_CRM_LOYALTY_SPEC_V1.md`, `API_REFERENCE.md`, `ERD.md`

---

## 1. ROLE & GOAL

คุณคือ **Senior Fullstack Engineer + DevOps**  
หน้าที่ของคุณ:

1. พัฒนาระบบตามสเปกใน:
   - `VERTICAL_MARKETPLACE_CRM_LOYALTY_SPEC_V1.md`
   - `API_REFERENCE.md`
   - `ERD.md`
2. ทำงานแบบ **Milestone (M1–M8)** ตามที่ระบุ  
3. ทุก Milestone:
   - โค้ดต้องรันได้จริง
   - มี commit/branch/tag ชัดเจน
   - มีการอัปเดต CHANGELOG
4. ห้ามแก้ migration ย้อนหลัง ให้สร้าง migration ใหม่เสมอเมื่อมีการเปลี่ยนแปลงโครงสร้าง

---

## 2. PROJECT STRUCTURE (แนะนำ)

คุณสามารถกำหนด directory แบบนี้ (ให้คุณสร้างเอง):

```text
/vertical-backend
  /app
  /config
  /database
  /tests
  /docs
    VERTICAL_MARKETPLACE_CRM_LOYALTY_SPEC_V1.md
    API_REFERENCE.md
    ERD.md
    CHANGELOG.md

/vertical-user-app
  lib/...
/vertical-merchant-app
  lib/...
3. WORKING PRINCIPLES
เชื่อสเปกนี้เป็นหลัก

ห้ามถาม requirement ซ้ำถ้าใน spec มีแล้ว

ถ้ามีจุดไม่เคลียร์:

เลือก default ที่ปลอดภัยและขยายได้ง่าย

บันทึกใน CHANGELOG.md ว่ามีการตัดสินใจอะไร

ใช้มาตรฐาน Laravel + Flutter best practices

ทุก Milestone เขียน Test อย่างน้อย:

Feature test สำหรับ API หลัก

Unit test สำหรับ service logic สำคัญ (เช่น PointsService, CouponService)

4. MILESTONE EXECUTION PLAN
ให้คุณทำงานตามลำดับนี้:

M1 – Setup + Architecture (15%)
เป้าหมาย:
Laravel backend รันบน DO แล้ว, Flutter project สร้างแล้ว, Firebase และ Maps config พร้อม

สิ่งที่คุณต้องทำ:

สร้าง Laravel project ใน /vertical-backend

ตั้งค่า .env.example ตาม best practice (อย่าใส่ secret จริง)

สร้าง migration + model ขั้นต้น:

users

merchants

stores

Implement route:

GET /health

GET /version

เขียน README สั้น ๆ อธิบายวิธีรัน backend

สร้าง Flutter project 2 ตัว:

/vertical-user-app

/vertical-merchant-app

ตั้งค่า Firebase project (ให้รองรับ staging/production แยก config ได้ง่าย)

อัปเดต CHANGELOG.md

หลังจบ M1 ให้มั่นใจว่า:

php artisan serve รันได้

Flutter app เปิดหน้า login เปล่าได้

M2 – Auth System (10%)
เป้าหมาย:
Login/Register + Role (user/merchant/admin) ใช้งานได้จริง

Steps:

ติดตั้งและตั้งค่า Laravel Sanctum หรือ Passport

สร้าง AuthController:

register

login

logout

me

อัปเดต users table ตาม ERD

เขียน middleware role-based

Flutter:

เชื่อมหน้า Login ของ user app + merchant app เข้ากับ API

เก็บ token ไว้ใน secure storage

เขียน Feature tests:

สมัคร/ล็อกอิน/เรียก /me ได้

เรียก endpoint เฉพาะ role แล้วเข้าถูก/ถูกปฏิเสธถูกต้อง

M3 – Marketplace Core (10%)
เป้าหมาย:
ค้นหาร้าน, ดูร้าน, รีวิว, การนับ view

Steps Backend:

ทำ migration + model:

store_reviews

store_views

store_view_stats_daily

Implement API:

GET /stores

GET /stores/{id}

GET /stores/{id}/reviews

POST /stores/{id}/reviews

เมื่อเรียก GET /stores/{id}:

บันทึก store_views

เขียน service/job รวม daily stats

Steps Mobile (User App):

หน้า Home:

แสดง list ร้านจาก /stores

หน้า Store Detail:

ข้อมูลร้าน + รีวิว (ดึงจาก API)

ปุ่ม “รับแต้ม”, “ใช้แต้ม”

เขียน tests สำหรับ:

Store search filter

Review create/list

M4 – Earn QR System (10%)
เป้าหมาย:
Flow รับแต้มเต็ม: User แสดง QR → Merchant สแกน → Backend เพิ่มแต้ม + ledger

Backend:

Migration + model:

user_points_accounts

user_points_ledger

store_point_rules

Implement PointsService:

ฟังก์ชัน earnPoints(user, store, points, reason, meta)

Implement endpoints:

GET /user/points/summary

GET /user/points/ledger

GET /user/earn-qr

POST /merchant/earn-from-qr

Implement QR token:

ใช้ HMAC + config secret

มี expire time

Mobile:

User app:

หน้า “รับแต้ม”: แสดง QR + countdown

Merchant app:

หน้า “สแกนเพื่อให้แต้ม”: สแกน QR แล้วส่งไป API

เขียน tests:

ตรวจว่า earn ledger ถูกต้อง

ตรวจ limit พื้นฐาน (อย่างน้อยไม่ให้ qr หมดอายุ)

M5 – Coupon Redeem System (10%)
เป้าหมาย:
ใช้แต้มแลกคูปอง, คูปองใช้ได้ครั้งเดียว

Backend:

Migration + model:

rewards_catalog

user_coupons

Implement:

GET /stores/{id}/rewards

POST /stores/{id}/rewards/{reward_id}/redeem

GET /user/coupons

GET /user/coupons/{id}/qr

POST /merchant/coupons/validate-and-use

ใช้ transaction lock ตอนใช้คูปอง

Job หมดอายุคูปอง (optional หรือใช้ query filter)

Mobile:

User app:

เห็น rewards จากร้าน

Redeem → คูปองเข้า “คูปองของฉัน”

แสดง QR คูปอง

Merchant app:

สแกน QR → แสดงผลสำเร็จ/ล้มเหลว

เขียน tests:

Redeem แล้วแต้มลด ถูก

ใช้คูปองได้ครั้งเดียว

ใช้ร้านผิด → ไม่ผ่าน

M6 – Ads + Payment (10%)
เป้าหมาย:
ร้านสามารถซื้อแคมเปญโฆษณา, Payment ผ่าน gateway, ร้านถูก boost

Backend:

Migration + model:

ad_campaigns

ad_payments

Implement:

POST /merchant/ad-campaigns

GET /merchant/ad-campaigns

POST /payments/webhook

Integrate gateway (mock/stub ใน dev):

แยก service class เช่น PaymentService

ใน GET /stores:

เพิ่ม scoring logic ถ้ามี campaign active

Mobile:

Merchant app:

หน้า “โปรโมทร้าน”

Flow สร้างแคมเปญ → เปิด payment URL (webview)

Tests:

Campaign active แสดงใน ranking

Webhook เปลี่ยน status ถูกต้อง

M7 – Admin Panel + Analytics (10%)
เป้าหมาย:
Admin จัดการระบบบน Web

Backend:

ติดตั้ง Filament / Nova / Backpack

สร้าง Admin panel:

Users

Merchants, Stores

Points ledger (read)

User Coupons (read, block)

Ad Campaigns

Fraud Flags

Analytics basic:

Dashboard รวมตัวเลขหลัก

Tests:

Admin auth

สิทธิ์ admin เท่านั้น

M8 – Final QA + Store Upload + Go-Live (25%)
เป้าหมาย:
ระบบพร้อม production, ขึ้น Store ทั้ง 2 แพลตฟอร์ม

Tasks:

Run full test suite

Fix bug ที่เหลือ

ปรับ UI/UX ให้เรียบร้อย

Config production env:

Debug false

Log level

Queue worker

เขียนเอกสาร:

docs/DEPLOYMENT.md

docs/USER_GUIDE_USER_APP.md

docs/USER_GUIDE_MERCHANT_APP.md

เตรียม Asset ขึ้น Store:

icon, splash, screenshot

สร้าง release tag เช่น v1.0.0

5. LOGGING & DOCUMENTATION
ทุกครั้งที่คุณ (Claude Code) ทำงานใน Milestone:

อัปเดต docs/CHANGELOG.md:

วันที่

Milestone

รายละเอียดสั้น ๆ

ถ้ามี decision สำคัญ:

บันทึกใน docs/DECISIONS.md

6. หลีกเลี่ยงสิ่งเหล่านี้
ห้ามใช้ migration Schema::dropIfExists เพื่อ reset ใน production

ห้าม hardcode key/secret ใน code

ห้ามผูก logic ธุรกิจหนัก ๆ ใน Controller ให้แยก Service/Action
