#!/bin/bash
#==============================================================================
# BACKUP SIMPLES DA VPS PARA GOOGLE DRIVE
#==============================================================================

# Configurações
BACKUP_NAME="backup-$(date +%Y-%m-%d_%H-%M)"
TEMP_DIR="/tmp/$BACKUP_NAME"
GDRIVE_DEST="gdrive:vps-backups"

echo "🔵 Iniciando backup: $BACKUP_NAME"

# Cria diretório temporário
mkdir -p "$TEMP_DIR"

# 1. Backup dos bancos PostgreSQL
echo "📦 Backup PostgreSQL..."
docker exec chatwoot-postgres-1 pg_dumpall -U postgres 2>/dev/null | gzip > "$TEMP_DIR/chatwoot-db.sql.gz" || echo "⚠️  PostgreSQL chatwoot falhou (continuando...)"
docker exec postgres_for_n8n pg_dumpall -U postgres 2>/dev/null | gzip > "$TEMP_DIR/n8n-db.sql.gz" || echo "⚠️  PostgreSQL n8n falhou (continuando...)"

# 2. Backup dos bancos MySQL
echo "📦 Backup MySQL..."
docker exec mautic_achadinhosdolar-db-1 sh -c 'mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases 2>/dev/null' | gzip > "$TEMP_DIR/mautic-db.sql.gz" || echo "⚠️  MySQL falhou (continuando...)"

# 3. Backup do /home (docker-compose, configs, etc)
echo "📦 Backup /home..."
tar -czf "$TEMP_DIR/home.tar.gz" /home

# 4. Backup dos volumes Docker
echo "📦 Backup volumes Docker..."
tar -czf "$TEMP_DIR/docker-volumes.tar.gz" /var/lib/docker/volumes

# 5. Upload para Google Drive
echo "☁️  Upload para Google Drive..."
rclone copy "$TEMP_DIR" "$GDRIVE_DEST/$BACKUP_NAME" --progress

# 6. Remove backups antigos (mantém 30 dias)
echo "🗑️  Limpando backups antigos..."
rclone delete "$GDRIVE_DEST" --min-age 30d

# 7. Limpa temporários
rm -rf "$TEMP_DIR"

echo "✅ Backup concluído: $GDRIVE_DEST/$BACKUP_NAME"
