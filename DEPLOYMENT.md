# Panduan Deployment VPS - hris.wowinapps.cloud

Dokumen ini berisi langkah-langkah lengkap untuk melakukan deployment aplikasi HRIS Wowin di VPS Linux menggunakan Docker dan Nginx.

## Prasyarat
Sebelum memulai, pastikan VPS Anda sudah terinstall:
- **Git**
- **Docker**
- **Docker Compose** (Versi terbaru)
- Domain **hris.wowinapps.cloud** sudah diarahkan (A Record) ke IP VPS Anda.

---

## Langkah 1: Persiapan Kode
Masuk ke VPS Anda dan clone repository (jika pertama kali) atau tarik update terbaru.

```bash
# Jika pertama kali
git clone <url-repository-anda> hris_wowin
cd hris_wowin

# Jika ingin update
git pull origin main
```

---

## Langkah 2: Konfigurasi Environment
Salin template environment dan sesuaikan nilai-nilainya.

```bash
cp .env.example .env
nano .env
```
**Penting:** Ubah `POSTGRES_PASSWORD` dan `JWT_SECRET` dengan nilai yang unik dan aman.

---

## Langkah 3: Inisialisasi SSL (HTTPS)
Jalankan script helper untuk mendapatkan sertifikat dari Let's Encrypt. Pastikan port 80 tidak sedang digunakan oleh aplikasi lain.

```bash
# Berikan izin eksekusi jika belum
chmod +x deploy/init-ssl.sh

# Jalankan script (Ganti email dengan email admin Anda)
./deploy/init-ssl.sh hris.wowinapps.cloud sofyannurrohman1@gmail.com
```
Script ini akan:
1. Menjalankan Nginx sementara.
2. Meminta sertifikat SSL melalui Certbot.
3. Menyimpan sertifikat di volume Docker.

---

## Langkah 4: Mengaktifkan SSL di Nginx
Setelah sertifikat berhasil didapatkan, Anda harus mengaktifkannya di konfigurasi Nginx.

1. Buka file konfigurasi:
   ```bash
   nano deploy/nginx/nginx.conf
   ```
2. Temukan baris berikut (sekitar baris 21-22) dan **hapus tanda komentar (`#`)**:
   ```nginx
   # Sebelum
   # ssl_certificate /etc/letsencrypt/live/hris.wowinapps.cloud/fullchain.pem;
   # ssl_certificate_key /etc/letsencrypt/live/hris.wowinapps.cloud/privkey.pem;

   # Sesudah
   ssl_certificate /etc/letsencrypt/live/hris.wowinapps.cloud/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/hris.wowinapps.cloud/privkey.pem;
   ```
3. Simpan dan keluar (`Ctrl+O`, `Enter`, `Ctrl+X`).

---

## Langkah 5: Menjalankan Aplikasi
Sekarang jalankan seluruh layanan menggunakan Docker Compose dalam mode background.

```bash
docker compose up -d --build
```
---
## Langkah 6: Verifikasi
Buka browser dan akses:
- **https://hris.wowinapps.cloud** (Frontend)
- **https://hris.wowinapps.cloud/api/v1/health** (Backend Health Check)
---
## Pemeliharaan (Maintenance)
### Melihat Log
Jika terjadi kendala, cek log kontainer:
```bash
docker compose logs -f
```
### Menghentikan Aplikasi
```bash
docker compose down
```
### Update Kode di Masa Depan
Jika ada update di repository:
```bash
git pull origin main
docker compose up -d --build
```
### Perpanjangan Sertifikat SSL
Sertifikat akan diperbarui secara otomatis setiap 12 jam oleh kontainer `hris_certbot`. Anda tidak perlu melakukan apa-apa secara manual.
