# HARDENING BASELINE

## 1) UFW baseline

Contoh minimal:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp        # batasi source IP bila bisa
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Jika memungkinkan, batasi SSH/UI/NBI hanya dari IP admin/NOC.

## 2) Pembatasan akses UI/NBI

Rekomendasi:

- Batasi `ui.shezanet.net` dan `nbi.shezanet.net` dengan allowlist IP.
- Tambahkan autentikasi tambahan di reverse proxy (basic auth/SSO) untuk UI/NBI.
- Jangan publikasikan MongoDB/Redis ke internet.

## 3) Least privilege

- Simpan secret hanya di `.env` lokal (jangan commit).
- Rotasi password admin, JWT secret, dan credential database secara periodik.
- Pisahkan akun operasional (read-only monitoring vs admin penuh) jika workflow mendukung.

## 4) Logging dan monitoring minimum

- Pantau log kontainer:
  - `docker compose logs -f nginx`
  - `docker compose logs -f genieacs-cwmp`
- Simpan backup Mongo terjadwal dan uji restore berkala.
- Buat alert minimal untuk:
  - endpoint healthcheck gagal
  - penggunaan disk tinggi
  - restart container berulang

## 5) Checklist verifikasi baseline

- [ ] Semua placeholder secret di `.env` sudah diganti.
- [ ] Sertifikat TLS valid terpasang (atau bootstrap hanya untuk sementara).
- [ ] Port publik hanya 80/443.
- [ ] Backup Mongo berjalan dan file backup tervalidasi.
- [ ] Healthcheck endpoint berhasil.
- [ ] Akses UI/NBI dibatasi sesuai kebijakan operasi.
