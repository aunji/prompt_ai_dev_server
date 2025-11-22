# TASK: Setup Docker Droplet for zentrydev.com + 999jewelry + /webapp/*

You are **Claude Code** running on my dev server via SSH.
Your job: จากเครื่อง `aun-ai-server` ให้ตั้งค่า Droplet ใหม่ให้รันเว็บดังนี้ด้วย Docker:

- `https://zentrydev.com` → CMS/Blog (ไม่มี Product)
- `https://999jewelry.zentrydev.com` → CMS + Product Catalog
- `https://zentrydev.com/webapp/<project-name>` → Path สำหรับ Web App ต่าง ๆ (Laravel API + Next.js ฯลฯ) ที่รันผ่าน Docker อยู่หลัง Reverse Proxy

Do everything **end-to-end over SSH**, fully automated, no questions.

---

## CONFIG (EDIT THESE BEFORE RUNNING)

Assume you are running on my dev server in `/home/aunji`.

**1) Droplet info**

- SSH host (Droplet): `DROPLET_HOST=159.65.132.177`  
- SSH user: `DROPLET_USER=root`  
- SSH port: `22`

**2) Project paths on dev server (already exist and contain code)**

(แก้ให้ตรงกับของจริง)

```text
/home/aunji/projects/zentrydev-cms          # Laravel CMS/Blog for zentrydev.com
/home/aunji/projects/999jewelry-cms        # Laravel CMS + product catalog
/home/aunji/projects/webapps               # Folder รวม Web Apps หลายตัว
                                           # ตัวอย่าง: /home/aunji/projects/webapps/costing-app
3) Base path on Droplet for deployment

Use:

text
Copy code
/opt/zentry-stack        # main stack
  ├─ apps
  │   ├─ zentrydev-cms
  │   ├─ 999jewelry-cms
  │   └─ webapps/<project-name>...
  ├─ proxy               # Caddy reverse proxy
  └─ docker-compose.yml
GLOBAL RULES
ทำงานแบบ non-interactive: อย่าถามคำถามระหว่างทำ

เขียนสคริปต์ให้รันซ้ำได้ (idempotent) – ถ้าไฟล์/โฟลเดอร์มีอยู่แล้วให้เช็คก่อน

ใช้ Docker + docker compose v2 (docker compose) เป็นหลัก

ใช้ Caddy เป็น reverse proxy + TLS (Let’s Encrypt)

ใช้ rsync จาก dev server → Droplet แทนการ git clone ตรง ๆ

เขียนทุกอย่างเป็น Bash script และ config file จริง ๆ บนเครื่อง (ไม่ใช่แค่ตัวอย่าง)

PHASE 1 – Prepare Droplet (system + Docker + user)
1.1 From aun-ai-server: basic SSH test
สร้าง Bash script บน dev server:

ที่ /home/aunji/zentrydev_infra/test_ssh.sh

ทำสิ่งต่อไปนี้:

เช็คว่า ssh $DROPLET_USER@$DROPLET_HOST เชื่อมได้โดยไม่ถาม host key (-o StrictHostKeyChecking=accept-new)

echo ข้อความ "Connected OK" ถ้าสำเร็จ

รัน script นี้หนึ่งครั้งยืนยันว่าใช้ได้

1.2 On Droplet: system update + Docker
เขียนสคริปต์ setup_system.sh บน Droplet (ใช้ SSH จาก dev server ไปสร้างไฟล์)

สคริปต์ต้องทำ:

apt-get update && apt-get upgrade -y

ติดตั้ง tools พื้นฐาน: curl, git, ufw, rsync, ca-certificates, gnupg, lsb-release

ติดตั้ง Docker CE + docker compose plugin ตามขั้นตอน official

systemctl enable docker && systemctl start docker

ตั้งค่า UFW:

allow OpenSSH

allow 80, 443

enable แบบ non-interactive (ufw --force enable ถ้ายัง inactive)

สคริปต์ต้องตรวจสอบว่า Docker ติดตั้งแล้วหรือยัง ถ้ามีแล้วให้ skip

PHASE 2 – Folder structure + docker-compose stack
2.1 Create base structure
บน Droplet สร้างโฟลเดอร์:

bash
Copy code
/opt/zentry-stack
/opt/zentry-stack/apps
/opt/zentry-stack/apps/zentrydev-cms
/opt/zentry-stack/apps/999jewelry-cms
/opt/zentry-stack/apps/webapps
/opt/zentry-stack/proxy
ตั้ง owner เป็น root:root หรือ user ที่ใช้รัน Docker (ใช้ root ก็ได้ใน droplet เดี่ยวนี้)

2.2 docker-compose.yml (multi-service stack)
สร้างไฟล์ /opt/zentry-stack/docker-compose.yml มี services หลัก:

caddy – reverse proxy + TLS

zentrydev_cms – Laravel app สำหรับ zentrydev.com

jewelry_cms – Laravel app สำหรับ 999jewelry.zentrydev.com

webapps_router – simple Node/NGINX container ที่ทำหน้าที่เป็น entry point สำหรับ /webapp/<project> (ภายในอาจ reverse proxy ไป service อื่น หรือแค่เป็น Next.js app ที่เรา map route)

รวมถึง db (ถ้าทั้ง 2 CMS แชร์ db เดียว):

mysql (optional ถ้าในโปรเจกต์ใช้ MySQL)

volume: mysql_data

โครง docker-compose (ให้เขียนไฟล์จริง):
yaml
Copy code
version: "3.9"

services:
  caddy:
    image: caddy:2
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./proxy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - zentrydev_cms
      - jewelry_cms
      - webapps_router

  mysql:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: zentry_main
      MYSQL_USER: app_user
      MYSQL_PASSWORD: app_password
    volumes:
      - mysql_data:/var/lib/mysql

  zentrydev_cms:
    build:
      context: ./apps/zentrydev-cms
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      APP_ENV: production
      APP_DEBUG: "false"
      APP_URL: https://zentrydev.com
      DB_CONNECTION: mysql
      DB_HOST: mysql
      DB_PORT: 3306
      DB_DATABASE: zentry_main
      DB_USERNAME: app_user
      DB_PASSWORD: app_password
    depends_on:
      - mysql

  jewelry_cms:
    build:
      context: ./apps/999jewelry-cms
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      APP_ENV: production
      APP_DEBUG: "false"
      APP_URL: https://999jewelry.zentrydev.com
      DB_CONNECTION: mysql
      DB_HOST: mysql
      DB_PORT: 3306
      DB_DATABASE: zentry_main
      DB_USERNAME: app_user
      DB_PASSWORD: app_password
    depends_on:
      - mysql

  webapps_router:
    build:
      context: ./apps/webapps
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      NODE_ENV: production

volumes:
  mysql_data:
  caddy_data:
  caddy_config:
NOTE: You must actually create minimal Dockerfile for each service as part of this task (ดู PHASE 3).

PHASE 3 – App deployment (rsync from dev server → droplet)
3.1 Rsync scripts on dev server
บน dev server ให้สร้างสคริปต์ deployment:

/home/aunji/zentrydev_infra/deploy_zentrydev_cms.sh

/home/aunji/zentrydev_infra/deploy_999jewelry_cms.sh

/home/aunji/zentrydev_infra/deploy_webapps.sh

โครงหลัก:

bash
Copy code
#!/usr/bin/env bash
set -e

DROPLET_HOST="xxx.xxx.xxx.xxx"
DROPLET_USER="root"

SRC="/home/aunji/projects/zentrydev-cms/"
DEST="/opt/zentry-stack/apps/zentrydev-cms/"

rsync -avz \
  --delete \
  -e "ssh -p 22 -o StrictHostKeyChecking=accept-new" \
  "$SRC" "$DROPLET_USER@$DROPLET_HOST:$DEST"
แต่ละตัวให้เปลี่ยน SRC/DEST ให้เหมาะสม

3.2 Create Dockerfile for Laravel apps (on droplet source tree)
สำหรับ zentrydev_cms และ jewelry_cms ให้สร้าง Dockerfile ที่:

ใช้ php:8.2-fpm หรือ php:8.2-cli + artisan serve

ติดตั้ง extensions: pdo_mysql, zip, ฯลฯ

ใช้ composer (copy มาจาก composer:2 image)

ทำ composer install --no-dev

php artisan config:cache, route:cache, ฯลฯ

expose port (เช่น 8000) แล้วให้ Caddy reverse proxy มาที่ port นั้น

ตัวอย่าง (ให้สร้างจริง):

dockerfile
Copy code
FROM php:8.2-cli

RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libpng-dev libonig-dev \
 && docker-php-ext-install pdo_mysql zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN composer install --no-dev --optimize-autoloader \
 && php artisan key:generate \
 && php artisan config:cache \
 && php artisan route:cache

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
ให้ใช้ template นี้กับทั้ง 2 CMS (เปลี่ยนบางค่าได้ถ้าจำเป็น)

3.3 webapps_router Dockerfile
สำหรับ webapps_router ให้เตรียม minimal Next.js/Node app ที่:

รับ traffic จาก Caddy เฉพาะ path /webapp/*

ภายในอาจทำเป็น:

simple Node/Express ที่ตรวจ req.path แล้ว proxy ไปยัง service อื่น (option advanced)

หรือ (ง่ายกว่า) เป็น Next.js app ที่มี route /[project]/... แล้วใช้ client-side route ไปต่าง ๆ

สำหรับตอนนี้ ให้ทำแบบง่าย:

Next.js app 1 ตัว ที่หน้าแรก (/) เป็น "Webapp Index" list (static)

path /[project] แสดงข้อความ “placeholder for project [project]”

Dockerfile ตัวอย่าง:

dockerfile
Copy code
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
PHASE 4 – Caddy configuration for domains & routing
สร้างไฟล์ /opt/zentry-stack/proxy/Caddyfile บน Droplet:

Requirements:

zentrydev.com

reverse_proxy ไป zentrydev_cms:8000

999jewelry.zentrydev.com

reverse_proxy ไป jewelry_cms:8000

zentrydev.com/webapp/*

ให้ส่งต่อไปที่ webapps_router:3000

ใช้ handle_path หรือ uri strip_prefix เพื่อถอด /webapp ออกก่อนส่งเข้า Next.js

โครง:

caddy
Copy code
zentrydev.com {
  encode gzip
  reverse_proxy zentrydev_cms:8000
}

999jewelry.zentrydev.com {
  encode gzip
  reverse_proxy jewelry_cms:8000
}

zentrydev.com {
  @webapp path /webapp/*
  handle @webapp {
    uri strip_prefix /webapp
    reverse_proxy webapps_router:3000
  }

  # default root (ถ้าไม่มี /webapp) ให้ไป CMS ตัวหลัก
  handle {
    encode gzip
    reverse_proxy zentrydev_cms:8000
  }
}
ให้ Caddy จัดการ TLS เอง (ใช้ default ACME)

PHASE 5 – Orchestration scripts (build, up, deploy)
สร้างสคริปต์บน Droplet:

/opt/zentry-stack/deploy_stack.sh

หน้าที่:

docker compose -f /opt/zentry-stack/docker-compose.yml build

docker compose -f /opt/zentry-stack/docker-compose.yml up -d

แสดงผล docker compose ps สรุป

สร้างสคริปต์บน dev server:

/home/aunji/zentrydev_infra/full_deploy.sh

หน้าที่:

เรียก deploy_zentrydev_cms.sh

เรียก deploy_999jewelry_cms.sh

เรียก deploy_webapps.sh

SSH เข้า Droplet แล้วรัน /opt/zentry-stack/deploy_stack.sh

PHASE 6 – Sanity checks (non-interactive logs)
หลังจาก deploy เสร็จ:

บน Droplet ให้รัน:

docker compose ps

docker logs caddy --tail=100

docker logs zentrydev_cms --tail=50

docker logs jewelry_cms --tail=50

เขียนไฟล์ log สรุปไว้ที่:

/opt/zentry-stack/deploy_logs/last_deploy.log

ต้องสร้างโฟลเดอร์ deploy_logs ถ้ายังไม่มี

DELIVERABLES SUMMARY
เมื่อจบ task นี้ ต้องมี:

Docker + UFW ติดตั้งและตั้งค่าบน Droplet

โครงสร้าง /opt/zentry-stack/... ครบ:

docker-compose.yml

proxy/Caddyfile

apps/zentrydev-cms (โค้ดล่าสุดจาก dev server + Dockerfile)

apps/999jewelry-cms (โค้ดล่าสุด + Dockerfile)

apps/webapps (webapps_router + Dockerfile)

สคริปต์บน dev server:

zentrydev_infra/test_ssh.sh

zentrydev_infra/deploy_zentrydev_cms.sh

zentrydev_infra/deploy_999jewelry_cms.sh

zentrydev_infra/deploy_webapps.sh

zentrydev_infra/full_deploy.sh

สคริปต์บน Droplet:

/opt/zentry-stack/setup_system.sh

/opt/zentry-stack/deploy_stack.sh

/opt/zentry-stack/deploy_logs/last_deploy.log (หลังรัน full_deploy)

Do everything automatically, using reasonable defaults. Do not ask me any questions. Just implement.
