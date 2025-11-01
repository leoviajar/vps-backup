#!/bin/bash
#==============================================================================
# RESTAURAR BACKUP DA VPS
#==============================================================================

# Lista backups disponíveis
echo "📋 Backups disponíveis:"
rclone lsf gdrive:vps-backups --dirs-only

echo ""
read -p "Digite o nome do backup para restaurar: " BACKUP_NAME

TEMP_DIR="/tmp/restore-$BACKUP_NAME"
mkdir -p "$TEMP_DIR"

# Download do backup
echo "⬇️  Baixando backup..."
rclone copy "gdrive:vps-backups/$BACKUP_NAME" "$TEMP_DIR" --progress

echo ""
echo "⚠️  ATENÇÃO: Todos os containers serão parados e dados substituídos!"
read -p "Confirme digitando 'SIM' em maiúsculas: " CONFIRM

if [ "$CONFIRM" != "SIM" ]; then
    echo "❌ Restauração cancelada"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Para APENAS os apps (mantém DBs rodando para restore)
echo "⏸️  Parando aplicações..."
docker ps --format '{{.Names}}' | grep -v postgres | grep -v mysql | grep -v redis | xargs -r docker stop

# Aguarda 5s
sleep 5

# Restaura bancos PostgreSQL (com containers rodando)
echo "📥 Restaurando PostgreSQL..."
gunzip < "$TEMP_DIR/chatwoot-db.sql.gz" | docker exec -i chatwoot-postgres-1 psql -U postgres
gunzip < "$TEMP_DIR/n8n-db.sql.gz" | docker exec -i postgres_for_n8n psql -U postgres
gunzip < "$TEMP_DIR/tracking-db.sql.gz" | docker exec -i tracking-api_postgres_1 psql -U tracking_user

# Restaura bancos MySQL (com container rodando)
echo "📥 Restaurando MySQL..."
gunzip < "$TEMP_DIR/mautic-db.sql.gz" | docker exec -i mautic_achadinhosdolar-db-1 sh -c 'mysql -u root -p"$MYSQL_ROOT_PASSWORD"'

# Agora para TUDO para restaurar volumes
echo "⏸️  Parando todos os containers..."
docker stop $(docker ps -q)

# Aguarda containers pararem
sleep 10

# Restaura volumes Docker
echo "📥 Restaurando volumes Docker..."
tar -xzf "$TEMP_DIR/docker-volumes.tar.gz" -C /

# Restaura /home
echo "📥 Restaurando /home..."
tar -xzf "$TEMP_DIR/home.tar.gz" -C /

# Reinicia TUDO
echo "▶️  Reiniciando todos os containers..."

# Cria rede do Traefik primeiro (necessária para outros containers)
docker network create traefik_network 2>/dev/null || true

# Sobe Traefik primeiro
cd /home/traefik && docker-compose up -d
sleep 5

# Sobe os demais
cd /home/chatwoot && docker-compose up -d
cd /home/n8n && docker-compose up -d
cd /home/mautic-achadinhos && docker-compose up -d
cd /home/gtm-achadinhos && docker-compose up -d
cd /home/tracking-api && docker-compose up -d

# Aguarda containers iniciarem
sleep 10

echo ""
echo "✅ Restauração concluída!"
echo ""
echo "🔍 Verificando containers:"
docker ps --format 'table {{.Names}}\t{{.Status}}'

# Limpa
rm -rf "$TEMP_DIR"
