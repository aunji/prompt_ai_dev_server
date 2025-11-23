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
