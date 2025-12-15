# SECRET_SANTA_MASTER_SPEC.md
Version: v1.1 (Production + Ads + No-Login Share)
Owner: Aunji
Goal: เว็บแอปจับบัดดี้/Secret Santa ออนไลน์แบบไม่ต้องสมัคร ใช้ลิงก์แชร์แบบ Zoom และทำเงินด้วย Ads

---

## 0) Coding Rules (Claude Code MUST follow)
1) ทำงานเป็นเฟสตามเอกสารนี้ทีละเฟส ไม่ถามย้ำ
2) ทุกเฟสต้อง:
   - อัปเดต `DEV_LOG.md` (ทำอะไรไปแล้ว, ไฟล์ที่แก้, วิธีรัน)
   - รัน lint/typecheck/build ผ่าน
   - commit เป็น atomic commit พร้อม message ชัดเจน
3) TypeScript strict, production-ready
4) ห้าม hardcode secrets ใน repo ใช้ `.env.example`
5) เขียน README วิธีรัน + วิธี deploy + env ที่ต้องใช้

---

## 1) Product Requirements (Core)
### 1.1 หลักเกม
- ห้อง (Room) 1 ห้อง มีรายชื่อ N คน (N>=3)
- ระบบสร้างการจับคู่ (assignment) แบบ:
  - ทุกคนได้ “ผู้รับของขวัญ” 1 คน
  - ห้ามได้ตัวเอง (No self)
  - ห้ามผู้รับซ้ำ (Unique receiver)
- ผู้เล่นเข้าห้องและ “เปิดผลของตัวเอง” ได้
  - เปิดผลได้ครั้งเดียว (one-time reveal) เป็นค่า default
  - ห้ามดูผลคนอื่น
  - แชร์ลิงก์ให้เพื่อนมาเปิดของตัวเองได้

### 1.2 Must NOT get stuck (สำคัญ)
- ห้ามสุ่มทีละคนแบบเสี่ยงคนท้ายเหลือแต่ตัวเอง
- วิธีที่ใช้: Pre-generate “derangement mapping” ทั้งชุดตอนสร้างห้อง

### 1.3 No-Login Share (Zoom-like) ✅
- ไม่มีระบบสมัคร/ล็อกอิน
- ใช้ Room Link + Guest Identity (ชั่วคราวต่อเครื่อง)
- ผู้เล่นบอกต่อกันเองด้วยลิงก์
- ห้องหมดอายุได้ (default 24 ชม.)
- ป้องกัน “คนแอบอ้างชื่อเพื่อน” ด้วย Claim/Bind ต่อเครื่อง

### 1.4 Ads / Monetization
- รองรับ Google AdSense (script)
- Placement:
  - Banner bottom (หลัง reveal)
  - Optional pre-reveal overlay 3 วินาที (เปิด/ปิดด้วย env flag)
- ต้องไม่ผิดนโยบาย AdSense (ห้ามหลอกให้คลิก / ห้ามบังคับคลิก)

### 1.5 Analytics (เบื้องต้น)
- Event:
  - room_created
  - room_opened
  - name_claimed
  - reveal_success
  - reveal_failed
  - ad_shown
- ใช้ internal minimal logging (DB table) หรือจะเสียบ Plausible/Umami ภายหลังได้

---

## 2) Tech Stack
- Next.js (App Router) + TypeScript
- Tailwind CSS
- Prisma + SQLite (v1)
- Hosting: Vercel หรือ VPS (Docker)

---

## 3) UX / Pages
### 3.1 Landing `/`
- CTA: “สร้างห้องใหม่”
- SEO ไทย: จับฉลากของขวัญออนไลน์ / secret santa

### 3.2 Create Room `/create`
- Input: Room name (optional)
- People list: chips/add list
  - validate: ห้ามซ้ำ, trim, N>=3, max 50 คน
- Settings:
  - Expire in: 24h default (48h, 7d)
  - Reveal once only: true default
- Submit -> POST create -> redirect `/r/:roomCode`

### 3.3 Room `/r/:roomCode`
- แสดงชื่อห้อง + จำนวนคน + countdown expire
- “ฉันคือ” -> dropdown เลือกชื่อของตัวเอง
- เมื่อเลือกชื่อแล้ว ระบบจะ “claim ชื่อ” ให้กับเครื่องนี้ (guestId)
- ปุ่ม “จับบัดดี้ของฉัน”
- หลัง reveal:
  - แสดง “คุณต้องซื้อให้: X”
  - ปุ่ม Copy/Share link
  - แจ้งเตือน:
    - “โปรดใช้เครื่องเดิม หากเปลี่ยนเครื่องอาจเปิดซ้ำไม่ได้”

Edge UI:
- ถ้าชื่อนี้ถูก claim โดยคนอื่น → แจ้ง “ชื่อนี้ถูกใช้แล้ว”
- ถ้าชื่อนี้ reveal ไปแล้ว:
  - ถ้าเป็นเครื่องเดิม → ให้ดูผลเดิมได้ (optional setting)
  - ถ้าเป็นเครื่องอื่น → deny
- ห้องหมดอายุ → อ่านได้ แต่ reveal/claim ไม่ได้

### 3.4 `/privacy` `/terms`
- สั้น ๆ ว่าเก็บแค่ชื่อเล่นในห้อง + event log แบบไม่ระบุตัวตน
- ข้อมูลหมดอายุตามห้อง

---

## 4) No-Login Identity Model (สำคัญมาก)
### 4.1 Room Code
- URL รูปแบบ: `/r/:roomCode`
- roomCode เป็น short random เช่น 6–10 ตัวอักษร (base32/base62) ไม่เดาง่าย

### 4.2 Guest ID (per browser/device)
- เมื่อเปิดหน้า room ครั้งแรก:
  - สร้าง `guestId = crypto.randomUUID()`
  - เก็บใน cookie + localStorage
- guestId ไม่ใช่ user account เป็นแค่ identity ชั่วคราวต่อเครื่อง

### 4.3 Claim / Bind name to device
- เมื่อผู้เล่นเลือกชื่อ giver:
  - ระบบ “bind” ชื่อนั้นกับ guestId ใน DB (claims)
- หลักการ:
  - 1 ชื่อ giver → 1 guestId เท่านั้น
  - เครื่องเดิมเข้ามาใหม่ยังใช้ชื่อเดิมได้
  - เครื่องอื่นจะถูกปฏิเสธ (NAME_ALREADY_CLAIMED)

---

## 5) Data Model (Prisma)
### 5.1 Room
- id (cuid)
- code (unique short string)
- name (nullable)
- usersJson (text) // array of names
- assignmentsJson (text) // map giver->receiver (server-only)
- revealedJson (text) // map giver->boolean
- claimsJson (text) // map giver->guestId  ✅ new
- settingsJson (text) // {expireAt, revealOnce, adsMode, allowReopenSameDevice?}
- createdAt, updatedAt

### 5.2 EventLog (optional)
- id, roomId nullable, type, metaJson, createdAt

---

## 6) Core Algorithm: Derangement Generator
- Pre-generate mapping ตอนสร้างห้อง
- ต้อง satisfy:
  - receiver != giver
  - receivers unique

Approach:
- shuffle receivers until no fixed point, tries max 50
- fallback deterministic rotation + random swaps

---

## 7) API Design (Next Route Handlers)
Base: `/api`

### 7.1 POST `/api/rooms`
Body:
```json
{
  "name": "X",
  "users": ["A","B","C","D","E"],
  "expireHours": 24,
  "revealOnce": true,
  "allowReopenSameDevice": true
}
Response:

json
Copy code
{ "roomCode": "7F9KQ2" }
7.2 GET /api/rooms/:roomCode
Public meta (no assignments)

json
Copy code
{
  "roomCode":"7F9KQ2",
  "name":"X",
  "users":["A","B","C","D","E"],
  "expired": false,
  "expireAt": "ISO"
}
7.3 POST /api/rooms/:roomCode/claim
Body:

json
Copy code
{ "giver": "A", "guestId": "uuid" }
Response:

success:

json
Copy code
{ "claimed": true, "giver": "A" }
already claimed by other device:

json
Copy code
{ "error": "NAME_ALREADY_CLAIMED" }
expired:

json
Copy code
{ "error": "ROOM_EXPIRED" }
7.4 POST /api/rooms/:roomCode/reveal
Body:

json
Copy code
{ "giver": "A", "guestId": "uuid" }
Rules:

ต้อง claimed แล้ว หรือ reveal endpoint จะ auto-claim ก็ได้ (เลือกแบบง่าย: auto-claim)

ถ้า claims[giver] != guestId -> deny

ถ้า revealOnce=true:

ถ้า revealed[giver]==true:

ถ้า allowReopenSameDevice=true และ claims match -> return same receiver + revealedNow=false

else error ALREADY_REVEALED

Response:

json
Copy code
{ "receiver": "D", "revealedNow": true }
Or:

json
Copy code
{ "receiver": "D", "revealedNow": false }
Errors:

NAME_ALREADY_CLAIMED

ALREADY_REVEALED

ROOM_EXPIRED

INVALID_GIVER

7.5 POST /api/events (optional)
log events (rate limited)

8) Security / Abuse Prevention
Rate limit:

claim: 20 req/min/IP

reveal: 10 req/min/IP

Validate input:

giver must exist

guestId uuid format

sanitize names (Thai/Eng/num/space/-/_), max 24 chars

Expiration: deny claim/reveal after expireAt

Never expose assignmentsJson in any GET

Optional: basic bot protection (turnstile) later

9) Ads Integration
ENV:

NEXT_PUBLIC_ADS_ENABLED=true|false

NEXT_PUBLIC_ADS_MODE=banner|pre_reveal|both

NEXT_PUBLIC_ADSENSE_CLIENT=ca-pub-xxxxx

UI:

Banner: after reveal

Pre-reveal overlay: show 3s then call reveal

10) Deliverables
BUDDYDRAW_MASTER_SPEC.md (ไฟล์นี้)

CLAUDE_CODE_PROMPT.md

DEV_LOG.md

README.md

.env.example

docker-compose.yml + Dockerfile

prisma/schema.prisma

src/lib/derangement.ts

src/lib/guestId.ts

src/lib/rateLimit.ts

src/app/api/... handlers

src/app/create/page.tsx

src/app/r/[roomCode]/page.tsx

src/components/AdsBanner.tsx AdsOverlay.tsx

tests (unit/integration minimal)

11) Implementation Phases
Phase 1: Bootstrap Next + Tailwind + Prisma + SQLite, pages skeleton
Phase 2: Room create/get API + DB schema (with code field)
Phase 3: Derangement + claim/reveal logic + tests
Phase 4: Ads + analytics + rate limit
Phase 5: Docker + deploy docs
Phase 6: Polish UX + SEO + policy pages

12) Acceptance Criteria
N=5 ตัวอย่าง: ทุกคน reveal ครบ ไม่มีใครได้ตัวเอง ไม่มีซ้ำ

No-login: แชร์ลิงก์ คนละเครื่องเลือกชื่อได้

Claim works:

เครื่องอื่นแอบใช้ชื่อเดียวกันไม่ได้

revealOnce works:

เปิดซ้ำได้เฉพาะเครื่องเดิม (ถ้า allowReopenSameDevice=true)

Expired room: claim/reveal ไม่ได้

Build ผ่าน + migrate ผ่าน + docker run ได้

diff
Copy code

---

# 2) CLAUDE_CODE_PROMPT.md (สั่ง Claude ทำงานแบบไม่ถาม)

```md
# CLAUDE_CODE_PROMPT.md
You are Claude Code acting as a senior full-stack engineer.
Goal: Implement the project described in `BUDDYDRAW_MASTER_SPEC.md` end-to-end with production quality.

## Non-negotiable rules
- Do NOT ask questions. Make reasonable defaults based on the spec.
- Work strictly phase by phase (Phase 1 → Phase 6).
- After each phase:
  1) Update `DEV_LOG.md` with: what changed, key files, how to run/test.
  2) Ensure `npm run lint`, `npm run typecheck`, `npm run build` succeed (add scripts if missing).
  3) Commit with an atomic message: `phaseX: ...`
- Use TypeScript strict. Keep code clean and modular.
- Never expose assignments in GET responses.
- Store secrets in env only and provide `.env.example`.

## Repo setup
- Create Next.js App Router project with Tailwind
- Add Prisma + SQLite
- Add basic test runner (Vitest or Jest). Prefer Vitest for speed.

## Implementation details / defaults
- Room code: 6 chars base32 uppercase (avoid confusing chars), unique.
- Expire default 24h.
- revealOnce default true.
- allowReopenSameDevice default true.
- guestId: generate on client using crypto.randomUUID(); store in localStorage + cookie.
- Claim happens when user selects their name; reveal endpoint also verifies claim.

## Phase plan
### Phase 1: Bootstrap
- Initialize project, Tailwind, basic layout
- Pages: `/`, `/create`, `/r/[roomCode]`, `/privacy`, `/terms`
- Add UI skeleton and form validation.

### Phase 2: DB + API base
- Prisma schema: Room, EventLog optional
- Migrations
- API:
  - POST /api/rooms
  - GET /api/rooms/:roomCode

### Phase 3: Core game + no-login claim/reveal
- Implement derangement generator with fallback
- Implement:
  - POST /api/rooms/:roomCode/claim
  - POST /api/rooms/:roomCode/reveal
- Implement client guestId helper `src/lib/guestId.ts`
- Implement Room UI:
  - select name → claim
  - reveal button → pre-reveal animation → reveal result
- Tests:
  - unit: derangement correctness
  - integration: claim/reveal rules

### Phase 4: Ads + analytics + rate limit
- AdsBanner, AdsOverlay components with env flags
- Simple rate limit helper (in-memory for dev; simple DB/IP key for prod acceptable)
- Event logging for key actions

### Phase 5: Docker + docs
- Dockerfile + docker-compose.yml (SQLite volume)
- README: dev, migrate, deploy (Vercel + VPS)
- `.env.example` complete

### Phase 6: Polish
- Copy/share button, toast notifications
- SEO tags (OG/Twitter)
- Error states and empty states polish
- Basic Lighthouse sanity

## Output expectations
- The app must run locally with `npm install && npm run dev`
- Migrate with `npx prisma migrate dev`
- Production build passes
- Provide clear `README.md` and updated `DEV_LOG.md`
3) Edge cases + Test Scenarios (ให้ Claude ทำ tests ตามนี้)
3.1 Unit Tests: Derangement
N=3..50 สุ่มหลายรอบ

ทุกคนได้ receiver ไม่ซ้ำ

ไม่มีใครได้ตัวเอง

Repeatability safety: เรียก generator 1,000 ครั้งสำหรับ N=10 ต้องไม่ throw

Fallback path: บังคับให้ shuffle fail (mock) แล้วต้องได้ mapping ที่ valid

3.2 Integration Tests: Claim
Claim success

create room (A..E)

claim A ด้วย guestId1 -> ok

Claim same device again

claim A ด้วย guestId1 ซ้ำ -> ok (idempotent)

Claim by another device denied

claim A ด้วย guestId2 -> NAME_ALREADY_CLAIMED

Claim invalid giver

giver="Z" -> INVALID_GIVER

Claim after expiry

set expireAt past -> ROOM_EXPIRED

3.3 Integration Tests: Reveal
Reveal requires valid claim / or auto-claim

ถ้าออกแบบให้ reveal auto-claim:

reveal A guestId1 -> ok และ claims[A]=guestId1

ถ้าออกแบบให้ต้อง claim ก่อน:

reveal ก่อน claim -> error (NOT_CLAIMED) หรือให้ระบบ auto-claim (เลือกอย่างใดอย่างหนึ่งและเขียน test ให้ตรง)

Reveal returns receiver

reveal A guestId1 -> receiver != A

Reveal from other device denied

reveal A guestId2 -> NAME_ALREADY_CLAIMED

Reveal once logic

reveal A guestId1 -> revealedNow=true

reveal A guestId1 อีกครั้ง:

ถ้า allowReopenSameDevice=true -> receiver เดิม, revealedNow=false

ถ้า allowReopenSameDevice=false -> ALREADY_REVEALED

No assignment leakage

GET /api/rooms/:code ต้องไม่มี receiver map

Expiry blocks reveal

expired -> ROOM_EXPIRED

3.4 Concurrency-ish (สำคัญ)
claim A พร้อมกัน 2 guestId

ต้องมี 1 อันสำเร็จ อีกอัน NAME_ALREADY_CLAIMED

(ทำด้วย transaction/atomic update ใน DB)

reveal A พร้อมกัน 2 requests (guestId เดียว)

ต้องได้ receiver เดิม, state ไม่พัง

3.5 Manual QA Checklist (production)
เปิดลิงก์ในมือถือ 2 เครื่อง

เครื่องที่ 1 claim “A”

เครื่องที่ 2 เลือก “A” ต้องโดนบล็อก

ทุกคน reveal ครบแล้ว ไม่มีซ้ำ

Ads ปรากฏตาม env flags

แชร์ลิงก์ LINE แล้ว open graph ขึ้นถูกต้อง
