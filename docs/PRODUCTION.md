# PRODUCTION RUNBOOK (Baseline)

## 1) Arsitektur layanan

- Publik hanya `nginx` pada port `80/443`.
- Service internal (`cwmp`, `nbi`, `fs`, `ui`, `mongo`, `redis`) berada di jaringan Docker internal.
- Nginx meneruskan trafik berbasis host:
  - `acs.shezanet.net` -> `genieacs-cwmp:7547`
  - `ui.shezanet.net` -> `genieacs-ui:3000`
  - `nbi.shezanet.net` -> `genieacs-nbi:7557`
  - `fs.shezanet.net` -> `genieacs-fs:7567`

## 2) Prasyarat Ubuntu

- Ubuntu 22.04/24.04 LTS
- DNS A/AAAA record untuk host di atas ke IP publik server
- Wildcard cert `*.shezanet.net` + chain (recommended)
- Firewall terbuka untuk 80/443 (dan port admin hanya dari trusted IP)

## 3) Install Docker + Compose plugin

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

Logout/login ulang setelah `usermod`.

## 4) Bootstrap `.env`

```bash
cp .env.example .env
```

Wajib diubah:
- `GENIEACS_UI_PASSWORD`
- `GENIEACS_UI_JWT_SECRET`
- `MONGO_ROOT_PASSWORD`
- `GENIEACS_MONGODB_CONNECTION_URL` (pastikan sesuai credential `.env`)

## 5) Deploy

```bash
docker compose pull
docker compose up -d
docker compose ps
```

## 6) Verifikasi health

```bash
./scripts/healthcheck.sh
# atau jika self-signed
INSECURE_TLS=true ./scripts/healthcheck.sh
```

Tambahan verifikasi:
```bash
docker compose logs --tail=100 nginx
docker compose logs --tail=100 genieacs-cwmp
```

## 7) Rolling restart

```bash
docker compose up -d --no-deps --force-recreate genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
```

## 8) Backup dan restore MongoDB

### Backup
```bash
RETENTION_DAYS=7 ./scripts/backup-mongo.sh
```

Contoh cron harian (jam 02:15):
```bash
crontab -e
15 2 * * * cd /path/to/genieacs-auto && ./scripts/backup-mongo.sh >> /var/log/genieacs-backup.log 2>&1
```

### Restore (manual)
```bash
gzip -dc backups/mongo/<file>.archive.gz | docker compose exec -T mongo mongorestore \
  --username "$MONGO_ROOT_USERNAME" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --archive --gzip
```

## 9) Update procedure

1. `docker compose pull`
2. `docker compose up -d`
3. Verifikasi `./scripts/healthcheck.sh`
4. Cek log error 10-15 menit pertama

## 10) Rollback dasar

- Simpan versi image yang sebelumnya dipakai.
- Pin tag image di `docker-compose.yml`, lalu:
  ```bash
  docker compose pull
  docker compose up -d
  ```
- Restore backup Mongo jika terjadi inkonsistensi data.

## Asumsi baseline

- Semua host `*.shezanet.net` mengarah ke server ini.
- ONT dapat menjangkau `https://acs.shezanet.net` dari jaringan operasional.
- Operational monitoring lanjutan (metrics/alerting) ditambahkan terpisah sesuai kebutuhan NOC.
