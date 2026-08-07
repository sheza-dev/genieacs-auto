# Multi-City dan MikroTik (Baseline Design)

## 1) Model konektivitas multi-kota

Dua pola umum:

1. **Public Internet langsung ke ACS pusat**
   - Tiap kota mengarahkan ONT ke `acs.shezanet.net`.
   - Sederhana, cepat implementasi.
   - Wajib hardening firewall + rate control.

2. **VPN/site-to-site ke NOC pusat**
   - Tiap site kota tunnel ke core/NOC.
   - Lebih terkontrol, cocok jika kebijakan keamanan ketat.
   - Butuh monitoring tunnel dan failover routing.

## 2) Minimum firewall/NAT requirement

- Izinkan inbound TCP 443 ke server ACS (via Nginx).
- Port 80 hanya untuk redirect/ACME challenge jika digunakan.
- Drop semua inbound lain dari internet secara default.
- Batasi akses UI/NBI dengan allowlist IP admin/NOC bila memungkinkan.

## 3) ONT dan server Ubuntu di belakang MikroTik yang sama

### Risiko umum

- **Hairpin NAT / NAT loopback** saat ONT mengakses FQDN publik yang resolve ke IP publik router yang sama.
- DNS lokal mengarah ke IP yang tidak sesuai jalur routing ONT.

### Pendekatan aman (template konseptual)

- Opsi A: gunakan DNS split-horizon (ONT resolve `acs.shezanet.net` ke IP internal server).
- Opsi B: aktifkan hairpin NAT terkontrol agar trafik kembali ke server internal.
- Tambahkan filter rule untuk hanya port perlu (443) dan source network sesuai desain.

Contoh konsep rule MikroTik (sesuaikan interface/list/address):

```routeros
/ip firewall nat
# dstnat: publik 443 ke server ACS internal
add chain=dstnat action=dst-nat protocol=tcp dst-port=443 in-interface-list=WAN to-addresses=<ACS_LAN_IP> to-ports=443 comment="ACS HTTPS"

# hairpin srcnat: client LAN menuju ACS via IP publik
add chain=srcnat action=masquerade protocol=tcp src-address=<LAN_SUBNET> dst-address=<ACS_LAN_IP> out-interface-list=LAN comment="Hairpin ACS"

/ip firewall filter
# allow established/related
add chain=forward action=accept connection-state=established,related
# allow ONT subnet to ACS:443
add chain=forward action=accept protocol=tcp src-address=<ONT_SUBNET> dst-address=<ACS_LAN_IP> dst-port=443
# drop invalid and deny by default
add chain=forward action=drop connection-state=invalid
```

> Template di atas bukan aturan baku ISP tunggal; sesuaikan dengan topologi, VLAN, dan kebijakan keamanan Anda.

## 4) Validasi jalur ONT -> ACS FQDN

Checklist:

- ONT resolve `acs.shezanet.net` ke IP yang benar (public/internal sesuai desain).
- Dari subnet ONT, `tcp/443` ke ACS dapat terhubung.
- Sertifikat TLS valid untuk hostname yang dipanggil ONT.
- CWMP Inform URL pada ONT menunjuk `https://acs.shezanet.net`.
- Log `genieacs-cwmp` menampilkan request Inform dari ONT.

## 5) Troubleshooting TR-069 umum

- ONT tidak inform:
  - cek DNS resolve ONT
  - cek firewall drop counter di MikroTik
  - cek route balik dari server ke subnet ONT
- TLS gagal:
  - cek chain/intermediate cert
  - pastikan CN/SAN mencakup hostname target
- Auth/provision gagal:
  - cek credential/parameter di provisioning GenieACS
  - cek log `cwmp` dan `nbi`
- Session putus-nyambung:
  - evaluasi timeout NAT, MTU VPN, packet loss antar-site
