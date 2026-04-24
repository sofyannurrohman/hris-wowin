# Panduan Deployment VPS - hris.wowinapps.cloud (Host Nginx)

Dokumen ini berisi langkah-langkah untuk melakukan deployment HRIS Wowin di VPS yang sudah memiliki Nginx (seperti aplikasi hrd-room).

## Prasyarat
- **Docker** & **Docker Compose**
- **Nginx** terinstall di host VPS (`apt install nginx`)
- **Certbot** terinstall di host VPS (`apt install certbot python3-certbot-nginx`)

---

## Langkah 1: Clone/Pull Kode
```bash
git pull origin main
```

---

## Langkah 2: Konfigurasi Docker Environment
```bash
cp .env.example .env
nano .env
```
Pastikan `VITE_API_BASE_URL=/api`.

---

## Langkah 3: Jalankan Aplikasi (Docker)
```bash
docker compose up -d --build
```
Aplikasi sekarang berjalan secara internal:
- Frontend: `http://127.0.0.1:3000`
- Backend: `http://127.0.0.1:8081`

---

## Langkah 4: Konfigurasi Nginx di VPS
Buat file konfigurasi baru di Nginx VPS Anda:

```bash
sudo nano /etc/nginx/sites-available/hris.wowinapps.cloud
```

Tempelkan konfigurasi berikut:
```nginx
server {
    listen 80;
    server_name hris.wowinapps.cloud;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8081/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /uploads/ {
        proxy_pass http://127.0.0.1:8081/uploads/;
        proxy_set_header Host $host;
    }
}
```

Aktifkan konfigurasi dan restart Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/hris.wowinapps.cloud /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Langkah 5: Setup SSL (HTTPS) menggunakan Certbot
Jalankan Certbot langsung di host VPS:

```bash
sudo certbot --nginx -d hris.wowinapps.cloud
```
Ikuti petunjuknya (pilih opsi 2 untuk redirect HTTP ke HTTPS).

---

## Langkah 6: Verifikasi
Akses **https://hris.wowinapps.cloud**.

---

## Pemeliharaan
- Cek log Docker: `docker compose logs -f`
- Update aplikasi: `git pull` -> `docker compose up -d --build`
