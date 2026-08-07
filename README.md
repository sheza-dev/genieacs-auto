# genieacs-auto

Production-ready baseline deployment GenieACS di Ubuntu menggunakan Docker Compose untuk domain:

- ACS utama: `acs.shezanet.net`
- Wildcard: `*.shezanet.net`
- Email SSL: `shezant.official@gmail.com`

> Catatan: ini adalah **production-ready baseline**, bukan klaim “100% production ready”. Lakukan checklist verifikasi sebelum go-live.

## Komponen

- `genieacs-cwmp`
- `genieacs-nbi`
- `genieacs-fs`
- `genieacs-ui`
- `mongo`
- `redis`
- `nginx` (TLS termination + reverse proxy)

## Struktur penting

- `docker-compose.yml`
- `.env.example`
- `nginx/modes/production.conf`
- `nginx/modes/bootstrap-selfsigned.conf`
- `scripts/backup-mongo.sh`
- `scripts/healthcheck.sh`
- `docs/PRODUCTION.md`
- `docs/MULTI_CITY_AND_MIKROTIK.md`
- `docs/HARDENING.md`

## Quickstart dari nol

1. Clone repo ke Ubuntu server, lalu masuk folder repo.
2. Salin env:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` dan ganti semua placeholder secret.
4. Pilih mode TLS:
   - **Mode production cert tersedia** (direkomendasikan):
     - Pasang wildcard cert ke:
       - `nginx/certs/live/fullchain.pem`
       - `nginx/certs/live/privkey.pem`
     - Ganti default Nginx config:
       ```bash
       cp nginx/modes/production.conf nginx/conf.d/default.conf
       ```
   - **Mode bootstrap (self-signed)**:
     - Pastikan mode bootstrap aktif:
       ```bash
       cp nginx/modes/bootstrap-selfsigned.conf nginx/conf.d/default.conf
       ```
     - Generate cert self-signed:
       ```bash
       mkdir -p nginx/certs/bootstrap
       openssl req -x509 -nodes -newkey rsa:2048 -days 30 \
         -keyout nginx/certs/bootstrap/privkey.pem \
         -out nginx/certs/bootstrap/fullchain.pem \
         -subj "/CN=acs.shezanet.net"
       ```
5. Start stack:
   ```bash
   docker compose up -d
   ```
6. Verifikasi:
   ```bash
   docker compose ps
   ./scripts/healthcheck.sh
   ```
   Jika masih bootstrap cert, jalankan:
   ```bash
   INSECURE_TLS=true ./scripts/healthcheck.sh
   ```

## Endpoint default

- CWMP: `https://acs.shezanet.net`
- UI: `https://ui.shezanet.net`
- NBI: `https://nbi.shezanet.net`
- FS: `https://fs.shezanet.net`

## Operasional cepat

- Backup MongoDB:
  ```bash
  ./scripts/backup-mongo.sh
  ```
- Rolling restart:
  ```bash
  docker compose up -d --no-deps --force-recreate genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
  ```

Lihat runbook lengkap di `docs/`.
