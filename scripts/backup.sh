#!/usr/bin/env bash
# ============================================================
# OpenVAL Backup Script
# Usage: bash scripts/backup.sh [--dest /path/to/backup/dir]
# Schedule with cron: 0 2 * * * bash /opt/openval/src/scripts/backup.sh
# ============================================================
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/openval}"
BACKUP_BASE="${1:-$INSTALL_DIR/backups}"
DATE=$(date +%Y-%m-%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE/$DATE"
RETAIN_DAYS=30

info()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $1"; }
success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK]    $1"; }
error()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1"; exit 1; }

# Load env
[ -f "$INSTALL_DIR/.env" ] && export $(grep -v '^#' "$INSTALL_DIR/.env" | xargs)

info "Starting OpenVAL backup: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 1. Database backup
info "Backing up PostgreSQL database..."
DB_NAME=$(echo "$DATABASE_URL" | sed 's|.*//[^/]*/||' | sed 's|?.*||')
DB_HOST=$(echo "$DATABASE_URL" | sed 's|.*@||' | sed 's|/.*||' | sed 's|:.*||')
DB_USER=$(echo "$DATABASE_URL" | sed 's|.*//||' | sed 's|:.*||')

PGPASSWORD="$DB_PASSWORD" pg_dump \
    -h "${DB_HOST:-localhost}" \
    -U "$DB_USER" \
    -d "${DB_NAME:-openval}" \
    --format=custom \
    --compress=9 \
    --no-privileges \
    > "$BACKUP_DIR/database.pgdump"

success "Database backed up: $(du -sh "$BACKUP_DIR/database.pgdump" | cut -f1)"

# 2. Media files
info "Backing up media files..."
MEDIA_SIZE=$(du -sh "$INSTALL_DIR/media" 2>/dev/null | cut -f1 || echo "0")
if [ "$(du -sm "$INSTALL_DIR/media" 2>/dev/null | cut -f1)" -gt 0 ]; then
    tar -czf "$BACKUP_DIR/media.tar.gz" -C "$INSTALL_DIR" media/
    success "Media backed up: $MEDIA_SIZE"
else
    touch "$BACKUP_DIR/media.tar.gz"
    info "Media directory empty, created empty archive"
fi

# 3. Environment file (encrypted)
info "Backing up configuration..."
cp "$INSTALL_DIR/.env" "$BACKUP_DIR/.env.backup"
chmod 600 "$BACKUP_DIR/.env.backup"
success "Configuration backed up"

# 4. Create manifest
cat > "$BACKUP_DIR/MANIFEST.txt" <<EOF
OpenVAL Backup Manifest
=======================
Date:           $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Hostname:       $(hostname)
OpenVAL Version: $(cat "$INSTALL_DIR/src/backend/app/__version__.py" 2>/dev/null || echo "unknown")
Database:       ${DB_NAME:-openval}
Files:
  database.pgdump  $(du -sh "$BACKUP_DIR/database.pgdump" | cut -f1)
  media.tar.gz     $(du -sh "$BACKUP_DIR/media.tar.gz" | cut -f1)
  .env.backup      present

Restore command:
  bash $INSTALL_DIR/src/scripts/restore.sh --backup-dir $BACKUP_DIR
EOF

success "Manifest created"

# 5. Create checksum
info "Computing checksums..."
cd "$BACKUP_DIR"
sha256sum database.pgdump media.tar.gz .env.backup > SHA256SUMS
success "Checksums recorded"

# 6. Cleanup old backups
info "Cleaning up backups older than $RETAIN_DAYS days..."
find "$BACKUP_BASE" -maxdepth 1 -type d -mtime "+$RETAIN_DAYS" -exec rm -rf {} + 2>/dev/null || true
BACKUP_COUNT=$(find "$BACKUP_BASE" -maxdepth 1 -type d | wc -l)
info "Retained $((BACKUP_COUNT - 1)) backups"

TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
success "Backup complete: $BACKUP_DIR ($TOTAL_SIZE total)"
