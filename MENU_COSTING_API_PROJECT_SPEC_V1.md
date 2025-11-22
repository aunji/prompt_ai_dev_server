act you is senior dev top of world

droplet is  159.65.132.177

use aunji ssh key

you must build app to deploy on automate not ask me

and save coding log always in .md and when you come back to coding again please read log coding before think anything

0. PROJECT OVERVIEW

Project Name: menu-costing-api
Goal: สร้าง RESTful API สำหรับระบบ:

คำนวณต้นทุนวัตถุดิบ + เมนู

จัดการสูตร (Recipe) + SOP

วางเป้าขาย / Break-even / Feasibility

ทำ Scenario (Sensitivity) เมื่อราคาวัตถุดิบ หรือราคาขายเปลี่ยน

ใช้ได้ทั้ง:

future web frontend

mobile app

หรือ Google Sheet connector ภายหลัง

1. TECH STACK & CONSTRAINTS

ใช้ Laravel 11 + PHP 8.2 (API only)

Database: MySQL 8 (ถ้าไม่มี ให้ช่วยตั้งค่าใน droplet ด้วย)

Auth:

ใช้ Laravel Sanctum ทำ token-based auth (สำหรับ web SPA หรือ mobile ในอนาคต)

ไม่ต้องสร้าง Blade / View / Livewire

ทุกอย่างตอบเป็น JSON ผ่าน routes/api.php

Code style:

ใช้ Service classes แยก logic การคำนวณให้ชัด

Controller บางเบา เน้นเรียก Service

Tests:

Feature test ขั้นพื้นฐาน สำหรับ endpoint สำคัญ

Unit test สำหรับ logic การคำนวณ

2. DIRECTORY & INITIAL SETUP

ให้ทำบนเซิร์ฟเวอร์ dev (เช่น aun-ai-server) หรือเครื่องที่คุณเห็นเหมาะสม:

สร้างโปรเจกต์ Laravel:

cd ~
composer create-project laravel/laravel menu-costing-api "11.*"


ติดตั้ง Sanctum:

cd ~/menu-costing-api
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate


Config Sanctum:

เปิด config/sanctum.php และ .env ให้ใช้ token-based (เหมาะกับ API)

ตั้งค่า .env ตัวอย่าง (dev):

APP_NAME="MenuCostingAPI"
APP_ENV=local
APP_KEY=GENERATE_KEY
APP_DEBUG=true
APP_URL=http://localhost

LOG_CHANNEL=stack

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=menu_costing_api
DB_USERNAME=YOUR_DB_USER
DB_PASSWORD=YOUR_DB_PASSWORD


ให้สร้าง DB ชื่อ menu_costing_api โดยอัตโนมัติ (ถ้ายังไม่มี)

3. DATABASE SCHEMA

สร้าง migrations, models และ relationships ตามนี้

3.1 Users (พื้นฐาน)

users

id (bigint, PK)

name (string)

email (string, unique)

password (string)

role (enum/string: owner, manager, staff)

created_at, updated_at

ใช้ Laravel Breeze (API) หรือเขียน register/login เองก็ได้ แต่ใช้ Sanctum เป็นหลัก

3.2 Ingredients & Prices

Table: ingredients

id

name (string)

unit (string) — เช่น g, kg, ml, piece

category (string, nullable) — เช่น meat, veg, sauce

is_active (boolean, default true)

created_at, updated_at

Table: ingredient_prices

id

ingredient_id (FK → ingredients)

supplier_name (string, nullable)

purchase_unit (string) — เช่น "pack 1kg"

purchase_qty (decimal(12,4)) — จำนวนหน่วยสุทธิที่ได้ เช่น 1000 (g)

purchase_cost (decimal(12,4)) — ราคาที่จ่ายต่อ pack

waste_percent (decimal(5,2), default 0) — % ที่สูญเสียระหว่างเตรียม

effective_cost_per_unit (decimal(12,6)) — บาทต่อ ingredient.unit (คำนวณเก็บไว้)

valid_from (date)

is_current (boolean, default true)

created_at, updated_at

Logic effective_cost_per_unit:

net_qty = purchase_qty * (1 - waste_percent/100)
effective_cost_per_unit = purchase_cost / net_qty


เวลาบันทึกหรืออัปเดตราคาใหม่:

set is_current = false สำหรับราคาก่อนหน้า ของ ingredient เดียวกัน

คำนวณ field effective_cost_per_unit จากสูตรด้านบน

3.3 Recipes & Recipe Ingredients

Table: recipes

id

name (string)

code (string, unique) — รหัสสูตร

yield_qty (decimal(10,2)) — จำนวน portion ต่อ 1 batch

yield_unit (string) — เช่น portion, plate, glass

notes (text, nullable)

created_at, updated_at

Table: recipe_ingredients

id

recipe_id (FK → recipes)

ingredient_id (FK → ingredients)

qty (decimal(12,4)) — จำนวนที่ใช้ใน 1 batch

unit (string) — ถ้า unit ไม่ตรง ingredient.unit ให้ถือว่าผู้ใช้ใส่ให้ตรงเอง เพื่อความง่าย

extra_loss_percent (decimal(5,2), default 0)

remark (string, nullable)

created_at, updated_at

คำนวณค่า Recipe:

RecipeCostService:

function: calculateRecipeCost(recipeId): RecipeCostResult

recipe_cost (cost ทั้ง batch)

cost_per_portion (ต้นทุนต่อ 1 portion)

สูตร:

effective_cost_of_item = qty * effective_cost_per_unit(ingredient) * (1 + extra_loss_percent/100)
recipe_cost = Σ effective_cost_of_item
cost_per_portion = recipe_cost / yield_qty

3.4 Menu Items

Table: menu_items

id

recipe_id (FK → recipes)

name_on_menu (string)

selling_price (decimal(12,2))

vat_included (boolean, default true)

target_cost_percent (decimal(5,2), nullable) — เช่น 35

is_active (boolean, default true)

created_at, updated_at

ในระบบจะไม่ได้เก็บ cost_per_portion ตายตัว แต่ให้คำนวณจาก recipe + ingredient prices ปัจจุบัน
อาจมี table cache ภายหลังถ้าจำเป็น แต่เฟสนี้คำนวณสดได้

คำนวณ Margin ของเมนู:

ใน MenuCostingService:

cost_per_portion = from RecipeCostService
gross_profit_per_portion = selling_price - cost_per_portion
gross_margin_percent = (gross_profit_per_portion / selling_price) * 100
cost_percent = (cost_per_portion / selling_price) * 100

3.5 Sales Target & Sales Mix

Table: sales_targets

id

name (string) — เช่น แผนเดือน Jan 2026

period_type (enum/string: daily, weekly, monthly, custom)

start_date (date)

end_date (date)

fixed_costs (decimal(12,2)) — ค่าใช้จ่ายคงที่ในช่วงนั้น เช่น ค่าเช่า, เงินเดือน, น้ำไฟ

target_profit_amount (decimal(12,2), default 0)

notes (text, nullable)

created_at, updated_at

Table: sales_mix_assumptions

id

sales_target_id (FK → sales_targets)

menu_item_id (FK → menu_items)

expected_qty (decimal(12,2))

created_at, updated_at

Feasibility / Break-even Logic — ใน FeasibilityService:

จาก sales_target + mix:

total_gp = Σ expected_qty(menu_item) * gp_per_portion(menu_item)
total_qty = Σ expected_qty(menu_item)
avg_gp_per_portion = total_gp / total_qty

break_even_qty = fixed_costs / avg_gp_per_portion
required_qty = (fixed_costs + target_profit_amount) / avg_gp_per_portion


คืนค่า:

break_even_qty

required_qty

เปรียบเทียบกับ Σ expected_qty ว่า plan นี้ feasible หรือไม่

3.6 Scenarios (Sensitivity Analysis)

Table: scenarios

id

name (string) — เช่น หมู+เนื้อขึ้นราคา 20%

description (text, nullable)

base_sales_target_id (FK → sales_targets, nullable)

created_at, updated_at

Table: scenario_ingredient_adjustments

id

scenario_id (FK → scenarios)

ingredient_id (nullable, FK → ingredients)

ingredient_category (nullable, string) — เช่น meat ถ้าอยากปรับทั้งกลุ่ม

price_change_percent (decimal(6,2)) — เช่น 20 = +20%

created_at, updated_at

Table: scenario_menu_adjustments (optional เฟส 1)

id

scenario_id (FK → scenarios)

menu_item_id (FK → menu_items)

price_change_percent (decimal(6,2), nullable)

expected_qty_change_percent (decimal(6,2), nullable)

created_at, updated_at

ScenarioService:

function: simulateScenario(scenarioId) → คืนผลลัพธ์:

margin เดิม vs ใหม่

break_even_qty เดิม vs ใหม่

required_qty เดิม vs ใหม่

วิธี:

อ่าน base sales target + mix

ปรับราคาต้นทุน ingredient ตาม scenario_ingredient_adjustments

ถ้าเจาะ ingredient → แทนที่ effective_cost_per_unit ด้วยที่ปรับแล้ว (ใน simulation, ไม่เขียนลง DB)

ถ้าใช้ category → ใช้กับ ingredients ทุกตัวใน category

ปรับ selling_price / expected_qty ตาม scenario_menu_adjustments

คำนวณใหม่ด้วยสูตร FeasibilityService

3.7 SOP Templates

Table: sop_templates

id

recipe_id (FK → recipes)

version (integer)

title (string)

objective (text)

required_tools (text / json)

estimated_time_min (integer, nullable)

critical_points (text, nullable)

created_at, updated_at

Table: sop_steps

id

sop_template_id (FK → sop_templates)

step_order (integer)

description (text)

image_url (string, nullable)

timer_seconds (integer, nullable)

created_at, updated_at

4. LARAVEL MODELS & RELATIONSHIPS

สร้าง Models พร้อม fillable หรือ casts ที่เหมาะสม ทุก model มี HasFactory

ตัวอย่าง relationships:

Ingredient

hasMany(IngredientPrice)

IngredientPrice

belongsTo(Ingredient)

Recipe

hasMany(RecipeIngredient)

hasOne(SopTemplate)->latest('version') (หรือ hasMany)

RecipeIngredient

belongsTo(Recipe)

belongsTo(Ingredient)

MenuItem

belongsTo(Recipe)

SalesTarget

hasMany(SalesMixAssumption)

SalesMixAssumption

belongsTo(SalesTarget)

belongsTo(MenuItem)

Scenario

hasMany(ScenarioIngredientAdjustment)

hasMany(ScenarioMenuAdjustment)

belongsTo(SalesTarget, 'base_sales_target_id')

SopTemplate

belongsTo(Recipe)

hasMany(SopStep)

SopStep

belongsTo(SopTemplate)

5. SERVICES (BUSINESS LOGIC)

สร้าง Service classes ใน app/Services:

IngredientPriceService

create/update ราคา และคำนวณ effective_cost_per_unit

RecipeCostService

calculateRecipeCost(int $recipeId): RecipeCostResultDTO

MenuCostingService

รับ MenuItem → เรียก RecipeCostService → คืน margin data

FeasibilityService

รับ SalesTarget → ใช้ MenuCostingService + mix

ScenarioService

จำลองราคาต้นทุน/ราคาขายที่ปรับแล้ว และคำนวณ feasibility เปรียบเทียบ

แนะนำสร้าง DTO ง่าย ๆ ใน app/DTOs/ สำหรับผลลัพธ์ calculation

6. API DESIGN

ใช้ prefix /api/v1/... ทั้งหมด (ใน routes/api.php)

ใช้ Sanctum สำหรับ auth:

/api/v1/auth/register — สมัคร user ใหม่ (owner/manager)

/api/v1/auth/login — รับ email/password → คืน token

/api/v1/auth/me

/api/v1/auth/logout

6.1 Ingredients & Prices

GET /api/v1/ingredients

list + filter: category, search, active

POST /api/v1/ingredients

GET /api/v1/ingredients/{id}

PUT /api/v1/ingredients/{id}

DELETE /api/v1/ingredients/{id} (soft delete หรือ is_active=false)

GET /api/v1/ingredients/{id}/prices

POST /api/v1/ingredients/{id}/prices

body: supplier_name, purchase_unit, purchase_qty, purchase_cost, waste_percent, valid_from

คำนวณ effective_cost_per_unit และจัดการ is_current

GET /api/v1/ingredients/{id}/current-price

6.2 Recipes

GET /api/v1/recipes

POST /api/v1/recipes

GET /api/v1/recipes/{id}

PUT /api/v1/recipes/{id}

DELETE /api/v1/recipes/{id}

Recipe ingredients:

GET /api/v1/recipes/{id}/ingredients

POST /api/v1/recipes/{id}/ingredients

array ของ ingredients ในครั้งเดียว หรือทีละตัวก็ได้

PUT /api/v1/recipes/{id}/ingredients/{recipeIngredientId}

DELETE /api/v1/recipes/{id}/ingredients/{recipeIngredientId}

Recipe cost calculation:

GET /api/v1/recipes/{id}/cost

response: recipe_cost, cost_per_portion, breakdown ต่อ ingredient

6.3 Menu Items

GET /api/v1/menu-items

POST /api/v1/menu-items

GET /api/v1/menu-items/{id}

PUT /api/v1/menu-items/{id}

DELETE /api/v1/menu-items/{id}

Menu costing:

GET /api/v1/menu-items/{id}/costing

response:

selling_price

cost_per_portion

gross_profit_per_portion

gross_margin_percent

cost_percent

target_cost_percent

is_over_target (bool)

6.4 Sales Targets & Mix

GET /api/v1/sales-targets

POST /api/v1/sales-targets

GET /api/v1/sales-targets/{id}

PUT /api/v1/sales-targets/{id}

DELETE /api/v1/sales-targets/{id}

Sales mix:

GET /api/v1/sales-targets/{id}/mix

POST /api/v1/sales-targets/{id}/mix

body: array of {menu_item_id, expected_qty}

PUT /api/v1/sales-targets/{id}/mix/{mixId}

DELETE /api/v1/sales-targets/{id}/mix/{mixId}

Feasibility calculation:

GET /api/v1/sales-targets/{id}/feasibility

response:

fixed_costs

target_profit_amount

avg_gp_per_portion

break_even_qty

required_qty

total_expected_qty

is_feasible

6.5 Scenarios

GET /api/v1/scenarios

POST /api/v1/scenarios

GET /api/v1/scenarios/{id}

PUT /api/v1/scenarios/{id}

DELETE /api/v1/scenarios/{id}

Scenario ingredient adjustments:

GET /api/v1/scenarios/{id}/ingredient-adjustments

POST /api/v1/scenarios/{id}/ingredient-adjustments

PUT /api/v1/scenarios/{id}/ingredient-adjustments/{adjId}

DELETE /api/v1/scenarios/{id}/ingredient-adjustments/{adjId}

Scenario menu adjustments:

GET /api/v1/scenarios/{id}/menu-adjustments

POST /api/v1/scenarios/{id}/menu-adjustments

PUT /api/v1/scenarios/{id}/menu-adjustments/{adjId}

DELETE /api/v1/scenarios/{id}/menu-adjustments/{adjId}

Scenario simulation:

GET /api/v1/scenarios/{id}/simulate

response:

base vs scenario:

avg_gp_per_portion

break_even_qty

required_qty

total_expected_qty

summary message

6.6 SOP

GET /api/v1/recipes/{id}/sops

POST /api/v1/recipes/{id}/sops

สร้างเวอร์ชันใหม่

GET /api/v1/sops/{id}

PUT /api/v1/sops/{id}

DELETE /api/v1/sops/{id}

Steps:

GET /api/v1/sops/{id}/steps

POST /api/v1/sops/{id}/steps

PUT /api/v1/sops/{id}/steps/{stepId}

DELETE /api/v1/sops/{id}/steps/{stepId}

7. TESTS

สร้าง test อย่างน้อย:

Feature tests:

Auth (register/login/me)

Ingredients + prices + current price

Recipe cost endpoint

Menu costing endpoint

Sales feasibility endpoint

Scenario simulate endpoint

Unit tests:

RecipeCostService

FeasibilityService

ScenarioService

ใช้ PHPUnit + Laravel test utilities

8. DEPLOYMENT TO DIGITALOCEAN DROPLET

Goal: deploy Laravel API ไปยัง droplet และ map กับ
https://zentrydev.com/webapp/menu-costing-api/

8.1 Server Setup Script

ให้สร้างไฟล์ bash เช่น scripts/setup_droplet_menu_costing_api.sh (idempotent):

ติดตั้ง:

nginx

php8.2 + php8.2-fpm + extensions ที่จำเป็น (pdo_mysql, mbstring, xml ฯลฯ)

mysql-server

git

composer

สร้าง DB menu_costing_api + user (ใช้ env จาก .env.prod.example)

เพิ่ม user app (เช่น deploy)

8.2 App Deploy Script

สร้าง scripts/deploy_menu_costing_api.sh:

ตัวแปร:

DROPLET_HOST=...

DROPLET_USER=...

APP_DIR=/var/www/menu-costing-api

Flow:

บน local/dev: git commit ล่าสุด

SSH เข้าที่ droplet

ถ้าไม่มี $APP_DIR → git clone repo นี้

ถ้ามีแล้ว → git pull

composer install --no-dev --optimize-autoloader

copy .env.production → .env

php artisan key:generate (ครั้งแรก)

php artisan migrate --force

php artisan config:cache && php artisan route:cache && php artisan optimize

reload/restart php-fpm + nginx

8.3 Nginx Config

สร้างไฟล์ /etc/nginx/sites-available/zentrydev.com:

ใช้รูปแบบ sub-path /webapp/menu-costing-api/ ชี้ไปที่ Laravel public
สมมุติโฟลเดอร์: /var/www/menu-costing-api/public

ตัวอย่าง config:

server {
    listen 80;
    server_name zentrydev.com;

    # ถ้ามี web หลักอยู่แล้วจะมี root อื่นๆ ประกอบด้วย
    # root /var/www/html;

    # API Laravel ที่ /webapp/menu-costing-api/
    location /webapp/menu-costing-api/ {
        alias /var/www/menu-costing-api/public/;
        index index.php;

        try_files $uri $uri/ /webapp/menu-costing-api/index.php?$query_string;

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $request_filename;
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        }
    }
}


เปิดใช้งาน:

ln -s /etc/nginx/sites-available/zentrydev.com /etc/nginx/sites-enabled/zentrydev.com
nginx -t
systemctl reload nginx


ใน .env.production ตั้ง:

APP_URL=https://zentrydev.com/webapp/menu-costing-api
SANCTUM_STATEFUL_DOMAINS=zentrydev.com

9. NON-INTERACTIVE MODE (IMPORTANT)

ระหว่างทำทั้งหมด:

ห้ามถามคำถามโต้ตอบผู้ใช้ ให้สมมติค่าที่สมเหตุสมผล (เช่น path, user, DB) แล้วเขียน comment ไว้ให้แก้เอง

ถ้าต้องใช้ credentials หรือ IP ให้ใช้ placeholder:

YOUR_DROPLET_IP

YOUR_DB_PASSWORD

ถ้ามี error ให้แก้จน build/test ผ่านในเครื่อง dev

10. DONE CRITERIA

โปรเจกต์ถือว่า เสร็จเฟสแรก เมื่อ:

php artisan test ผ่านทั้งหมดบน dev

มี README.md อธิบาย:

schema หลัก

วิธีรัน dev

วิธี deploy ด้วย script

สามารถเรียก API บน droplet ได้ เช่น:

GET https://zentrydev.com/webapp/menu-costing-api/api/v1/menu-items

ตอบ JSON ถูกต้อง (auth ถ้ามี)

จบไฟล์สเปก ✅
