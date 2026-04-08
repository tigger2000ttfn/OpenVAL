#!/usr/bin/env bash
# ============================================================
# OpenVAL Bare Metal Installer
# Supports: Ubuntu 22.04 LTS, Ubuntu 24.04 LTS, RHEL 9
# Run as root or with sudo: sudo bash scripts/install.sh
# ============================================================
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header()  { echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}\n"; }

# ── Requirements check ───────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run as root: sudo bash scripts/install.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="/opt/openval"
OPENVAL_USER="openval"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    error "Cannot detect OS. Supported: Ubuntu 22.04, Ubuntu 24.04, RHEL 9"
fi

info "Detected OS: $OS $OS_VERSION"

case "$OS" in
    ubuntu)
        [[ "$OS_VERSION" =~ ^(22|24) ]] || error "Ubuntu 22.04 or 24.04 required"
        PKG_MGR="apt"
        ;;
    rhel|rocky|almalinux)
        [[ "$OS_VERSION" =~ ^9 ]] || error "RHEL/Rocky/Alma 9 required"
        PKG_MGR="dnf"
        ;;
    *)
        error "Unsupported OS: $OS. Supported: Ubuntu 22.04+, RHEL 9"
        ;;
esac

header "OpenVAL Installation"
echo "  Install directory:  $INSTALL_DIR"
echo "  Project source:     $PROJECT_ROOT"
echo "  OS:                 $OS $OS_VERSION"
echo ""
read -p "Continue? [y/N] " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] || { info "Installation cancelled."; exit 0; }

# ── Collect configuration ────────────────────────────────────
header "Configuration"

read -p "Site URL (e.g. https://openval.yoursite.com): " SITE_URL
[[ -z "$SITE_URL" ]] && error "Site URL is required"

DOMAIN=$(echo "$SITE_URL" | sed 's|https://||' | sed 's|http://||' | sed 's|/.*||')
info "Domain: $DOMAIN"

read -p "Database password: " -s DB_PASSWORD; echo
[[ ${#DB_PASSWORD} -lt 16 ]] && error "Database password must be at least 16 characters"

read -p "Redis password: " -s REDIS_PASSWORD; echo
[[ ${#REDIS_PASSWORD} -lt 16 ]] && error "Redis password must be at least 16 characters"

read -p "SMTP host (e.g. mail.yoursite.com): " SMTP_HOST
read -p "SMTP port [587]: " SMTP_PORT; SMTP_PORT=${SMTP_PORT:-587}
read -p "SMTP username: " SMTP_USER
read -p "SMTP password: " -s SMTP_PASSWORD; echo
read -p "From email address: " SMTP_FROM

read -p "Initial admin username: " ADMIN_USERNAME
[[ -z "$ADMIN_USERNAME" ]] && error "Admin username is required"
read -p "Initial admin email: " ADMIN_EMAIL
[[ -z "$ADMIN_EMAIL" ]] && error "Admin email is required"
read -p "Initial admin full name: " ADMIN_NAME

read -p "TLS certificate path (or press Enter to configure manually later): " TLS_CERT
read -p "TLS certificate key path (or press Enter to configure manually later): " TLS_KEY

# ── System packages ──────────────────────────────────────────
header "Installing System Packages"

if [ "$PKG_MGR" = "apt" ]; then
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        python3.11 python3.11-venv python3.11-dev python3-pip \
        postgresql postgresql-client postgresql-contrib \
        redis-server \
        nginx \
        build-essential libpq-dev libssl-dev libffi-dev \
        libldap2-dev libsasl2-dev \
        git curl wget unzip \
        ufw \
        logrotate \
        clamav clamav-daemon 2>/dev/null || warn "ClamAV installation skipped"

    # Node.js 20 LTS
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
    apt-get install -y -qq nodejs
else
    dnf update -y -q
    dnf install -y -q \
        python3.11 python3.11-devel \
        postgresql15-server postgresql15-contrib postgresql15 \
        redis \
        nginx \
        gcc gcc-c++ make openssl-devel libffi-devel libpq-devel \
        openldap-devel \
        git curl wget unzip \
        firewalld \
        logrotate
    dnf module install -y -q nodejs:20
    postgresql-15-setup --initdb || true
fi

success "System packages installed"

# ── Create application user ──────────────────────────────────
header "Creating Application User"

if id "$OPENVAL_USER" &>/dev/null; then
    warn "User '$OPENVAL_USER' already exists"
else
    useradd --system --shell /bin/bash --home "$INSTALL_DIR" --create-home "$OPENVAL_USER"
    success "Created system user: $OPENVAL_USER"
fi

# ── Directory structure ──────────────────────────────────────
header "Creating Directory Structure"

mkdir -p "$INSTALL_DIR"/{media,logs,backups}
mkdir -p /var/log/openval

# Copy application files
cp -r "$PROJECT_ROOT" "$INSTALL_DIR/src"
chown -R "$OPENVAL_USER:$OPENVAL_USER" "$INSTALL_DIR"
chown "$OPENVAL_USER:adm" /var/log/openval

success "Directories created"

# ── PostgreSQL setup ─────────────────────────────────────────
header "Configuring PostgreSQL"

systemctl enable --now postgresql 2>/dev/null || \
systemctl enable --now postgresql-15 2>/dev/null || true

sleep 2

sudo -u postgres psql -c "
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'openval_app') THEN
            CREATE USER openval_app WITH PASSWORD '$DB_PASSWORD';
        END IF;
    END
    \$\$;" 2>/dev/null || true

sudo -u postgres psql -c "
    SELECT 'CREATE DATABASE openval OWNER openval_app'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'openval')
    \\gexec" 2>/dev/null || true

sudo -u postgres psql -d openval -c "
    CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";
    CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";
    CREATE EXTENSION IF NOT EXISTS \"pg_trgm\";
    GRANT ALL PRIVILEGES ON DATABASE openval TO openval_app;
    GRANT ALL ON SCHEMA public TO openval_app;" 2>/dev/null

success "PostgreSQL configured"

# ── Redis setup ──────────────────────────────────────────────
header "Configuring Redis"

REDIS_CONF="/etc/redis/redis.conf"
[ -f "/etc/redis.conf" ] && REDIS_CONF="/etc/redis.conf"

sed -i "s/^bind .*/bind 127.0.0.1/" "$REDIS_CONF" 2>/dev/null || true
grep -q "^requirepass" "$REDIS_CONF" && \
    sed -i "s/^requirepass.*/requirepass $REDIS_PASSWORD/" "$REDIS_CONF" || \
    echo "requirepass $REDIS_PASSWORD" >> "$REDIS_CONF"

systemctl enable --now redis-server 2>/dev/null || \
systemctl enable --now redis 2>/dev/null || true

success "Redis configured"

# ── Python environment ───────────────────────────────────────
header "Setting Up Python Environment"

sudo -u "$OPENVAL_USER" python3.11 -m venv "$INSTALL_DIR/venv"
sudo -u "$OPENVAL_USER" "$INSTALL_DIR/venv/bin/pip" install --quiet --upgrade pip
sudo -u "$OPENVAL_USER" "$INSTALL_DIR/venv/bin/pip" install --quiet \
    -r "$INSTALL_DIR/src/backend/requirements.txt"

success "Python environment ready"

# ── Frontend build ───────────────────────────────────────────
header "Building Frontend"

cd "$INSTALL_DIR/src/frontend"
sudo -u "$OPENVAL_USER" npm ci --silent
sudo -u "$OPENVAL_USER" npm run build --silent

success "Frontend built"

# ── Environment file ─────────────────────────────────────────
header "Creating Environment Configuration"

SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(64))")
ENCRYPTION_KEY=$(python3 -c "import secrets, base64; print(base64.b64encode(secrets.token_bytes(32)).decode())")

cat > "$INSTALL_DIR/.env" <<EOF
APP_NAME=OpenVAL
APP_VERSION=1.0.0
APP_ENV=production
DEBUG=false
SITE_URL=$SITE_URL
ALLOWED_HOSTS=$DOMAIN

LICENSE_KEY=

SECRET_KEY=$SECRET_KEY
ENCRYPTION_KEY=$ENCRYPTION_KEY
JWT_ALGORITHM=HS256

DATABASE_URL=postgresql+asyncpg://openval_app:$DB_PASSWORD@localhost/openval
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=40

REDIS_URL=redis://:$REDIS_PASSWORD@localhost:6379/0
CELERY_BROKER_URL=redis://:$REDIS_PASSWORD@localhost:6379/1
CELERY_RESULT_BACKEND=redis://:$REDIS_PASSWORD@localhost:6379/2

SMTP_HOST=$SMTP_HOST
SMTP_PORT=$SMTP_PORT
SMTP_USER=$SMTP_USER
SMTP_PASSWORD=$SMTP_PASSWORD
SMTP_FROM_ADDRESS=$SMTP_FROM
SMTP_FROM_NAME=OpenVAL
SMTP_USE_TLS=true

MEDIA_ROOT=$INSTALL_DIR/media
MAX_UPLOAD_SIZE_MB=50
ALLOWED_EXTENSIONS=pdf,doc,docx,xls,xlsx,ppt,pptx,png,jpg,jpeg,gif,webp,txt,csv,zip,xml,json

ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
SESSION_IDLE_TIMEOUT_MINUTES=30
SESSION_ABSOLUTE_TIMEOUT_HOURS=8
MAX_CONCURRENT_SESSIONS=3

PASSWORD_MIN_LENGTH=12
PASSWORD_HISTORY_COUNT=12
LOGIN_MAX_ATTEMPTS=5
LOGIN_LOCKOUT_MINUTES=15
MFA_REQUIRED_FOR_SIGNATURES=true

LOG_LEVEL=INFO
LOG_FILE=$INSTALL_DIR/logs/openval.log
LOG_FORMAT=json

CE_MAX_USERS=50
CE_MAX_SITES=1

GUNICORN_WORKERS=4
GUNICORN_TIMEOUT=120
CELERY_CONCURRENCY=4
EOF

chmod 600 "$INSTALL_DIR/.env"
chown "$OPENVAL_USER:$OPENVAL_USER" "$INSTALL_DIR/.env"

success "Environment file created"

# ── Database initialization ──────────────────────────────────
header "Initializing Database"

cd "$INSTALL_DIR/src/backend"
sudo -u "$OPENVAL_USER" env $(cat "$INSTALL_DIR/.env" | xargs) \
    "$INSTALL_DIR/venv/bin/python" -m alembic upgrade head

sudo -u "$OPENVAL_USER" env $(cat "$INSTALL_DIR/.env" | xargs) \
    "$INSTALL_DIR/venv/bin/python" scripts/seed_database.py

success "Database initialized"

# ── Create admin user ────────────────────────────────────────
header "Creating Administrator Account"

sudo -u "$OPENVAL_USER" env $(cat "$INSTALL_DIR/.env" | xargs) \
    "$INSTALL_DIR/venv/bin/python" scripts/create_admin.py \
    --username "$ADMIN_USERNAME" \
    --email "$ADMIN_EMAIL" \
    --full-name "$ADMIN_NAME"

success "Admin account created: $ADMIN_USERNAME"

# ── systemd services ─────────────────────────────────────────
header "Installing systemd Services"

cp "$INSTALL_DIR/src/config/openval-api.service"    /etc/systemd/system/
cp "$INSTALL_DIR/src/config/openval-worker.service" /etc/systemd/system/
cp "$INSTALL_DIR/src/config/openval-beat.service"   /etc/systemd/system/

# Replace INSTALL_DIR placeholder
sed -i "s|/opt/openval|$INSTALL_DIR|g" /etc/systemd/system/openval-*.service

systemctl daemon-reload
systemctl enable openval-api openval-worker openval-beat
systemctl start  openval-api openval-worker openval-beat

success "Services installed and started"

# ── Nginx configuration ───────────────────────────────────────
header "Configuring Nginx"

cp "$INSTALL_DIR/src/config/nginx.conf" /etc/nginx/sites-available/openval
sed -i "s/OPENVAL_DOMAIN/$DOMAIN/g" /etc/nginx/sites-available/openval

if [ -n "$TLS_CERT" ] && [ -f "$TLS_CERT" ]; then
    sed -i "s|/etc/ssl/certs/OPENVAL_DOMAIN.crt|$TLS_CERT|g" /etc/nginx/sites-available/openval
    sed -i "s|/etc/ssl/private/OPENVAL_DOMAIN.key|$TLS_KEY|g" /etc/nginx/sites-available/openval
else
    warn "TLS certificate not configured. Edit /etc/nginx/sites-available/openval before enabling HTTPS."
fi

ln -sf /etc/nginx/sites-available/openval /etc/nginx/sites-enabled/openval
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl enable --now nginx || warn "Nginx config test failed. Check /etc/nginx/sites-available/openval"

success "Nginx configured"

# ── Firewall ─────────────────────────────────────────────────
header "Configuring Firewall"

if command -v ufw &>/dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw deny  5432/tcp
    ufw deny  6379/tcp
    ufw --force enable
else
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

success "Firewall configured"

# ── Log rotation ─────────────────────────────────────────────
cat > /etc/logrotate.d/openval <<'LOGROTATE'
/opt/openval/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        systemctl kill -s USR1 openval-api 2>/dev/null || true
    endscript
}
LOGROTATE

success "Log rotation configured"

# ── Final verification ────────────────────────────────────────
header "Verification"

sleep 3

SERVICES_OK=true
for svc in openval-api openval-worker openval-beat nginx; do
    if systemctl is-active --quiet "$svc"; then
        success "$svc is running"
    else
        warn "$svc is NOT running. Check: sudo journalctl -u $svc -n 50"
        SERVICES_OK=false
    fi
done

# Test API health
sleep 2
if curl -sf "http://localhost:8000/api/v1/health" >/dev/null 2>&1; then
    success "API health check passed"
else
    warn "API health check failed. Check: sudo journalctl -u openval-api -n 50"
fi

# ── Summary ───────────────────────────────────────────────────
header "Installation Complete"

echo -e "${GREEN}${BOLD}"
echo "  OpenVAL has been installed!"
echo "${NC}"
echo "  URL:            $SITE_URL"
echo "  Admin user:     $ADMIN_USERNAME"
echo "  Install dir:    $INSTALL_DIR"
echo "  Logs:           $INSTALL_DIR/logs/"
echo "  Config:         $INSTALL_DIR/.env"
echo ""
echo "  Next steps:"
echo "  1. If TLS not configured: edit /etc/nginx/sites-available/openval"
echo "  2. Log in at $SITE_URL"
echo "  3. Complete site setup in Administration > Site Settings"
echo "  4. Run the bundled validation package: docs/validation_package/"
echo ""

if [ "$SERVICES_OK" = false ]; then
    warn "Some services failed to start. Check logs before proceeding."
fi

info "Run 'sudo bash scripts/verify_install.sh' to verify the installation."
