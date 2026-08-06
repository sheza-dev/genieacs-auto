# GACS-AUTO — GenieACS Multi-Instance Orchestrator

CLI manager untuk deploy, monitor, dan manage **multi-instance GenieACS (TR-069 ACS)** pada satu VPS, dengan integrasi **L2TP / WireGuard VPN** untuk konektivitas ONU lokal.

Fokus desainnya adalah **lebih stabil dan aman untuk lingkungan produksi**: isolasi instance, alokasi port otomatis, reverse proxy terpusat, SSL wildcard, backup-friendly layout, dan pemisahan file runtime/secrets agar tidak ikut ter-commit.

---

## ✨ Fitur

| Fitur | Deskripsi |
|---|---|
| **Multi-Instance** | Deploy banyak GenieACS instance di satu server, masing-masing terisolasi |
| **Auto Port Allocation** | Port CWMP/NBI/FS/UI dialokasikan otomatis tanpa bentrok |
| **Nginx Reverse Proxy** | Subdomain otomatis per instance (`acs-<nama>.domain.id`) |
| **Wildcard SSL/HTTPS** | SSL via Let's Encrypt + Cloudflare DNS-01 challenge |
| **L2TP / WireGuard VPN** | Otomatis buat konektivitas tunnel untuk ONU lokal |
| **ONU Route Management** | Auto routing subnet ONU agar ACS bisa summon/push perangkat |
| **Parameter Restore** | Restore provisions, virtual params, presets, UI config dari preset |
| **Version Support** | GenieACS Stable (v1.2) dan Latest (v1.3-dev) |
| **Pause/Unpause** | Freeze instance tanpa menghentikan container |
| **Activity Log** | Riwayat semua aksi dengan filter dan pencarian |
| **Production Baseline** | Layout file runtime terpisah, panduan backup, firewall, dan proteksi secrets |

---

## 🔐 Baseline Stabil & Aman untuk Produksi

Versi produksi disarankan mengikuti baseline berikut:

1. **Jalankan installer sebagai root, tetapi simpan secrets dengan permission ketat**
   - `chmod 600` untuk token Cloudflare, password VPN, dan config sensitif.
   - Jangan commit file runtime atau secrets ke Git.
2. **Gunakan reverse proxy tunggal**
   - Publikasikan hanya `80/443` untuk web.
   - Endpoint internal GenieACS tetap di jaringan lokal/container bila memungkinkan.
3. **Aktifkan firewall**
   - Allow hanya port yang dibutuhkan: `22`, `80`, `443`, dan port VPN yang dipakai.
4. **Pin versi source/image**
   - Gunakan source `stable` untuk produksi default.
   - Update `latest` hanya untuk staging/uji coba.
5. **Isolasi per instance**
   - Satu instance = satu direktori data + satu compose file + satu mapping port.
6. **Siapkan backup dan restore**
   - Backup `manager/config.conf`, direktori `instances/`, preset parameter, dan dump MongoDB.
7. **Aktifkan monitoring & health checks**
   - Pantau container, penggunaan CPU/RAM, status VPN, dan masa berlaku sertifikat.
8. **Simpan route secara persisten**
   - Route ONU harus otomatis dipulihkan saat reboot.

---

## 🏗️ Arsitektur

```text
┌─────────────────────────────────────────────────────────┐
│                        VPS (Cloud)                      │
│                                                         │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐            │
│  │ Instance1 │  │ Instance2 │  │ Instance3 │  ...      │
│  │ GenieACS  │  │ GenieACS  │  │ GenieACS  │           │
│  │ +MongoDB  │  │ +MongoDB  │  │ +MongoDB  │           │
│  └────┬──────┘  └────┬──────┘  └────┬──────┘            │
│       │              │              │                   │
│  ┌────┴──────────────┴──────────────┴────┐             │
│  │          Nginx Reverse Proxy          │             │
│  │       (SSL/HTTPS + Subdomains)        │             │
│  └───────────────────────────────────────┘             │
│                       │                                 │
│  ┌────────────────────┴──────────────────┐             │
│  │         L2TP / WireGuard VPN          │             │
│  │    172.16.101.1 (Server Gateway)      │             │
│  └────────┬───────────┬─────────────────┘             │
│           │           │                                 │
└───────────┼───────────┼─────────────────────────────────┘
            │           │
        VPN Tunnel  VPN Tunnel
            │           │
   ┌────────┴──┐  ┌─────┴──────┐
   │ MikroTik1 │  │ MikroTik2  │
   │172.16.101.│  │172.16.101. │
   │   10      │  │   11       │
   └─────┬─────┘  └─────┬──────┘
         │              │
    ┌────┴────┐    ┌────┴────┐
    │ONU/ONT  │    │ONU/ONT  │
    │10.50.x.x│    │192.168.x│
    └─────────┘    └─────────┘
```

---

## 📦 Instalasi

### Prasyarat

- **OS**: Ubuntu 24.04+ (atau Debian-based)
- **Docker & Docker Compose**
- **Git & Curl**: `apt install git curl`
- **Domain** dengan wildcard DNS record (`*.domain.id → IP VPS`)
- **Cloudflare API Token** untuk DNS-01 challenge

> Script sebaiknya mengecek root permission, dependency, konflik port, dan keberadaan file source sebelum deployment.

### Quick Start

```bash
git clone https://github.com/sheza-dev/genieacs-auto.git /home/docker/genieacs
cd /home/docker/genieacs/manager
chmod +x mostech-gacs.sh
sudo ./mostech-gacs.sh
```

---

## 🚀 Setup Pertama Kali (Fresh VPS)

Urutan aman untuk provisioning awal:

```text
┌─ 3. Services & Settings
│   ├─ 4. Setup GenieACS Source  ← Clone source stable/latest
│   ├─ 2. Install Services       ← Install VPN, Nginx, Certbot
│   └─ 1. Setup Domain & SSL     ← Konfigurasi domain + SSL
│
└─ 1. Manage Instance
    └─ 1. Install New Instance   ← Deploy GenieACS pertama
```

### Langkah detail

1. `Services & Settings` → `Setup GenieACS Source`
2. `Services & Settings` → `Install Services`
3. `Services & Settings` → `Setup Domain & SSL`
4. `Manage Instance` → `Install New Instance`

---

## 🎮 Penggunaan

```bash
cd /home/docker/genieacs/manager
sudo ./mostech-gacs.sh
```

### Main Menu

```text
╔══════════════════════════════════════════╗
║       MOSTECH GACS MANAGER v1.2         ║
║    GenieACS Multi-Instance Manager      ║
╚══════════════════════════════════════════╝

  Instances: 1  │  Domain: domain.id  │  SSL: Active
──────────────────────────────────────────
  1. Manage Instance
  2. View Activity Log
  3. Services & Settings
  0. Exit
```

### Manage Instance

```text
  1. Install New Instance
  2. Monitor Resources
  3. Pause / Unpause
  4. Uninstall Instance
  0. Back
```

### Services & Settings

```text
  VPN: Active  │  Nginx: Active  │  Certbot: Ready
  Domain: domain.id  │  SSL: Active
  Source Stable: Ready  │  Source Latest: Ready
──────────────────────────────────────────
  1. Setup Domain & SSL
  2. Install Services
  3. Uninstall Services
  4. Setup GenieACS Source
  0. Back
```

### Install Instance — Auto Flow

Saat install instance baru, manager sebaiknya otomatis:

- Alokasi port unik (CWMP/NBI/FS/UI)
- Build dan start container
- Generate Nginx proxy config
- Buat user VPN + password
- Prompt subnet ONU lalu tambahkan route
- Prompt restore parameter preset
- Tampilkan info koneksi dan panduan MikroTik

---

## 🔌 Konektivitas ONU via VPN

### Contoh MikroTik (L2TP Client)

```routeros
/interface l2tp-client add name=l2tp-out1 connect-to=<IP_VPS> \
  user=<username> ****** disabled=no

/ip firewall filter add chain=forward in-interface=l2tp-out1 \
  action=accept comment="Allow L2TP to LAN" place-before=0
/ip firewall filter add chain=forward out-interface=l2tp-out1 \
  action=accept comment="Allow LAN to L2TP" place-before=1
```

> **Penting:** rule VPN harus di atas rule drop/hotspot agar trafik ACS ke ONU tidak terblokir.

### ACS URL di OLT

```text
http://172.16.101.1:<PORT_CWMP>
```

---

## 📁 Struktur Direktori

```text
/home/docker/genieacs/
├── README.md
├── .gitignore
├── manager/
│   ├── mostech-gacs.sh
│   ├── config.conf
│   ├── log.txt
│   └── nginx/
├── instances/
│   └── <instance>/
│       ├── docker-compose.yml
│       └── .onu_subnet
└── source/
    ├── deploy/
    │   ├── stable/Dockerfile
    │   └── latest/Dockerfile
    ├── GACS-Ubuntu-22.04/
    │   └── parameter/
    ├── stable/
    └── latest/
```

### Catatan Struktur

- `manager/config.conf`, `manager/log.txt`, `instances/`, clone source, backup, dan file secret adalah **runtime artifacts**.
- File tersebut **tidak boleh ikut ter-commit** dan sudah dicakup dalam `.gitignore`.

---

## 🔐 Subdomain Pattern

| Service | Subdomain | Protocol |
|---|---|---|
| Web UI | `acs-<nama>.domain.id` | HTTPS |
| CWMP | `cwmp-<nama>.domain.id` | HTTP/HTTPS sesuai terminasi proxy |
| NBI | `nbi-<nama>.domain.id` | HTTP/HTTPS |
| FS | `fs-<nama>.domain.id` | HTTP/HTTPS |

---

## 🛡️ Rekomendasi Hardening Produksi

- Gunakan **GenieACS stable** sebagai default produksi.
- Batasi akses SSH dengan key-based auth dan nonaktifkan password login bila memungkinkan.
- Simpan token Cloudflare di file root-only, bukan hard-coded di script.
- Gunakan `restart: unless-stopped` dan healthcheck pada container.
- Pisahkan domain publik UI dan endpoint internal bila deployment mengizinkan.
- Backup database dan file konfigurasi sebelum upgrade source/instance.
- Audit log aktivitas install, uninstall, pause, restore, dan perubahan route.
- Pastikan renewal sertifikat otomatis dan lakukan reload Nginx tanpa downtime besar.

---

## 📝 Catatan

- **Root Required**: installer/manager dijalankan dengan `sudo`.
- **Dependency Auto-Check**: Docker, Git, Curl, Nginx, dan Certbot sebaiknya diverifikasi di awal.
- **Parameter Restore**: stable dapat restore collection lengkap; latest bisa skip config UI jika format berbeda.
- **Route Persistence**: route ONU perlu dipulihkan otomatis saat reboot.
- **Periodic Inform**: set interval 60 detik di OLT profile untuk near real-time management.

---

## 📌 Status Repository

Repository ini saat ini berfungsi sebagai baseline spesifikasi dan dokumentasi. Implementasi script manager, template deployment, dan automation runtime dapat ditambahkan bertahap dengan tetap menjaga prinsip:

- perubahan kecil dan terukur,
- default aman untuk produksi,
- tidak menyimpan secrets di Git,
- dan validasi tiap perubahan sebelum dipakai di VPS produksi.
