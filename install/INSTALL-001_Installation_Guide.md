# PHAROLON Installation Guide

**Document Reference:** INSTALL-001
**Version:** 1.0
**Applies To:** PHAROLON v1.x bare metal deployment on Ubuntu 22.04 LTS or RHEL 9

---

## 1. Overview

PHAROLON deploys on a single Linux server using:

| Component | Role |
|---|---|
| Nginx | TLS termination, static file serving, reverse proxy |
| Gunicorn + Uvicorn | FastAPI application server |
| PostgreSQL 15 | Primary database |
| Redis 7 | Cache, task queue, session store |
| Celery | Background tasks and scheduled jobs |
| systemd | Process management and auto-restart |

No Docker or containerization is required. All services run as native system processes under dedicated service accounts.

---

## 2. System Requirements

### Minimum (up to 50 users)
- CPU: 4 vCPU
- RAM: 8 GB
- Disk: 50 GB (application + database)
- Disk (separate, recommended): 200 GB (file attachments)
- OS: Ubuntu 22.04 LTS or RHEL 9
- Network: Internal network only. Do not expose PostgreSQL or Redis to external networks.

### Recommended (up to 200 users)
- CPU: 8 vCPU
- RAM: 16 GB
- Disk: 100 GB SSD (OS + application + database)
- Disk (separate): 1 TB (file attachments, expandable)

### Database Sizing Guide
- Base installation: ~500 MB
- Per year of active use (50 users): ~2-5 GB database, 10-50 GB file attachments
- Audit log grows ~1 MB per 1,000 audit events; plan for significant audit trail volume in active sites

---

## 3. Pre-Installation Checklist

Before beginning installation, confirm:

- [ ] Server OS: Ubuntu 22.04 LTS or RHEL 9 installed and updated
- [ ] Static IP address assigned to the server
- [ ] DNS record created: `pharolon.yoursite.com` pointing to the server IP
- [ ] TLS certificate available (Let's Encrypt, internal CA, or commercial cert)
- [ ] Outbound SMTP access available (port 587 or 25)
- [ ] Firewall rules: ports 80 and 443 open inbound; 5432 and 6379 closed externally
- [ ] Sudo or root access to the server
- [ ] Git access to clone the PHAROLON repository

---

## 4. Automated Installation (Recommended)

The `install.sh` script handles all installation steps interactively.

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_ORG/pharolon.git /opt/pharolon-src
cd /opt/pharolon-src

# 2. Run the installer as root or with sudo
sudo bash scripts/install.sh
```

The installer prompts for:
- Site name and URL
- Database password
- SMTP server settings
- Initial administrator username and email
- TLS certificate paths (or Let's Encrypt auto-configuration)

Installation completes in approximately 10-20 minutes on a fresh server.

---

## 5. Manual Installation (Step by Step)

For environments where the automated installer cannot be used, follow these steps.

### 5.1 System Packages

**Ubuntu 22.04:**
```bash
sudo apt update && sudo apt upgrade -y

# Python, pip, venv
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# PostgreSQL 15
sudo apt install -y postgresql-15 postgresql-client-15 postgresql-15-pg-trgm

# Redis 7
sudo apt install -y redis-server

# Nginx
sudo apt install -y nginx

# Build tools and dependencies
sudo apt install -y build-essential libpq-dev libssl-dev libffi-dev \
                   curl git unzip ufw

# Optional: libldap for LDAP/AD integration
sudo apt install -y libldap2-dev libsasl2-dev
```

**RHEL 9:**
```bash
sudo dnf update -y

# Python 3.11
sudo dnf install -y python3.11 python3.11-devel

# Node.js 20
sudo dnf module install -y nodejs:20

# PostgreSQL 15
sudo dnf install -y postgresql15-server postgresql15-contrib
sudo postgresql-15-setup --initdb
sudo systemctl enable --now postgresql-15

# Redis 7
sudo dnf install -y redis
sudo systemctl enable --now redis

# Nginx
sudo dnf install -y nginx

# Build tools
sudo dnf install -y gcc gcc-c++ make openssl-devel libffi-devel \
                    libpq-devel git curl
```

### 5.2 PostgreSQL Setup

```bash
# Switch to postgres user
sudo -u postgres psql

-- Inside psql:
CREATE USER pharolon_app WITH PASSWORD 'CHANGE_THIS_STRONG_PASSWORD';
CREATE DATABASE pharolon OWNER pharolon_app;
\c pharolon
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
GRANT ALL PRIVILEGES ON DATABASE pharolon TO pharolon_app;

-- IMPORTANT: Create a read-only user for reporting/backup
CREATE USER pharolon_readonly WITH PASSWORD 'CHANGE_THIS_READONLY_PASSWORD';
GRANT CONNECT ON DATABASE pharolon TO pharolon_readonly;
GRANT USAGE ON SCHEMA public TO pharolon_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pharolon_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO pharolon_readonly;

\q
```

**Configure PostgreSQL authentication (`/etc/postgresql/15/main/pg_hba.conf`):**
```
# Add these lines (before the "local all all peer" line):
host    pharolon         pharolon_app     127.0.0.1/32            scram-sha-256
host    pharolon         pharolon_readonly 127.0.0.1/32           scram-sha-256
```

```bash
sudo systemctl restart postgresql
```

### 5.3 Redis Setup

```bash
# Edit /etc/redis/redis.conf:
# Bind to localhost only (security)
sudo sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf

# Set a password (recommended)
sudo sed -i 's/^# requirepass.*/requirepass CHANGE_THIS_REDIS_PASSWORD/' /etc/redis/redis.conf

# Disable dangerous commands (optional but recommended)
echo "rename-command FLUSHALL \"\"" | sudo tee -a /etc/redis/redis.conf
echo "rename-command FLUSHDB \"\"" | sudo tee -a /etc/redis/redis.conf
echo "rename-command CONFIG \"\"" | sudo tee -a /etc/redis/redis.conf

sudo systemctl enable --now redis-server
```

### 5.4 Application User and Directory

```bash
# Create dedicated system user
sudo useradd --system --shell /bin/bash --home /opt/pharolon --create-home pharolon

# Create directory structure
sudo mkdir -p /opt/pharolon/{app,media,logs,backups}
sudo chown -R pharolon:pharolon /opt/pharolon

# Create log directory for Nginx
sudo mkdir -p /var/log/pharolon
sudo chown pharolon:adm /var/log/pharolon
```

### 5.5 Application Installation

```bash
# Clone the repository
sudo -u pharolon git clone https://github.com/YOUR_ORG/pharolon.git /opt/pharolon/src

# Create Python virtual environment
sudo -u pharolon python3.11 -m venv /opt/pharolon/venv

# Install Python dependencies
sudo -u pharolon /opt/pharolon/venv/bin/pip install --upgrade pip
sudo -u pharolon /opt/pharolon/venv/bin/pip install -r /opt/pharolon/src/backend/requirements.txt

# Build frontend
cd /opt/pharolon/src/frontend
sudo -u pharolon npm ci
sudo -u pharolon npm run build
# Frontend build output: /opt/pharolon/src/frontend/dist/
```

### 5.6 Environment Configuration

```bash
# Create the environment file
sudo -u pharolon cp /opt/pharolon/src/config/.env.example /opt/pharolon/.env
sudo chmod 600 /opt/pharolon/.env
sudo chown pharolon:pharolon /opt/pharolon/.env

# Edit the environment file
sudo -u pharolon nano /opt/pharolon/.env
```

**Required environment variables in `/opt/pharolon/.env`:**

```bash
# ── Application ──────────────────────────────────────
APP_NAME=PHAROLON
APP_VERSION=1.0.0
APP_ENV=production
DEBUG=false
SITE_URL=https://pharolon.yoursite.com

# ── Security (GENERATE THESE - do not use these values) ──
SECRET_KEY=<64-character-random-string>
ENCRYPTION_KEY=<32-byte-base64-encoded-key>
JWT_ALGORITHM=HS256

# Generate SECRET_KEY with:
# python3 -c "import secrets; print(secrets.token_hex(64))"
# Generate ENCRYPTION_KEY with:
# python3 -c "import secrets, base64; print(base64.b64encode(secrets.token_bytes(32)).decode())"

# ── Database ─────────────────────────────────────────
DATABASE_URL=postgresql+asyncpg://pharolon_app:CHANGE_THIS_STRONG_PASSWORD@localhost/pharolon
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=40

# ── Redis ─────────────────────────────────────────────
REDIS_URL=redis://:CHANGE_THIS_REDIS_PASSWORD@localhost:6379/0
CELERY_BROKER_URL=redis://:CHANGE_THIS_REDIS_PASSWORD@localhost:6379/1
CELERY_RESULT_BACKEND=redis://:CHANGE_THIS_REDIS_PASSWORD@localhost:6379/2

# ── Email ─────────────────────────────────────────────
SMTP_HOST=mail.yoursite.com
SMTP_PORT=587
SMTP_USER=pharolon@yoursite.com
SMTP_PASSWORD=<email-password>
SMTP_FROM_ADDRESS=pharolon@yoursite.com
SMTP_FROM_NAME=PHAROLON
SMTP_USE_TLS=true

# ── File Storage ──────────────────────────────────────
MEDIA_ROOT=/opt/pharolon/media
MAX_UPLOAD_SIZE_MB=50
ALLOWED_EXTENSIONS=pdf,doc,docx,xls,xlsx,ppt,pptx,png,jpg,jpeg,gif,txt,csv,zip

# ── Logging ───────────────────────────────────────────
LOG_LEVEL=INFO
LOG_FILE=/opt/pharolon/logs/pharolon.log

# ── Session ───────────────────────────────────────────
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
SESSION_IDLE_TIMEOUT_MINUTES=30
SESSION_ABSOLUTE_TIMEOUT_HOURS=8
MAX_CONCURRENT_SESSIONS=3

# ── Security Settings ─────────────────────────────────
PASSWORD_MIN_LENGTH=12
PASSWORD_HISTORY_COUNT=12
LOGIN_MAX_ATTEMPTS=5
LOGIN_LOCKOUT_MINUTES=15
```

### 5.7 Database Initialization

```bash
# Run migrations
sudo -u pharolon /opt/pharolon/venv/bin/python -m alembic \
    --config /opt/pharolon/src/backend/alembic.ini upgrade head

# Load seed data
sudo -u pharolon /opt/pharolon/venv/bin/python \
    /opt/pharolon/src/scripts/seed_database.py

# Run schema Part 1 (DDL - if using raw SQL method)
sudo -u postgres psql -d pharolon -f /opt/pharolon/src/schema/pharolon_schema_part1.sql

# Run schema Part 2 (indexes, sequences, seed data)
sudo -u postgres psql -d pharolon -f /opt/pharolon/src/schema/pharolon_schema_part2.sql

# Create initial admin user
sudo -u pharolon /opt/pharolon/venv/bin/python \
    /opt/pharolon/src/scripts/create_admin.py \
    --username admin \
    --email admin@yoursite.com \
    --full-name "Site Administrator"
```

### 5.8 systemd Service Files

**`/etc/systemd/system/pharolon-api.service`:**
```ini
[Unit]
Description=PHAROLON API Server (Gunicorn + Uvicorn)
After=network.target postgresql.service redis.service
Requires=postgresql.service redis.service

[Service]
User=pharolon
Group=pharolon
WorkingDirectory=/opt/pharolon/src/backend
EnvironmentFile=/opt/pharolon/.env
ExecStart=/opt/pharolon/venv/bin/gunicorn \
    app.main:app \
    --workers 4 \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 127.0.0.1:8000 \
    --timeout 120 \
    --keepalive 5 \
    --access-logfile /opt/pharolon/logs/api-access.log \
    --error-logfile /opt/pharolon/logs/api-error.log \
    --log-level info
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**`/etc/systemd/system/pharolon-worker.service`:**
```ini
[Unit]
Description=PHAROLON Celery Worker
After=network.target redis.service
Requires=redis.service

[Service]
User=pharolon
Group=pharolon
WorkingDirectory=/opt/pharolon/src/backend
EnvironmentFile=/opt/pharolon/.env
ExecStart=/opt/pharolon/venv/bin/celery \
    -A app.core.celery_app worker \
    --loglevel=info \
    --concurrency=4 \
    --logfile=/opt/pharolon/logs/celery-worker.log
KillMode=mixed
TimeoutStopSec=10
PrivateTmp=true
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**`/etc/systemd/system/pharolon-beat.service`:**
```ini
[Unit]
Description=PHAROLON Celery Beat Scheduler
After=network.target redis.service
Requires=redis.service

[Service]
User=pharolon
Group=pharolon
WorkingDirectory=/opt/pharolon/src/backend
EnvironmentFile=/opt/pharolon/.env
ExecStart=/opt/pharolon/venv/bin/celery \
    -A app.core.celery_app beat \
    --loglevel=info \
    --logfile=/opt/pharolon/logs/celery-beat.log \
    --pidfile=/opt/pharolon/logs/celery-beat.pid
KillMode=mixed
TimeoutStopSec=10
PrivateTmp=true
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable pharolon-api pharolon-worker pharolon-beat
sudo systemctl start pharolon-api pharolon-worker pharolon-beat

# Verify all services running
sudo systemctl status pharolon-api pharolon-worker pharolon-beat
```

### 5.9 Nginx Configuration

**`/etc/nginx/sites-available/pharolon`:**
```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name pharolon.yoursite.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name pharolon.yoursite.com;

    # TLS Configuration
    ssl_certificate     /etc/ssl/certs/pharolon.yoursite.com.crt;
    ssl_certificate_key /etc/ssl/private/pharolon.yoursite.com.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache   shared:SSL:10m;
    ssl_stapling        on;
    ssl_stapling_verify on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'" always;

    # Logging
    access_log /var/log/pharolon/access.log;
    error_log  /var/log/pharolon/error.log;

    # Client upload size limit (match MAX_UPLOAD_SIZE_MB in .env)
    client_max_body_size 55M;

    # Serve React frontend (static files)
    root /opt/pharolon/src/frontend/dist;
    index index.html;

    # API reverse proxy to Gunicorn
    location /api/ {
        proxy_pass         http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 120;
        proxy_send_timeout 120;
    }

    # Media file serving (authenticated via API, served by Nginx for performance)
    location /media/ {
        internal;
        alias /opt/pharolon/media/;
    }

    # React Router: all other routes serve index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Never cache index.html
    location = /index.html {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```

```bash
# Enable site
sudo ln -sf /etc/nginx/sites-available/pharolon /etc/nginx/sites-enabled/pharolon
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Enable and start Nginx
sudo systemctl enable --now nginx
```

### 5.10 Firewall

```bash
# Ubuntu (UFW)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (redirects to HTTPS)
sudo ufw allow 443/tcp   # HTTPS

# Block direct database access (if not already blocked)
sudo ufw deny 5432/tcp
sudo ufw deny 6379/tcp

sudo ufw --force enable
sudo ufw status
```

---

## 6. Post-Installation Verification

Run the built-in installation verification:

```bash
sudo -u pharolon /opt/pharolon/venv/bin/python \
    /opt/pharolon/src/scripts/verify_installation.py
```

This script checks:
- [ ] All services running
- [ ] Database connectivity
- [ ] Redis connectivity
- [ ] Celery worker responsive
- [ ] SMTP connectivity
- [ ] Audit trail hash chain initialized
- [ ] Default roles and permissions present
- [ ] Seed data complete
- [ ] Nginx serving frontend
- [ ] API health endpoint responding

**Manual verification:**
```bash
# Check service status
systemctl status pharolon-api pharolon-worker pharolon-beat nginx postgresql redis-server

# Check API health
curl -s https://pharolon.yoursite.com/api/v1/health | python3 -m json.tool

# Check logs for errors
sudo journalctl -u pharolon-api --since "5 minutes ago"
sudo tail -50 /opt/pharolon/logs/api-error.log
```

---

## 7. Initial Configuration

After installation, log in as the admin user and complete:

1. **Organization and Site Setup**
   - Administration > Site Settings > Organization Info
   - Enter legal name, FDA establishment number if applicable

2. **SMTP Verification**
   - Administration > Email Templates > Test Email

3. **User Accounts**
   - Create accounts for all users
   - Assign roles appropriate to each user's function
   - Set `must_change_password = true` for all initial accounts

4. **LDAP/AD Integration (if applicable)**
   - Administration > Integrations > LDAP
   - Configure and test before disabling local accounts

5. **Department and Site Structure**
   - Administration > Site Settings > Departments

6. **Default Workflows**
   - Workflows > Workflow Builder > Import system templates

7. **Document Categories**
   - Documents > Categories > Configure numbering formats

---

## 8. Backup and Recovery

### Automated Backup Script

```bash
# Run backup manually to verify
sudo -u pharolon bash /opt/pharolon/src/scripts/backup.sh

# Schedule via cron (as pharolon user)
sudo crontab -u pharolon -e
# Add:
0 2 * * * /bin/bash /opt/pharolon/src/scripts/backup.sh >> /opt/pharolon/logs/backup.log 2>&1
```

The backup script:
1. Creates a PostgreSQL dump: `pg_dump pharolon | gzip`
2. Archives the media directory
3. Copies the `.env` file
4. Retains last 30 days of backups
5. Logs completion or failure

**Backup location:** `/opt/pharolon/backups/YYYY-MM-DD/`

### Recovery

```bash
# Restore database from backup
sudo -u pharolon bash /opt/pharolon/src/scripts/restore.sh \
    --backup-dir /opt/pharolon/backups/2026-04-06
```

---

## 9. Upgrade Procedure

```bash
# 1. Read the release notes for the new version
#    Pay attention to validation impact classification

# 2. Take a full backup before upgrading
sudo -u pharolon bash /opt/pharolon/src/scripts/backup.sh

# 3. Pull new version
cd /opt/pharolon/src
sudo -u pharolon git fetch --tags
sudo -u pharolon git checkout v1.2.3

# 4. Stop services
sudo systemctl stop pharolon-api pharolon-worker pharolon-beat

# 5. Update Python dependencies
sudo -u pharolon /opt/pharolon/venv/bin/pip install -r backend/requirements.txt

# 6. Run database migrations
sudo -u pharolon /opt/pharolon/venv/bin/python \
    -m alembic --config backend/alembic.ini upgrade head

# 7. Build new frontend
cd /opt/pharolon/src/frontend
sudo -u pharolon npm ci
sudo -u pharolon npm run build

# 8. Restart services
sudo systemctl start pharolon-api pharolon-worker pharolon-beat

# 9. Verify services healthy
sudo systemctl status pharolon-api pharolon-worker pharolon-beat
curl -s https://pharolon.yoursite.com/api/v1/health

# 10. Update site change control record per your site's upgrade SOP
```

---

## 10. Troubleshooting

### API Server Not Starting
```bash
# Check logs
sudo journalctl -u pharolon-api -n 100
sudo tail -100 /opt/pharolon/logs/api-error.log

# Common causes:
# - Wrong DATABASE_URL or DB not running
# - Missing environment variables in .env
# - Python dependency not installed
```

### Database Connection Errors
```bash
# Test connection as app user
sudo -u pharolon psql "postgresql://pharolon_app:password@localhost/pharolon" -c "SELECT 1"

# Check PostgreSQL is running
sudo systemctl status postgresql
```

### Celery Worker Not Processing Tasks
```bash
# Check worker status
sudo journalctl -u pharolon-worker -n 100

# Test Redis connection
redis-cli -a REDIS_PASSWORD PING
```

### Nginx 502 Bad Gateway
```bash
# API server not running or wrong port
sudo systemctl status pharolon-api
sudo ss -tlnp | grep 8000
```

---

*INSTALL-001 v1.0 - PHAROLON Bare Metal Installation Guide*
