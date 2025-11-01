# 🛡️ Sistema de Backup VPS

Backup automático da VPS para Google Drive com restore completo.

## 📋 Arquivos

- **backup.sh** - Backup diário automático (roda às 3h da manhã)
- **restore.sh** - Restaura backup completo

## 🚀 Como Restaurar em VPS Nova

### 1. Instalar dependências

```bash
# Atualizar sistema
apt update && apt upgrade -y

# Instalar Docker + Docker Compose
apt install docker.io docker-compose -y

# Instalar rclone
curl https://rclone.org/install.sh | bash
```

### 2. Configurar rclone

```bash
rclone config

# Escolher:
# n) New remote
# Nome: gdrive
# Storage: drive (Google Drive)
# client_id: (deixar vazio)
# client_secret: (deixar vazio)
# scope: 1 (Full access)
# Seguir autenticação OAuth no navegador
```

### 3. Baixar scripts do repositório

```bash
# Na VPS
cd /root
git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git backup-vps
cd backup-vps
chmod +x *.sh
```

### 4. Executar restore

```bash
./restore.sh

# Escolher o backup desejado
# Confirmar com: SIM
```

### 5. Reconfigurar cron (após restore)

```bash
crontab -e

# Adicionar linha:
0 3 * * * /root/backup.sh >> /var/log/backup.log 2>&1
```

## 📦 O que é Backup

- ✅ Todos os bancos de dados (PostgreSQL + MySQL)
- ✅ Todos os volumes Docker
- ✅ Todas as configurações em /home
- ✅ Compactado (~360MB)
- ✅ Enviado para Google Drive
- ✅ Mantidos últimos 30 dias

## ⚙️ Containers Incluídos

- Traefik (reverse proxy)
- Chatwoot (4 containers)
- N8N (3 containers)
- Mautic (5 containers)
- GTM Server (2 containers)

**Total: 15 containers**

##  Ver Logs

```bash
# Logs de backup
tail -f /var/log/backup.log

# Ver backups no Google Drive
rclone lsf gdrive:vps-backups --dirs-only
```

## ⏱️ Tempo de Execução

- **Backup**: ~30 segundos
- **Restore completo**: ~2 minutos

---

**Sistema testado em cenário de desastre total!** ✅
