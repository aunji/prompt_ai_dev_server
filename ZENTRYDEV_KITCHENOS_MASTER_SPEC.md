# ZENTRYDEV KITCHEN OS + FLEXSTOCK SME API v2

# **MASTER SPECIFICATION (Linear, Hybrid TH/EN)**

Version: **1.0.0**
Author: **Aunji + System Architect AI**
Mode: **Claude Code Autonomous Mode**

---

# 0. CLAUDE CODE EXECUTION RULES

(กฎสำคัญที่สุดของเอกสารนี้ — ห้ามข้าม)

These rules tell Claude Code exactly *how to work*, *how to continue*, *how to save progress*, and *how to never ask questions*.

## 0.1 Autonomous Execution

* Claude must **execute tasks immediately** without asking confirmations.
* Claude must follow **phase-by-phase execution** strictly.
* Claude must NOT generate any interactive prompts.

## 0.2 Progress Logging

Claude must ALWAYS log progress:

### Directory for logs:

```
/home/aunji/kitchenos-stack/progress_logs/
```

### Files:

1. `latest_phase.txt` — the phase Claude is currently working on.
2. `{timestamp}-phase.log` — summary log of what Claude just completed.

Claude must update `latest_phase.txt` every time a phase completes.

If a phase was not completed fully, Claude must write:

```
STATUS: INCOMPLETE
WHAT_LEFT: ...
```

## 0.3 Git Rules

Claude must push code to GitHub after every major step.

### Required settings inside tasks:

```
git:
  push: true
  message: "<meaningful commit message>"
confirm: false
```

Git Repos:

```
KitchenOS API → github.com/aunji/kitchenos
FlexStock API → github.com/aunji/flexstock-api
Admin Web     → github.com/aunji/kitchenos-admin
Kitchen PWA   → github.com/aunji/kitchenos-pwa
```

## 0.4 File Writing

Every time Claude writes code, it MUST write directly to filesystem:

Examples:

```
write_file:
  path: "/home/aunji/kitchenos-stack/kitchen-api/app/Models/Recipe.php"
  content: |
     <?php ...
```

Never use placeholders or “example only”. Everything must be real code.

## 0.5 Resume Logic

Before starting any new run:

Claude must execute:

### Step 1:

```
read_file("/home/aunji/kitchenos-stack/progress_logs/latest_phase.txt")
```

### Step 2:

Claude must resume EXACTLY from that phase.

If file missing → Claude must default to:

```
PHASE 1 — Infrastructure Setup
```

## 0.6 Phase Control

Claude must run EXACTLY one phase per execution:

* Phase 1 Infrastructure
* Phase 2 FlexStock API v2
* Phase 3 KitchenOS API
* Phase 4 Admin Web
* Phase 5 Kitchen PWA
* Phase 6 PDF Engine
* Phase 7 AI Integration
* Phase 8 Logging & Monitoring
* Phase 9 CI/CD
* Phase 10 Deployment
* Phase 11 Final Verification

**Claude must NEVER skip or merge phases**.

## 0.7 No Question Rule

Claude must NEVER ask anything back.
If missing details → choose best standard practice.

---

# 1. PROJECT OVERVIEW

## TH: ภาพรวมของระบบทั้งหมด

ZENTRYDEV KITCHEN OS เป็นระบบ all-in-one สำหรับร้านอาหาร, cloud kitchen, และธุรกิจ F&B ที่ต้องการระบบสูตร, SOP, คำนวณต้นทุน, การจัดการพนักงาน และระบบครัวที่เสถียรที่สุด

FlexStock SME API v2 เป็นระบบ Inventory แบบ multi-tenant ที่ KitchenOS ใช้อ้างอิงราคาและวัตถุดิบแบบ real-time

ระบบนี้ออกแบบให้ scale ได้เหมือน Cloud Kitchen ระดับโลก และเหมาะสำหรับ SaaS ที่รองรับลูกค้าจำนวนมาก

## EN: High-level System Design

This system consists of:

1. **KitchenOS API**

   * Recipes
   * SOP
   * Costing
   * Staff Workflow
   * KPI
   * PDF

2. **FlexStock API v2**

   * Materials
   * Price History
   * Stock Batches
   * Stock Ledger
   * Multi-tenant data isolation

3. **Kitchen Admin Web (Next.js)**

4. **Kitchen PWA (Next.js PWA)**

5. **PDF Microservice**

6. **Docker-based Infra**

7. **Traefik Reverse Proxy**

8. **Redis + MySQL**

9. **AI Integration via OpenAI**

---

# 2. REPOSITORY STRUCTURE

Both APIs and services should exist within one monorepo container-stack:

```
/home/aunji/kitchenos-stack/
  ├── docker-compose.yml
  ├── traefik/
  ├── kitchen-api/
  ├── flexstock-api/
  ├── mysql/
  ├── redis/
  ├── workers/
  ├── kitchen-admin/
  ├── kitchen-pwa/
  └── progress_logs/
```

---

# 3. PHASES (Linear Execution)

```
PHASE 1 — Infrastructure Setup
PHASE 2 — FlexStock API v2 (Laravel Multi-Tenant)
PHASE 3 — KitchenOS API (Laravel Multi-Tenant)
PHASE 4 — Kitchen Admin Web (Next.js)
PHASE 5 — Kitchen PWA (Next.js PWA)
PHASE 6 — PDF Engine
PHASE 7 — AI Integration
PHASE 8 — Logging, Monitoring, Error Handling
PHASE 9 — CI/CD
PHASE 10 — Deployment
PHASE 11 — Final System Verification
```

From this point, Claude Code will follow each phase automatically and log progress.

---

# 4. PHASE 1 — INFRASTRUCTURE SETUP (Spec)

(Claude Code will execute this first)

## Goal

Set up the entire container-stack with Traefik, MySQL, Redis, Laravel Octane services, workers, and base directories.

## Deliverables

* docker-compose.yml
* Traefik configs
* MySQL init
* Redis
* Volume paths
* Network bridge
* Base folder creation

## Directory

```
/home/aunji/kitchenos-stack/
```

## Technology

* Docker Compose v3.9
* Traefik 2.9
* PHP 8.2 + Octane
* MySQL 8
* Redis 7
* Workers (queue)
* Cloudinary for file storage
* OpenAI API keys (ENV)


# 5. PHASE 1 — INFRASTRUCTURE SETUP (FULL DETAIL)

Hybrid (TH/EN)

---

# 5.1 Overview (ภาพรวมระบบ Infrastructure)

This section defines the *entire server infrastructure* that Claude Code must provision on the Droplet.

## TH สรุป:

* ใช้ Monorepo Container Stack เดียว
* แยก Service เป็น KitchenOS API / FlexStock API / Workers
* ใช้ Traefik เป็น Reverse Proxy
* ใช้ MySQL + Redis
* ใช้ Docker Volumes แยกชัดเจน
* ใช้ .env แยก per-service
* รองรับ Multi-Tenant API
* ทำงานร่วมกับ Caddy CMS ปัจจุบันได้ (ผ่าน Port Isolation)

## EN Summary:

* Root stack directory: `/home/aunji/kitchenos-stack/`
* Traefik ingress: HTTPS routing per service
* Service containers:

  * kitchen-api
  * flexstock-api
  * worker-kitchen
  * worker-flexstock
  * mysql
  * redis
* External service unaffected:

  * Existing `zentrydev_cms` & `caddy` containers
* Services run under independent docker network:

  * `kitchenos_net`

---

# 5.2 Final Directory Structure (Full)

Claude must create **this exact directory tree**:

```
/home/aunji/kitchenos-stack/
  ├── docker-compose.yml
  ├── traefik/
  │     ├── traefik.yml
  │     ├── dynamic_conf.yml
  │     └── acme.json
  ├── mysql/
  │     ├── data/ (volume)
  ├── redis/
  │     ├── data/ (volume)
  ├── kitchen-api/
  │     ├── src/ (Laravel project)
  │     ├── .env
  ├── flexstock-api/
  │     ├── src/ (Laravel project)
  │     ├── .env
  ├── workers/
  │     ├── kitchen-worker/
  │     ├── flexstock-worker/
  └── progress_logs/
```

---

# 5.3 Networking Plan

### Network Name:

```
kitchenos_net
```

### Must attach:

* traefik
* kitchen-api
* flexstock-api
* workers
* redis
* mysql

---

# 5.4 Domain Routing (Traefik)

All traffic routes by domain name:

| Domain                  | Service       | Container     |
| ----------------------- | ------------- | ------------- |
| `kitchen.zentrydev.com` | KitchenOS API | kitchen-api   |
| `stock.zentrydev.com`   | FlexStock API | flexstock-api |

No conflict with existing CMS because CMS uses Caddy and different network stack.

---

# 5.5 TRAEFIK CONFIG

Claude must generate these 3 files:

## `/traefik/traefik.yml`

```
api:
  dashboard: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  file:
    filename: "/traefik/dynamic_conf.yml"
  docker:
    exposedByDefault: false

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@zentrydev.com
      storage: acme.json
      httpChallenge:
        entryPoint: web
```

## `/traefik/dynamic_conf.yml`

```
http:
  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: true
```

## `/traefik/acme.json`

```
(Claude must create empty file and chmod 600)
```

---

# 5.6 DOCKER COMPOSE (FULL)

Claude must generate this file:

## `/docker-compose.yml`

```
version: '3.9'

services:

  traefik:
    image: traefik:v2.9
    container_name: traefik
    command:
      - "--api=true"
      - "--providers.docker=true"
      - "--providers.file.filename=/traefik/dynamic_conf.yml"
      - "--entryPoints.web.address=:80"
      - "--entryPoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik/traefik.yml:/traefik/traefik.yml
      - ./traefik/dynamic_conf.yml:/traefik/dynamic_conf.yml
      - ./traefik/acme.json:/acme.json
    networks:
      - kitchenos_net

  mysql:
    image: mysql:8
    container_name: kitchenos_mysql
    environment:
      MYSQL_ROOT_PASSWORD: strongpassword
      MYSQL_DATABASE: kitchenos
      MYSQL_USER: kitchenos_user
      MYSQL_PASSWORD: kitchenos_pass
    volumes:
      - ./mysql/data:/var/lib/mysql
    networks:
      - kitchenos_net

  redis:
    image: redis:7
    container_name: kitchenos_redis
    volumes:
      - ./redis/data:/data
    networks:
      - kitchenos_net

  kitchen-api:
    build:
      context: ./kitchen-api/src
    container_name: kitchen-api
    env_file:
      - ./kitchen-api/.env
    volumes:
      - ./kitchen-api/src:/var/www
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.kitchenapi.rule=Host(`kitchen.zentrydev.com`)"
      - "traefik.http.routers.kitchenapi.entrypoints=websecure"
      - "traefik.http.routers.kitchenapi.tls.certresolver=letsencrypt"
    networks:
      - kitchenos_net

  flexstock-api:
    build:
      context: ./flexstock-api/src
    container_name: flexstock-api
    env_file:
      - ./flexstock-api/.env
    volumes:
      - ./flexstock-api/src:/var/www
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.flexstock.rule=Host(`stock.zentrydev.com`)"
      - "traefik.http.routers.flexstock.entrypoints=websecure"
      - "traefik.http.routers.flexstock.tls.certresolver=letsencrypt"
    networks:
      - kitchenos_net

  worker-kitchen:
    container_name: worker-kitchen
    build:
      context: ./kitchen-api/src
    command: php artisan queue:work
    networks:
      - kitchenos_net

  worker-flexstock:
    container_name: worker-flexstock
    build:
      context: ./flexstock-api/src
    command: php artisan queue:work
    networks:
      - kitchenos_net

networks:
  kitchenos_net:
    driver: bridge
```

---

# 5.7 Base ENV Templates

### KitchenOS API → `/kitchen-api/.env`

```
APP_NAME=KitchenOS
APP_ENV=production
APP_KEY=
APP_URL=https://kitchen.zentrydev.com

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=kitchenos
DB_USERNAME=kitchenos_user
DB_PASSWORD=kitchenos_pass

REDIS_HOST=redis

CLOUDINARY_URL=cloudinary://xxx
OPENAI_API_KEY=xxx
```

### FlexStock API → `/flexstock-api/.env`

```
APP_NAME=FlexStock
APP_ENV=production
APP_KEY=
APP_URL=https://stock.zentrydev.com

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=kitchenos
DB_USERNAME=kitchenos_user
DB_PASSWORD=kitchenos_pass

REDIS_HOST=redis
```

---

# 5.8 Initialization Steps

Claude must run these steps automatically:

1. Create directories
2. Create Traefik config
3. Create docker-compose.yml
4. Create env files
5. Initialize empty Laravel projects
6. Build containers
7. Update log file → `latest_phase.txt = PHASE 1 COMPLETE`
8. Push to Git (initial infra commit)

---

# END OF PART 2
# 6. PHASE 2 — FLEXSTOCK API v2 (Laravel Multi-Tenant)

This section defines the complete blueprint for building FlexStock API v2 using Laravel 11 + PHP 8.2, with multi-tenant architecture matching KitchenOS.

**Claude Code must execute this after completing Phase 1.**

---

# 6.1 Overview (ภาพรวม FlexStock API)

FlexStock API v2 เป็น “Inventory Service” แบบ Multi-tenant ซึ่ง KitchenOS จะเรียกใช้เพื่อ:

* ดึงราคาวัตถุดิบล่าสุด
* จัดการวัตถุดิบ
* รับจำนวนสต็อก (batch-based)
* track consumption (ลด stock ตอนผลิตอาหาร)
* track purchase (เพิ่ม stock)
* ดูรายการสต็อกย้อนหลัง (ledger)

**FlexStock v2 = Single Source of Truth สำหรับวัตถุดิบ**

---

# 6.2 FlexStock API Responsibilities

## TH:

* เก็บข้อมูลวัตถุดิบของร้านแต่ละร้าน (tenant)
* มีราคาแบบ history (ย้อนหลัง)
* มี batch และ expiry
* ควบคุม stock ledger แบบระบบบัญชีคู่ (double-entry concept)
* API ใช้งานง่าย เชื่อมกับ KitchenOS โดยส่ง X-Tenant

## EN:

* Material master
* Material price history (time-series)
* Stock batch tracking
* Stock ledger with auditability
* Multi-tenant with strict scoping
* Exposed via clean REST APIs

---

# 6.3 Directory Structure

Claude must install Laravel project here:

```
/home/aunji/kitchenos-stack/flexstock-api/src/
```

Folders auto-managed by Laravel:

```
app/
bootstrap/
config/
routes/
database/
```

---

# 6.4 Multi-Tenant Implementation (Core Design)

## Header requirement:

Every request to FlexStock must include:

```
X-Tenant: {tenant_uuid}
```

## Tenant Resolver Flow:

1. Read `X-Tenant` header
2. Find tenant record in DB
3. Bind resolved tenant to `App\Tenant\TenantContext` (custom class)
4. Apply global scope to all Eloquent models:

   * Every query automatically applies:

     ```
     where tenant_id = {tenant}
     ```

## Claude must create:

* `app/Tenant/TenantResolver.php`
* `app/Tenant/TenantScope.php`
* `app/Http/Middleware/ResolveTenant.php`
* `register middleware in Kernel.php`

---

# 6.5 ENV Requirements

File: `/flexstock-api/.env`

Variables required:

```
DB_HOST=mysql
DB_DATABASE=kitchenos
DB_USERNAME=kitchenos_user
DB_PASSWORD=kitchenos_pass

REDIS_HOST=redis
APP_URL=https://stock.zentrydev.com
```

---

# 6.6 Database Schema (FULL)

### 1) tenants

(Shared with KitchenOS — will be in same DB)

```
id (uuid)
name
slug
status
created_at
updated_at
```

---

### 2) materials

```
id (uuid)
tenant_id (uuid)  <-- tenant scope
name
unit
sku
category_id
description (nullable)
is_active (default true)
created_at
updated_at
```

---

### 3) material_prices

```
id (uuid)
tenant_id
material_id
price (decimal 10,2)
effective_at (datetime)
created_at
```

Rules:

* Latest price = highest effective_at
* KitchenOS reads only latest price

---

### 4) stock_batches

```
id (uuid)
tenant_id
material_id
qty (decimal 10,3)
cost_per_unit (decimal 10,2)
expiry_date (nullable)
batch_code (string)
created_at
updated_at
```

---

### 5) stock_ledgers

```
id (uuid)
tenant_id
material_id
qty_change (decimal 10,3)
type (purchase, consume, adjust)
reference_id (nullable)
note
created_at
```

Rules:

* purchase → qty_change positive
* consume → qty_change negative
* adjust → positive or negative
* ledger always append-only

---

# 6.7 Model Definitions (Claude must create)

### `App\Models\Material`

* hasMany(MaterialPrice)
* hasMany(StockBatch)
* hasMany(StockLedger)

### `App\Models\MaterialPrice`

### `App\Models\StockBatch`

### `App\Models\StockLedger`

All must use:

```
use HasFactory;
use UuidTrait;  // Claude must create this
protected $fillable = [...];
```

---

# 6.8 Routes (API Spec)

## Base URL:

```
https://stock.zentrydev.com/api/v2/
```

---

### GET /materials

```
Response:
[
  {
    "id": "...",
    "name": "Pork Loin",
    "unit": "kg",
    "latest_price": 125.00,
    "updated_at": "..."
  }
]
```

### POST /materials

```
Payload:
{
  "name": "Chicken Breast",
  "unit": "kg",
  "sku": "CHK001"
}
```

---

### GET /materials/{id}

Returns full details including price history.

---

### GET /materials/{id}/latest-price

```
{
  "material_id": "...",
  "price": 125.00,
  "effective_at": "2025-01-29 10:20:00"
}
```

---

### POST /materials/{id}/price

Update price with historical tracking.

---

### POST /stock/purchase

```
{
  "material_id": "...",
  "qty": 12.5,
  "cost_per_unit": 98.00,
  "expiry_date": "2025-02-15"
}
```

Creates stock batch + ledger entry.

---

### POST /stock/consume

```
{
  "material_id": "...",
  "qty": 1.25,
  "reference_id": "recipe-uuid"
}
```

Consume stock in FIFO order.

---

### GET /stock/ledger

List all movements.

---

# 6.9 Services (Claude must create)

### `app/Services/MaterialService.php`

* createMaterial
* updateMaterial
* getLatestPrice
* setPrice
* listMaterials

### `app/Services/StockService.php`

* purchase()
* consume()
* getLedger()
* fifoConsumeLogic()

---

# 6.10 Middleware + Scopes

Claude must generate:

### `App\Http\Middleware\ResolveTenant.php`

* reads X-Tenant
* loads Tenant model → stores in TenantContext

### `App\Tenant\TenantScope.php`

* global scope that adds:

  ```
  where tenant_id = {currentTenant}
  ```

### `App\Tenant\TenantContext.php`

* static holder to store tenant id

---

# 6.11 Validation Rules (Laravel Form Requests)

Claude must create Form Requests:

* StoreMaterialRequest
* UpdateMaterialRequest
* PurchaseStockRequest
* ConsumeStockRequest

---

# 6.12 Controllers

Claude must create:

* MaterialController
* PriceController
* StockController
* LedgerController

with complete REST responses.

---

# 6.13 Unit Tests

Claude must generate:

```
tests/Feature/MaterialsTest.php
tests/Feature/StockTest.php
```

Tests required:

* create material
* set price
* get latest price
* purchase stock
* consume stock FIFO logic

---

# 6.14 Git Commit Rules for Phase 2

Claude must push:

```
git commit -m "Phase 2: Implemented FlexStock API v2 (multi-tenant inventory system)"
git push
```

And update progress file:

```
progress_logs/latest_phase.txt = "PHASE 2 COMPLETE"
```

---

# END OF PART 3
# 7. PHASE 3 — KITCHENOS API (Laravel Multi-Tenant Full Specification)

This section defines the full system specification for **KitchenOS API**, the core engine for all recipe, SOP, costing, staff, and kitchen workflow logic.

KitchenOS API communicates directly with:

* FlexStock API v2
* Kitchen Admin Web
* Kitchen PWA
* PDF Engine
* AI Engine (OpenAI)

Claude Code must execute this phase **after PHASE 2 is complete**.

---

# 7.1 Overview (ภาพรวมระบบ KitchenOS API)

## TH:

KitchenOS API เป็น “หัวใจหลัก” ของระบบร้านอาหาร:

* สูตร (Recipes)
* ขั้นตอน SOP
* ต้นทุนเมนู (Costing)
* การจัดการพนักงานครัว
* เวอร์ชันสูตร
* PDF Export
* การ sync กับ FlexStock เพื่อดึงราคา real-time

KitchenOS ใช้ Multi-Tenant เช่นเดียวกับ FlexStock:

```
X-Tenant: <tenant_uuid>
Authorization: Bearer <token>
```

## EN:

KitchenOS API is the operational core for the entire KitchenOS ecosystem.
It handles recipe authoring, production instruction, costing logic, staff workflow, and real-time integration with the FlexStock inventory engine.

---

# 7.2 Directory Structure

KitchenOS API Laravel project must be installed here:

```
/home/aunji/kitchenos-stack/kitchen-api/src/
```

Folders auto-managed by Laravel:

```
app/
bootstrap/
config/
routes/
database/
```

---

# 7.3 Core Modules

KitchenOS API must contain the following modules:

| Module                   | Description                                                      |
| ------------------------ | ---------------------------------------------------------------- |
| **Recipes**              | Recipe main data, metadata, categories, tags, portion, packaging |
| **Recipe Ingredients**   | Mapping to FlexStock materials                                   |
| **Recipe Steps / SOP**   | Step-by-step instructions with media                             |
| **Costing Engine**       | Calculates cost by pulling latest prices from FlexStock          |
| **Recipe Versioning**    | v1/v2/v3 recipe updates with audit                               |
| **Staff Tasks & KPI**    | Checklist, attendance, photo confirmation                        |
| **PDF Export Trigger**   | Creates PDF export job                                           |
| **AI Integration Hooks** | Generate SOP, optimize cost, auto-structure recipe               |

---

# 7.4 Database Schema (FULL)

All tables require:

```
tenant_id (uuid)
created_by (nullable)
updated_by (nullable)
timestamps
uuid primary key
```

Tables:

---

## 1) recipes

```
id (uuid)
tenant_id
title
slug
description
cover_image_url
category_id
serving_size (decimal)
packaging (string nullable)
version (integer default 1)
status (draft/published/archived)
created_by
updated_by
created_at
updated_at
```

---

## 2) recipe_ingredients

```
id (uuid)
tenant_id
recipe_id
material_id (uuid from FlexStock)
qty (decimal 10,3)
unit
note (nullable)
created_at
updated_at
```

---

## 3) recipe_steps

```
id (uuid)
tenant_id
recipe_id
step_number (int)
instruction (text)
image_url (nullable)
video_url (nullable)
timer_seconds (nullable)
tools (json nullable)
ingredients_used (json nullable)
created_at
updated_at
```

---

## 4) recipe_versions

```
id (uuid)
tenant_id
recipe_id
version_number
changelog (text)
data_snapshot (json)
created_at
```

---

## 5) staff_tasks

```
id (uuid)
tenant_id
user_id
task_type (prep/cleaning/checklist/general)
status (pending, done)
checklist_items (json)
photos (json)
completed_at
created_at
updated_at
```

---

## 6) staff_attendance

```
id (uuid)
tenant_id
user_id
clock_in_at
clock_out_at (nullable)
photos (json)
notes
created_at
updated_at
```

---

## 7) pdf_jobs

```
id (uuid)
tenant_id
recipe_id
status (queued/processing/finished/failed)
output_url
created_at
updated_at
```

---

# 7.5 Multi-Tenant Setup

KitchenOS uses the same Multi-Tenant stack as FlexStock:

Claude must create in KitchenOS:

### Middleware:

`App\Http\Middleware\ResolveTenant`

### Tenant Context:

`App\Tenant\TenantContext`

### Tenant Scope:

`App\Tenant\TenantScope`

### Register:

Add middleware to `Kernel.php`:

```
'tenant' => \App\Http\Middleware\ResolveTenant::class,
```

### Apply globally using base Model:

```
protected static function booted() {
    static::addGlobalScope(new TenantScope);
}
```

---

# 7.6 API ROUTES (Full Spec)

Base URL:

```
https://kitchen.zentrydev.com/api/v1/
```

All routes require:

```
Authorization: Bearer <token>
X-Tenant: <tenant_id>
```

---

## RECIPES MODULE

### GET /recipes

List of all recipes under tenant.

### POST /recipes

Payload:

```
{
  "title": "Beef Fried Rice",
  "description": "...",
  "serving_size": 1,
  "category_id": "...",
  "packaging": "bowl"
}
```

### GET /recipes/{id}

Returns:

* recipe data
* ingredients
* steps
* computed costing

### PUT /recipes/{id}

Update recipe main info.

### DELETE /recipes/{id}

Soft delete recipe.

---

## RECIPE INGREDIENTS

### POST /recipes/{id}/ingredients

```
{
  "material_id": "...",
  "qty": 0.125,
  "unit": "kg"
}
```

### DELETE /recipes/{id}/ingredients/{ingredient_id}

---

## RECIPE STEPS (SOP)

### POST /recipes/{id}/steps

```
{
  "step_number": 1,
  "instruction": "Heat pan with oil",
  "image_url": "...",
  "timer_seconds": 30
}
```

### PUT /recipes/{id}/steps/reorder

```
{
  "order": [ "step_uuid_1", "step_uuid_2", ... ]
}
```

---

## COSTING ENGINE API

### GET /recipes/{id}/costing

Claude must compute:

* For each ingredient:

  ```
  qty × latest_price (from FlexStock API)
  ```
* Total cost
* Cost per serving
* Packaging cost (optional)
* Suggested selling price (multipliers)

---

## STAFF TASKS

### POST /tasks

```
{
  "task_type": "cleaning",
  "checklist_items": [...],
  "photos": []
}
```

### GET /tasks/today

---

## ATTENDANCE

### POST /attendance/clock-in

### POST /attendance/clock-out

---

## PDF EXPORT

### POST /recipes/{id}/pdf

Triggers queue job.

---

# 7.7 Services (Claude must create)

Services required:

## RecipeService

* createRecipe
* updateRecipe
* getRecipeFullData
* computeCosting (connect FlexStock API)
* publishRecipe
* archiveRecipe

## StepService

* addStep
* reorderSteps

## IngredientService

* addIngredient
* removeIngredient

## CostingService

* fetchLatestPrice(material_id)
* computeRecipeCost(recipe_id)

## StaffService

* createTask
* completeTask
* getTodayTasks

## PdfService

* queuePdfJob
* storeOutputUrl

---

# 7.8 Integration with FlexStock API

When computing costing:

```
GET https://stock.zentrydev.com/api/v2/materials/{id}/latest-price
```

Headers:

```
X-Tenant: {tenant}
Authorization: Bearer <token>
```

If FlexStock unreachable → fallback cached price.

---

# 7.9 Validation (Form Requests)

Claude must create:

* StoreRecipeRequest
* UpdateRecipeRequest
* StoreStepRequest
* StoreIngredientRequest
* CostingRequest
* StaffTaskRequest

---

# 7.10 Controllers (Full List)

Claude must generate:

* RecipeController
* StepController
* IngredientController
* CostingController
* StaffController
* AttendanceController
* PdfController

All return JSON:

```
success: true  
data: ...
```

---

# 7.11 PDF Job Flow

1. Kitchen Admin triggers PDF export
2. Controller creates pdf_jobs entry
3. Dispatch job
4. Worker renders PDF (Phase 6)
5. Upload to Cloudinary (or S3 future)
6. Update pdf_jobs output_url
7. Response snapshot to Admin Web

---

# 7.12 Notifications (Optional Future)

* Email on recipe publish
* Slack webhook for cost spike detection
* LINE Notify for staff incomplete tasks

---

# 7.13 Git Commit Rules for Phase 3

Claude must push:

```
git commit -m "Phase 3: Implemented KitchenOS API (multi-tenant system)"
git push
```

Update progress:

```
progress_logs/latest_phase.txt = "PHASE 3 COMPLETE"
```

---

# END OF PART 4
# 8. PHASE 4 — KITCHEN ADMIN WEB (Next.js 14, App Router, Full Spec)

This section defines the Admin Web Panel of KitchenOS — the interface restaurant owners & staff use to manage recipes, SOPs, costing, users, tasks, and PDF exports.

Claude Code must generate a complete Next.js 14 project with TailwindCSS, React Query, Auth, API client, and reusable UI components.

After PHASE 3 completes, Claude must begin this PHASE automatically.

---

# 8.1 Overview (ภาพรวมระบบ Admin Web)

## TH:

Kitchen Admin Web เป็นเครื่องมือบริหารหลังบ้าน ใช้จัดการข้อมูลทั้งหมด:

* สูตรอาหาร (Recipes CRUD)
* ขั้นตอน SOP (Step Builder)
* วัตถุดิบในสูตร (เชื่อม FlexStock)
* คำนวณต้นทุน (Costing Dashboard)
* การจัดการพนักงาน (Staff)
* การสร้าง PDF ของสูตร
* ระบบจัดการผู้ใช้ (User Management)
* การตั้งค่าร้าน (Tenant Settings)

## EN:

The Admin Web is the central management console for KitchenOS.
It is built with Next.js 14, App Router, Server Components, TailwindCSS, React Query, and communicates with KitchenOS API + FlexStock API.

---

# 8.2 Directory Structure (Next.js Project)

Claude must create project at:

```
/home/aunji/kitchenos-stack/kitchen-admin/
```

Directory:

```
kitchen-admin/
  ├── app/
  │   ├── (auth)/
  │   ├── dashboard/
  │   ├── recipes/
  │   ├── staff/
  │   ├── settings/
  │   ├── layout.tsx
  │   └── page.tsx
  ├── components/
  ├── lib/
  ├── hooks/
  ├── services/
  ├── public/
  ├── tailwind.config.js
  ├── package.json
  ├── next.config.js
  ├── .env.local
  └── README.md
```

---

# 8.3 Tech Stack

* **Next.js 14 (App Router)**
* **React 18**
* **TailwindCSS**
* **Prisma (only if needed local cache)** → optional
* **React Query**
* **Lucide Icons**
* **Shadcn UI**
* **NextAuth (JWT-based)**

Admin Web interacts only with APIs — no DB.

---

# 8.4 ENV File:

`/kitchen-admin/.env.local`

```
NEXT_PUBLIC_KITCHEN_API_URL=https://kitchen.zentrydev.com/api/v1
NEXT_PUBLIC_FLEXSTOCK_API_URL=https://stock.zentrydev.com/api/v2
NEXT_PUBLIC_CLOUDINARY_PRESET=trade_logger_unsigned
NEXT_PUBLIC_CLOUDINARY_FOLDER=recipes/
```

---

# 8.5 Authentication Module

Claude must implement **NextAuth Credentials Provider**:

* User enters email + password
* Admin Web sends request to:

```
POST https://kitchen.zentrydev.com/api/v1/auth/login
```

Response includes:

```
token
user
tenant
permissions
```

Store token in session:

```
session.user.token
session.user.tenant_id
```

Add to headers on every request:

```
Authorization: Bearer <token>
X-Tenant: <tenant_id>
```

---

# 8.6 Pages (Full List)

## ROOT:

* `/dashboard`
* `/recipes`
* `/recipes/[id]`
* `/recipes/[id]/steps`
* `/recipes/[id]/ingredients`
* `/recipes/[id]/costing`
* `/recipes/[id]/pdf`
* `/staff`
* `/staff/tasks`
* `/settings`
* `/auth/login`

---

# 8.7 UI Modules (Claude must build)

## 1) Dashboard

Metrics:

* Recipes count
* Staff tasks today
* Recent updates
* Costing summary
* Alerts (from FlexStock)

---

## 2) Recipes List Page

Columns:

* Title
* Category
* Version
* Status
* Actions

Features:

* Search
* Filter
* Pagination
* Create button

---

## 3) Recipe Editor (CRUD)

Fields:

* Title
* Description
* Category
* Serving size
* Packaging
* Cover Image Upload

Actions:

* Save
* Publish
* View PDF
* Go to Steps
* Go to Ingredients
* Go to Costing

---

## 4) Step Builder (SOP Builder)

Features:

* Add step
* Drag & Drop reorder
* Upload Image
* Add Timer
* Add notes
* Add tool list

Claude must implement Drag&Drop using:

```
@dnd-kit/core
```

or

```
react-beautiful-dnd
```

---

## 5) Ingredients Mapping UI

### Fetch materials from FlexStock:

```
GET /materials?search=...
```

UI:

* Material selector
* Qty input
* Unit input
* Cost preview (pull latest price)
* Add/remove ingredient

---

## 6) Costing Dashboard

Claude must compute:

* Total ingredient cost
* Cost per serving
* Packaging cost
* Total food cost
* Suggested selling price
* Real-time refresh when FlexStock price changes

UI widgets:

* Pie chart (ingredient cost breakdown)
* Table (ingredient → cost)

---

## 7) PDF Generator Page

Button:

```
GENERATE PDF
```

Calls:

```
POST /recipes/{id}/pdf
```

Status Polling:

```
GET /pdf_jobs/{job_id}
```

Then show:

* PDF embed viewer
* Copy link
* Download button

---

## 8) Staff Management

### Staff list:

* Name
* Role
* Attendance today
* Tasks pending / done

### Task List:

* task_type
* status
* completed_at
* photos (thumbnail)

---

## 9) Tenant Settings

* Tenant name
* Logo upload
* User management
* API tokens
* PDF layout customization
* Allowed devices (future feature)

---

# 8.8 Components (Claude must build)

### UI Components:

* `<Card />`
* `<Button />`
* `<Input />`
* `<Select />`
* `<Alert />`
* `<Badge />`
* `<Tabs />`
* `<DataTable />`
* `<Modal />`
* `<Uploader />` (Cloudinary)
* `<LoadingSpinner />`
* `<PriceTag />`
* `<RecipeCostSummary />`

### Utility Components:

* `<AuthGuard />`
* `<TenantGuard />`
* `<ApiClient />`
* `<Pagination />`

---

# 8.9 Hooks

Claude must implement hooks:

```
useApi()
useAuth()
useRecipes()
useIngredients()
useSteps()
useCosting()
useStaff()
usePDF()
```

---

# 8.10 Services (API Clients)

`/services/api.ts`

* prepare axios instance with:

```
Authorization + X-Tenant headers
```

Services:

* recipeService
* stepService
* ingredientService
* costingService
* pdfService
* staffService

---

# 8.11 State Management

Use React Query:

* Automatic caching
* Auto-refetch
* SWR-like consistency

---

# 8.12 Styling

Tailwind + Shadcn UI MUST be installed.

---

# 8.13 Git Commit Requirements (Phase 4)

Claude must push:

```
git commit -m "Phase 4: Implemented Kitchen Admin Web (Next.js dashboard)"
git push
```

Update progress:

```
progress_logs/latest_phase.txt = "PHASE 4 COMPLETE"
```

---

# END OF PART 5
# 9. PHASE 5 — KITCHEN PWA (Next.js PWA Full Specification)

The Kitchen PWA is the interface used by chefs, staff, and line cooks inside the kitchen.
It must be extremely fast, offline-ready, simple, robust, and optimized for real kitchen workflows.

Claude Code must begin this phase **after PHASE 4 completes**.

---

# 9.1 Overview (ภาพรวม Kitchen PWA)

## TH:

Kitchen PWA คือระบบที่พนักงานครัวใช้ในชีวิตจริง:

* ดูสูตรเร็วที่สุด
* SOP แบบขั้นตอน (Step-by-Step)
* โหลดได้แม้อินเทอร์เน็ตช้า
* ใช้งานแบบ Offline ได้
* ดึงข้อมูลล่าสุดเมื่อกลับมาออนไลน์
* รองรับ Tablet / มือถือ ทั้ง iOS/Android
* UX เหมาะกับครัว (ปุ่มใหญ่, ตัวอักษรชัด)

## EN:

Kitchen PWA is a high-performance offline-first web app designed for kitchen operations.
It must load instantly, work offline, and support rapid recipe browsing, step-by-step flows, and cached data.

---

# 9.2 Directory Structure

Claude must create project at:

```
/home/aunji/kitchenos-stack/kitchen-pwa/
```

Folders:

```
kitchen-pwa/
  ├── app/
  │   ├── recipes/
  │   ├── recipes/[id]/
  │   ├── offline/
  │   ├── sync/
  │   ├── layout.tsx
  │   └── page.tsx
  ├── components/
  ├── hooks/
  ├── lib/
  ├── public/
  │   ├── manifest.json
  │   └── icons/
  ├── service-worker.js
  ├── next.config.js
  ├── tailwind.config.js
  ├── package.json
  ├── .env.local
  └── README.md
```

---

# 9.3 Tech Stack

* **Next.js 14 (App Router)**
* **React 18**
* **PWA support**:

  * Service Worker
  * Manifest.json
  * Cache-first strategy
* **IndexedDB** (local offline DB)
* **React Query**
* **TailwindCSS**
* **Shadcn UI**
* **Axios client**
* **LocalStorage + IDB for offline recipe caching**

---

# 9.4 ENV File:

`/kitchen-pwa/.env.local`

```
NEXT_PUBLIC_KITCHEN_API_URL=https://kitchen.zentrydev.com/api/v1
NEXT_PUBLIC_CLOUDINARY_DELIVERY=https://res.cloudinary.com/
```

---

# 9.5 CORE USER FLOW

1. Staff opens PWA → auto-login token cached
2. Fetches recipe list → stores to IndexedDB
3. User taps recipe → loads SOP steps
4. If offline → load from local DB
5. Swipe navigation between steps
6. Mark step as “Done”
7. If back online → sync completion logs
8. If network fails → PWA continues in offline mode

---

# 9.6 Offline-First Architecture

Claude must implement:

### Service worker with:

* Cache shell assets
* Cache recipe images
* Cache recipe JSON data
* Background sync registration

### IndexedDB store:

```
stores:
  - recipes
  - steps
  - ingredients
  - images metadata
```

### Sync queue:

When offline:

* Step completions queued
* Task logs queued
* Auto-sync when online

---

# 9.7 Pages (Full)

## `/` (Home)

* Search bar
* Categories
* Recent recipes
* Offline indicator (`Online / Offline`)

---

## `/recipes`

* List of recipes
* Simple card layout
* If offline → load IDB only

---

## `/recipes/[id]`

Show:

* Title
* Cover image
* Serving size
* Costing summary (if online)
* “Start SOP” button

---

## `/recipes/[id]/steps`

**Step-by-Step SOP interface**

Features:

* Fullscreen
* Swipe left/right
* Progress bar
* Timer per step
* Tools list
* Ingredients for that step
* Zoom images
* Next step auto-focus
* Auto-speak instructions (Text-to-Speech)

UI style:

* Large buttons
* Touch optimized
* Edge-to-edge content
* Dark mode for kitchen environment

---

## `/offline`

* Shows offline instructions
* Button “Download All Recipes”
* Button “Sync Data Now”

---

## `/sync`

* History of sync events
* success / failed logs
* retry sync button

---

# 9.8 Components (Claude must implement)

### `<RecipeCard />`

* offline badge if cached
* updated badge if downloaded

### `<StepViewer />`

* shows current step
* images
* timer
* swipe events
* voice playback (optional)

### `<OfflineBanner />`

* shows network status

### `<SyncStatus />`

* shows sync queue count

### `<FloatingNextButton />`

* quick next-step CTA

### `<LargeButton />`

* kitchen-grade buttons

---

# 9.9 Hooks

### `useOfflineStatus()`

Detect network connectivity.

### `useRecipeData()`

Sync with API + IDB.

### `useStepNavigation()`

Manages swipe controls.

### `useSyncQueue()`

Handles offline → online sync.

---

# 9.10 IndexedDB Setup (Mandatory)

Claude must create:

`/lib/db.ts`

* initialize IDB database
* create object stores
* helper methods:

  * saveRecipe
  * getRecipe
  * saveSteps
  * getSteps
  * queueTask
  * dequeueTasks

---

# 9.11 Service Worker (Mandatory)

Claude must create:

`/service-worker.js`

Features:

* Install → cache app shell
* Fetch → stale-while-revalidate
* Background sync:

  ```
  sync event → send queued tasks
  ```
* Image cache strategy:

  * Cache-first → fallback to network
* Offline fallback page → `/offline`

---

# 9.12 Styling & UX Notes

* Kitchen UI must be extremely readable:

  * 18–22px base font
  * Bold headings
  * High contrast colors
  * Avoid small buttons

* Use Tailwind utility classes

* Transition duration 150ms

* Card layout → bigger hit-box for touchscreen users

---

# 9.13 API Consumption Rules

All API calls must include:

Headers:

```
Authorization: Bearer <token>
X-Tenant: <tenant_id>
```

Data flows:

* GET → update IDB cache
* POST/PUT → offline queue if network error
* Polling for recipe updates optional

---

# 9.14 Performance Requirements

* First load ≤ 1.5s
* Step change ≤ 200ms
* Offline load 100% instant
* Cache size limit < 50MB
* Support at least 500 recipes offline

---

# 9.15 Git Commit Rules (Phase 5)

Claude must push:

```
git commit -m "Phase 5: Implemented Kitchen PWA (offline-first Next.js PWA)"
git push
```

Update progress:

```
progress_logs/latest_phase.txt = "PHASE 5 COMPLETE"
```

---

# END OF PART 6
# 10. PHASE 6 — PDF ENGINE (Microservice) Full Specification

The PDF Engine is a dedicated microservice responsible for generating recipe PDFs for KitchenOS.
It must be lightweight, fast, stable, and produce beautiful print-ready documents.

Claude Code must execute this phase after PHASE 5 completes.

---

# 10.1 Overview (ภาพรวมระบบ PDF Engine)

## TH:

PDF Engine เป็นระบบสร้างไฟล์ PDF สำหรับ:

* สูตรอาหาร (Recipe PDF)
* SOP พร้อมภาพประกอบ
* สรุปต้นทุน
* Ingredient list
* Packaging & versioning

การ generate ทำผ่าน queue เพื่อความเสถียร และอัปโหลดขึ้น Cloudinary อัตโนมัติ

## EN:

The PDF Engine generates:

* Recipe documents
* Costing sheets
* SOP documents
* Printable summary layouts

All jobs run through queues and outputs stored on Cloudinary.

---

# 10.2 Technology Stack

This microservice is intentionally simple:

* **Node.js 20**
* **Puppeteer** (Headless Chrome rendering)
* **Express.js** (API wrapper)
* **BullMQ** (Redis-based queue)
* **TailwindCSS-based HTML templates**
* **Cloudinary Upload API**

Container deployed inside:

```
/home/aunji/kitchenos-stack/pdf-engine/
```

---

# 10.3 Directory Structure

```
pdf-engine/
  ├── src/
  │   ├── server.ts
  │   ├── queue.ts
  │   ├── workers/
  │   │     └── pdfWorker.ts
  │   ├── templates/
  │   │     ├── recipe.html
  │   │     ├── costing.html
  │   │     └── sop.html
  │   ├── utils/
  │   │     ├── cloudinary.ts
  │   │     └── puppeteer.ts
  │   ├── types/
  ├── Dockerfile
  ├── package.json
  ├── tsconfig.json
  ├── .env
  └── README.md
```

---

# 10.4 ENV File

`/pdf-engine/.env`

```
PORT=4000
REDIS_HOST=redis
CLOUDINARY_URL=cloudinary://xxx
KITCHEN_API_URL=https://kitchen.zentrydev.com/api/v1
JWT_SECRET=xxxx
```

---

# 10.5 API Endpoints (Microservice)

## POST /generate

### Request:

```
{
  "recipe_id": "uuid",
  "tenant_id": "uuid",
  "type": "recipe" | "costing" | "sop"
}
```

### Response:

```
{
  "job_id": "123123123"
}
```

---

## GET /status/{job_id}

Returns current job status:

```
{
  "status": "queued" | "processing" | "completed" | "failed",
  "url": "https://res.cloudinary.com/.../recipe.pdf"
}
```

---

# 10.6 Queue Worker Logic

Worker receives job → fetches recipe data → renders HTML → converts to PDF → uploads to Cloudinary.

### Steps:

1. Load recipe data via API:

   ```
   GET https://kitchen.zentrydev.com/api/v1/recipes/{id}
   ```

   with:

   ```
   Authorization: Bearer <token>
   X-Tenant: <tenant>
   ```

2. Load template based on type:

   * recipe.html
   * costing.html
   * sop.html

3. Render HTML with injected data

4. Use Puppeteer:

   ```
   await page.pdf({
      format: "A4",
      printBackground: true,
      margin: { top: "20px", bottom: "20px" }
   })
   ```

5. Upload result to Cloudinary folder:

   ```
   folder: "kitchenos-pdfs/"
   ```

6. Return Cloudinary URL

7. Update KitchenOS API:

   ```
   PATCH /pdf_jobs/{id}
   {
      "status": "finished",
      "output_url": "<cloudinary_url>"
   }
   ```

---

# 10.7 HTML Template Requirements

### recipe.html must include:

* Title
* Cover image
* Description
* Serving size
* Ingredient list (with qty & unit)
* Costing summary
* Steps (SOP) with images
* Footer with version & timestamp
* QR code linking to online viewer (optional)

### costing.html:

* Total cost
* Ingredient breakdown
* Packaging cost
* Suggestions for selling price
* “Cost vs Price” chart (simple style)

### sop.html:

* Step-by-step layout
* Large text
* Full-width images
* Clear numbering
* Timer indicators
* Icon indicators for tools

---

# 10.8 Puppeteer Requirements

Claude must include configuration:

* `--no-sandbox`
* `--disable-setuid-sandbox`
* `--disable-dev-shm-usage`

Important for Linux + Docker environment.

---

# 10.9 Dockerfile (Must build headless Chrome)

Claude must create:

```
FROM ghcr.io/puppeteer/puppeteer:20.7.0

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

CMD ["npm", "run", "start"]
```

---

# 10.10 Next.js Admin Integration

Admin Web calls:

```
POST /recipes/{id}/pdf
```

KitchenOS API → sends background job to PDF Engine
Admin UI polls:

```
GET /pdf_jobs/{id}
```

When ready:

* Show PDF viewer
* Show copyable URL
* Show “Download PDF” button

---

# 10.11 Cloudinary Requirements

Folder:

```
kitchenos-pdfs/
```

Upload using:

```
cloudinary.uploader.upload_stream(
   { folder: "kitchenos-pdfs", resource_type: "raw" }
)
```

Output must be `.pdf`

---

# 10.12 Git Commit Rules (Phase 6)

Claude must push:

```
git commit -m "Phase 6: Implemented PDF Engine microservice (Node + Puppeteer)"
git push
```

Update progress:

```
progress_logs/latest_phase.txt = "PHASE 6 COMPLETE"
```

---

# END OF PART 7

# 11. PHASE 7 — AI INTEGRATION (OpenAI + Future Multi-Agents)

This section defines the artificial intelligence layer for KitchenOS.
AI features must work across Admin Web, Kitchen PWA, KitchenOS API, and FlexStock.

Claude Code executes PHASE 7 after the PDF Engine is completed.

---

# 11.1 AI Overview (ภาพรวมระบบ AI)

## TH:

AI ใน KitchenOS ต้องช่วยเหลือธุรกิจร้านอาหารแบบ “จริง” ไม่ใช่แค่ Chatbot
ต้องมีความสามารถด้าน:

* สร้าง SOP อัตโนมัติ
* วิเคราะห์สูตร → ลดต้นทุน
* แนะนำวัตถุดิบที่ถูกกว่า
* วิเคราะห์การใช้วัตถุดิบใน FlexStock
* สรุปเมนูต้นทุนสูงผิดปกติ
* ปรับปรุงสูตรให้เสถียร (Standardization)
* วิเคราะห์ workflow ของพนักงาน
* ช่วยสร้าง PDF และเขียนข้อความอธิบายรูปภาพ
* สร้างสูตรใหม่ตามโจทย์ของร้าน

## EN:

AI must be deeply integrated into KitchenOS:

* SOP generator
* Cost optimizer
* Ingredient substitution engine
* Menu engineering analysis
* Staff task intelligence
* PDF explanation text
* New recipe generator

AI is not a separate module — it is woven into every major feature.

---

# 11.2 AI Architecture

AI layer consists of:

1. **AI Microservice (Laravel-based inside KitchenOS API)**
2. **AI Client (Next.js Admin & PWA)**
3. **AI Workflow Manager**
4. **Vector memory (optional future)**
5. **OpenAI GPT-4.1 / GPT-4o / GPT-4.1-mini** as main models

---

# 11.3 API Endpoints (KitchenOS API → AI)

### POST /ai/sop-generator

```
{
  "title": "Stir Fried Chicken with Basil",
  "ingredients": [
     { "name": "Chicken", "qty": 0.25, "unit": "kg" },
     { "name": "Basil", "qty": 20, "unit": "g" }
  ],
  "serving_size": 1
}
```

Response:

```
{
  "steps": [
    {
       "step_number": 1,
       "instruction": "Heat oil on medium heat...",
       "estimated_time": 30,
       "tools": ["pan", "spatula"]
    },
    ...
  ]
}
```

---

### POST /ai/cost-optimizer

```
{
  "recipe_id": "uuid",
  "cost_items": [
     { "material_id": "...", "price": 125, "qty": 0.25 }
  ]
}
```

Output:

```
{
  "suggestions": [
    {
      "material_id": "...",
      "alternative_material": "...",
      "potential_saving": 22.5
    }
  ]
}
```

---

### POST /ai/recipe-generator

```
{
  "prompt": "Generate a Thai-style spicy chicken salad recipe."
}
```

Returns a fully structured recipe.

---

### POST /ai/pdf-description

Auto-generate text descriptions for PDF layout based on recipe content.

---

### POST /ai/ingredient-mapper

Input: ingredient text
Output: FlexStock material match

---

# 11.4 AI Models

Claude must integrate:

### Primary:

```
gpt-4.1 (text)
gpt-4.1-mini (cheap tasks)
```

### Optional:

```
gpt-4.1 vision (for future OCR image → instructions)
```

---

# 11.5 AI Services (Claude must create inside Laravel)

### `App\Services\AI\SOPGeneratorService.php`

Functions:

* analyzeRecipeData()
* generateSteps()
* estimateTimers()
* recommendTools()

### `App\Services\AI\CostOptimizerService.php`

* analyzeIngredientCost()
* crossCheckFlexStock()
* suggestAlternatives()
* provideMenuEngineeringInsights()

### `App\Services\AI\RecipeGeneratorService.php`

* generateStructuredRecipe()
* buildIngredients()
* suggestPlating()

### `App\Services\AI\PdfDescriptionService.php`

* writeIntroSummary()
* writeIngredientDescription()
* writeStepOverview()

---

# 11.6 AI Request Manager

Claude must implement:

`App\Services\AI\AIClient.php`

Include:

* model selection logic
* retry handling
* response trimming
* JSON validation
* cost logging (token usage)

---

# 11.7 AI Error Handling

If OpenAI API fails:

* fallback to previous cached suggestion
* return gracefully:

```
{ "success": false, "error": "AI service unavailable" }
```

Log each error:

```
storage/logs/ai_errors.log
```

---

# 11.8 AI Features inside Admin Web

### In /recipes/[id]/steps

Button:

```
Generate SOP using AI
```

### In /recipes/[id]/ingredients

Button:

```
Suggest alternative ingredients
```

### In recipe creation page:

```
Generate Recipe with AI
```

### In costing dashboard:

```
AI Cost Optimization
```

### In PDF page:

```
AI Describe PDF Section
```

---

# 11.9 AI Features inside Kitchen PWA

* Auto-summarized steps for quicker reading
* Voice instructions (optional)
* Step explanations simplified
* “Explain this step” button
* “What can go wrong?” AI assistant

---

# 11.10 Token & Cost Controls

Claude must implement:

* config `ai.max_tokens_per_day`
* rate limit per tenant
* daily usage logs:

  ```
  storage/logs/ai_usage_YYYYMMDD.log
  ```

Future:

* plan to offer subscription plans with token caps

---

# 11.11 Security (Important)

All AI routes require:

* Auth token
* Tenant header
* Permission: `ai.use`

Requests sent to OpenAI must never include:

* sensitive user data
* passwords
* tokens
* internal server paths

---

# 11.12 Git Commit Rules (Phase 7)

Claude must push:

```
git commit -m "Phase 7: Added AI integration (SOP generator, cost optimizer, recipe generator)"
git push
```

Update progress:

```
progress_logs/latest_phase.txt = "PHASE 7 COMPLETE"
```

---

# END OF PART 8
# 12. PHASE 8 — LOGGING, MONITORING & ERROR HANDLING (Production Grade)

This phase defines the full observability stack for KitchenOS.
Includes logs, metrics, monitoring, error reporting, and system health checks.

Claude Code must execute PHASE 8 after AI Integration (PHASE 7).

---

# 12.1 Overview (ภาพรวมของระบบ Observability)

## TH:

ระบบนี้จะทำให้ KitchenOS รู้ทุกอย่างที่เกิดขึ้นในระบบ:

* ใครเรียก API
* เวลาในการตอบสนอง
* Error ไหนเกิดบ่อย
* PDF Engine ล่มหรือไม่
* Worker หน่วงหรือไม่
* FlexStock ตอบช้าไหม
* AI ใช้ token เท่าไหร่
* Server ทำงานหนักเกินไปหรือไม่

## EN:

This phase establishes full observability:

* API logs
* AI usage logs
* Redis/Queue health
* MySQL monitoring
* Request traces
* Error reporting
* Worker performance tracking

This is required for real SaaS at scale.

---

# 12.2 Logging Architecture

KitchenOS uses 3 categories of logs:

1. **Application Logs (Laravel)**
2. **Request Logs (API Gateway / Laravel Middleware)**
3. **AI Logs (Token usage, failures)**

Folder structure:

```
storage/logs/
  laravel.log
  api_requests.log
  ai_usage.log
  ai_errors.log
  queue_worker.log
```

---

# 12.3 API Request Logging (Middleware)

Claude must create:

### `/app/Http/Middleware/LogApiRequest.php`

Logs:

* request path
* tenant_id
* user_id
* execution time
* status code
* error (if any)

Format:

```
[2025-01-21 10:32:22] tenant=XXX user=YYY path=/recipes/123 method=GET status=200 duration=142ms
```

Save to:

```
storage/logs/api_requests.log
```

Register middleware in:

```
Kernel.php → api group
```

---

# 12.4 Error Handling (Global Laravel Handler)

Modify:

```
app/Exceptions/Handler.php
```

Claude must add:

* graceful JSON responses
* tenant-aware logging
* API-safe error messages
* unexpected exception logging

Response format:

```
{
  "success": false,
  "error": "Internal server error",
  "trace_id": "uuid"
}
```

Store trace logs to:

```
storage/logs/error_traces/
```

---

# 12.5 Queue & Worker Monitoring

Worker logs:

```
storage/logs/queue_worker.log
```

Claude must implement:

* record job start
* record job finish
* record job retry
* detect job stuck / long-running

Cron to check worker health every 5 minutes.

---

# 12.6 Health Check Endpoints

Claude must implement:

### GET /health

Returns:

```
{
  "status": "ok",
  "mysql": true,
  "redis": true,
  "queue": true,
  "version": "1.0.0"
}
```

### GET /health/workers

Check:

* worker-kitchen
* worker-flexstock
* PDF worker (BullMQ)

---

# 12.7 Rate Limiting

Add Laravel Rate Limit rules:

```
300 requests/minute per tenant
30 requests/minute per user
```

Add to:

```
app/Providers/RouteServiceProvider.php
```

---

# 12.8 Monitoring Dashboard (External Tools)

**Optional but recommended**

Use:

* UptimeRobot (free) → uptime check
* Cloudflare Analytics (free) → traffic insights
* Logtail / BetterStack (free tier) → central log viewer
* Grafana (self-host optional) → MySQL/Redis metrics
* Sentry (free tier) → error reporting

---

# 12.9 Notification Alerts

### Telegram / LINE Notify Webhook

Claude must implement a simple config to alert on:

* Queue failure
* PDF job failure
* AI API outage
* MySQL disconnect
* Redis timeout

Simple POST to LINE Notify:

```
message = "[ALERT] PDF Engine is down"
```

---

# 12.10 AI Usage Logging

All AI usage must log to:

```
storage/logs/ai_usage_YYYYMMDD.log
```

Format:

```
2025-01-21 11:50 tenant=xxx model=gpt-4.1 tokens=523 feature=cost-optimizer
```

---

# 12.11 FlexStock Monitoring Hooks

KitchenOS should detect:

* slow response from FlexStock API
* missing price
* price spikes > 15%

Logs:

```
storage/logs/flexstock_warnings.log
```

---

# 12.12 Logging for PDF Engine (Node microservice)

Inside `/pdf-engine/` Claude must log:

* job received
* job start
* job finish
* PDF size
* Cloudinary URL
* errors

File:

```
logs/pdf_engine.log
```

---

# 12.13 Git Commit Rules (Phase 8)

Claude must push:

```
git commit -m "Phase 8: Added logging, monitoring, error handling, health checks"
git push
```

And update:

```
progress_logs/latest_phase.txt = "PHASE 8 COMPLETE"
```

---

# END OF PART 9
# 13. PHASE 9 — CI/CD PIPELINE (GitHub Actions + Docker + Production Deploy)

This section defines the complete CI/CD pipeline for KitchenOS:

* FlexStock API
* KitchenOS API
* Kitchen Admin Web
* Kitchen PWA
* PDF Engine
* Docker Stack on DigitalOcean Droplet

Claude Code must execute Phase 9 after Observability (Phase 8).

---

# 13.1 Overview (ภาพรวม CI/CD)

## TH:

ระบบ CI/CD นี้จะทำให้ทุกครั้งที่ Aunji หรือ Claude Code push โค้ดขึ้น GitHub:

* auto build
* auto test
* auto lint (ถ้ามี)
* auto create Docker image
* auto deploy ขึ้น Droplet โดยไม่มี downtime
* auto reload services (API, PWA, Admin)
* auto log deployment history

## EN:

CI/CD must:

* build on every push
* run tests
* build Docker images
* push to GHCR (GitHub Container Registry)
* deploy to Droplet using SSH & docker-compose pull/up
* ensure zero downtime using rolling restart

---

# 13.2 GitHub Repositories (Required)

1. **flexstock-api**
2. **kitchen-api**
3. **kitchen-admin**
4. **kitchen-pwa**
5. **pdf-engine**

Each repo must contain:

```
.github/workflows/deploy.yml
```

---

# 13.3 GitHub Secrets (Must be configured)

For each repo:

```
SSH_HOST=159.65.132.177
SSH_USER=aunji
SSH_KEY=<your_private_key>
DOCKER_CONTEXT=/home/aunji/kitchenos-stack/
```

Also:

```
CR_PAT=<GitHub Personal Access Token>
```

Used for GHCR push.

---

# 13.4 CI Stages (Full Pipeline)

### 1) Trigger

* On push to `main`
* On pull request (test only)

### 2) Install dependencies

* PHP deps via composer
* Node deps via npm
* Docker build tools

### 3) Tests

* Laravel test suite
* Next.js type check
* Node unit tests (PDF Engine)

### 4) Build Docker image

Each repo’s workflow must build:

* `ghcr.io/aunji/kitchen-api:latest`
* `ghcr.io/aunji/flexstock-api:latest`
* `ghcr.io/aunji/kitchen-admin:latest`
* `ghcr.io/aunji/kitchen-pwa:latest`
* `ghcr.io/aunji/pdf-engine:latest`

### 5) Push image to GHCR

### 6) SSH → Droplet & deploy

Commands:

```
docker compose pull
docker compose up -d
docker system prune -f
```

### 7) Post-deploy health check

Call:

```
https://kitchen.zentrydev.com/health
https://stock.zentrydev.com/health
```

### 8) Log deployment history

Append entry:

```
/home/aunji/kitchenos-stack/deploy_logs/YYYYMMDD-HHMM.log
```

---

# 13.5 GitHub Actions Workflow Template (Laravel APIs)

**For flexstock-api and kitchen-api:**

File:

```
.github/workflows/deploy.yml
```

Content:

```yaml
name: Deploy Laravel API

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mbstring, bcmath, intl, redis, pdo_mysql

      - name: Install Composer deps
        run: composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

      - name: Run Tests
        run: php artisan test || true

      - name: Login to GHCR
        run: echo "${{ secrets.CR_PAT }}" | docker login ghcr.io -u aunji --password-stdin

      - name: Build Docker Image
        run: docker build -t ghcr.io/aunji/${{ github.event.repository.name }}:latest .

      - name: Push Docker Image
        run: docker push ghcr.io/aunji/${{ github.event.repository.name }}:latest

      - name: Deploy to Droplet
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd ${{ secrets.DOCKER_CONTEXT }}
            docker compose pull
            docker compose up -d
            docker system prune -f

      - name: Health Check
        run: curl -s https://kitchen.zentrydev.com/health || true
```

---

# 13.6 GitHub Actions Workflow (Next.js Admin + PWA)

```yaml
name: Deploy Next.js app

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install deps
        run: npm install

      - name: Lint and Build
        run: npm run build

      - name: Login to GHCR
        run: echo "${{ secrets.CR_PAT }}" | docker login ghcr.io -u aunji --password-stdin

      - name: Build Docker Image
        run: docker build -t ghcr.io/aunji/${{ github.event.repository.name }}:latest .

      - name: Push Image
        run: docker push ghcr.io/aunji/${{ github.event.repository.name }}:latest

      - name: Deploy to Droplet
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd ${{ secrets.DOCKER_CONTEXT }}
            docker compose pull
            docker compose up -d
            docker system prune -f
```

---

# 13.7 GitHub Actions Workflow (PDF Engine)

Identical to Node deployment above.

---

# 13.8 Deployment Directory Rules

On Droplet:

```
/home/aunji/kitchenos-stack/
  docker-compose.yml
  .env files
  logs/
  deploy_logs/
```

Pipeline must never override `.env` files.

---

# 13.9 Zero-Downtime Deployment Rules

`docker compose up -d` will:

* Start new containers
* Stop old containers only after new ones are running
* Ensure no interruption for users

Laravel Octane must auto reload.

---

# 13.10 Backup Rules (Before Deployment)

Claude must add OPTIONAL step:

```
docker exec kitchenos_mysql mysqldump -u root -p > backup_YYYYMMDD.sql
```

Save to:

```
/home/aunji/kitchenos-stack/backups/
```

---

# 13.11 Git Commit Rules (Phase 9)

Claude must push:

```
git commit -m "Phase 9: Added CI/CD pipelines for all services (Docker + GHCR + Droplet deploy)"
git push
```

Update phase tracker:

```
progress_logs/latest_phase.txt = "PHASE 9 COMPLETE"
```

---

# END OF PART 10
# 14. PHASE 10 — FINAL SYSTEM VERIFICATION (Go-Live Readiness)

This phase ensures *everything in KitchenOS is production-ready*.
Claude Code must perform these checks automatically before declaring the system fully deployed.

---

# 14.1 Overview (ภาพรวมของการตรวจสอบ)

## TH:

ก่อนเปิดให้ร้านใช้งาน ต้องตรวจสอบทุกส่วนดังนี้:

* API ตอบสนองเร็ว ไม่มี error
* PDF Engine ทำงานครบทุก template
* FlexStock ส่งราคา, batch, ledger ได้ถูกต้อง
* Kitchen PWA โหลดไวในครัว
* Admin Web ใช้งานได้ทุกเมนู
* ทุกรูปแบบ multi-tenant แยกข้อมูลไม่ปนกัน
* ระบบ queue ไม่ค้าง
* ระบบ AI ตอบได้ ไม่มี timeout
* Docker stack stable
* CI/CD deploy แบบไม่มี downtime

## EN:

This phase validates:

* API performance
* Multi-tenant isolation
* Admin Web stability
* PWA stability
* PDF rendering reliability
* Queue + Redis behaviour
* Database connections
* AI endpoints
* Docker compose stack
* CI/CD behavior

---

# 14.2 Health Checks (Auto)

Claude must call:

### KitchenOS API:

```
GET https://kitchen.zentrydev.com/health
```

### FlexStock API:

```
GET https://stock.zentrydev.com/health
```

### PDF Engine:

```
GET https://pdf.zentrydev.com/status
```

(if exposed through Traefik)

### Admin Web:

```
curl -I https://kitchen-admin.zentrydev.com
```

### Kitchen PWA:

```
curl -I https://kitchen.zentrydev.com/pwa
```

If any return non-200 → mark phase as `INCOMPLETE`.

---

# 14.3 Multi-Tenant Isolation Test

Claude must automatically test:

1. Tenant A create material
2. Tenant B cannot read it
3. Tenant A create recipe
4. Tenant B cannot read it
5. Tenant A generate PDF
6. PDF URL must contain correct folder path:

   ```
   kitchenos-pdfs/<tenant_id>/<recipe_id>.pdf
   ```

If any cross-tenant data leakage → BLOCK deployment.

---

# 14.4 FlexStock Functional Tests

Claude must run API functional checks:

### Price Logic

* Set price
* Update price
* Get latest price
* Ensure latest = highest effective_at

### Stock Logic

* purchase
* consume (FIFO)
* ledger count increases

### Material Search

```
GET /materials?search=chicken
```

must return expected results.

---

# 14.5 KitchenOS API Functional Tests

## Recipes:

* Create
* Update
* Add ingredients
* Calculate cost
* Generate SOP via AI
* Generate PDF job

## Staff Functions:

* Create staff
* Assign task
* Complete task (with photo)

## Attendance:

* Clock-in
* Clock-out

---

# 14.6 PDF Rendering Verification

Claude must queue 3 test PDFs:

```
recipe.pdf
costing.pdf
sop.pdf
```

Each must be:

* > 50 KB
* < 2 MB
* no blank pages
* has title, ingredients, costing summary
* cloudinary URL available

---

# 14.7 Admin Web Tests

Claude must verify:

* Login works with real user
* Dashboard loads without error
* Recipe CRUD works
* SOP drag & drop works
* Ingredient selector pulls FlexStock data
* Costing page calculates correctly
* PDF Viewer loads generated PDF
* Staff list & tasks display correctly
* Settings page updates tenant info

---

# 14.8 Kitchen PWA Tests

Claude must ensure:

* PWA installable
* Offline caching for assets
* Steps load fast (< 300 ms)
* Images load correctly
* Staff task workflow works
* “Explain this step” AI button works

---

# 14.9 Worker & Queue Stability Test

Claude must:

* Push 20 PDF jobs
* Ensure worker does NOT crash
* Ensure all jobs finish under 15 seconds avg

If any job fails → phase incomplete.

---

# 14.10 API Performance Requirements

Minimum performance under load (DigitalOcean 1–2 vCPU):

```
KitchenOS API: 50 requests/sec
FlexStock API: 50 requests/sec
PWA assets < 100ms
Admin Web < 300ms
```

If response times exceed above → mark warning.

---

# 14.11 Log & Error Inspection

Claude must inspect:

```
storage/logs/laravel.log
storage/logs/api_requests.log
storage/logs/ai_usage_*.log
storage/logs/queue_worker.log
```

If any of these appear:

```
SQLSTATE
RedisException
Queue timeout
AI service unavailable
PDF error
```

→ Mark as potential deployment blocker.

---

# 14.12 Security Verification

Claude must check:

* `.env` files NOT exposed
* Admin Web headers:

  ```
  X-Frame-Options: DENY
  X-XSS-Protection: 1
  X-Content-Type-Options: nosniff
  ```
* HTTPS enforced (Cloudflare)
* API returns safe error messages
* JWT tokens stored securely

---

# 14.13 Final Go-Live Checklist (MUST PASS)

Claude must validate all items below:

### ✔ API health = OK

### ✔ Multi-tenant isolation = OK

### ✔ PDF generation = OK

### ✔ Queue processing = OK

### ✔ AI endpoints = OK

### ✔ Deploy pipeline = OK

### ✔ Docker stack stable = OK

### ✔ Admin Web works = OK

### ✔ Kitchen PWA works = OK

### ✔ Log inspection clean = OK

### ✔ No sensitive data leaking = OK

If all pass → system ready.

---

# 14.14 Git Commit Rules (Phase 10)

Claude must commit:

```
git commit -m "Phase 10: Final verification & go-live readiness checklist"
git push
```

Then update:

```
progress_logs/latest_phase.txt = "PHASE 10 COMPLETE"
```

---

# END OF PART 11
