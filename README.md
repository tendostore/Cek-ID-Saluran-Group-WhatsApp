# Instalasi Bot WhatsApp (Notifikasi & Cek ID)

Salin dan tempel perintah di bawah ini ke terminal VPS Anda untuk memulai instalasi:
```bash
wget -qO- https://raw.githubusercontent.com/tendostore/Cek-ID-Saluran-Group-WhatsApp/main/install.sh | bash
```

## 🚀 Tentang Script Ini
Script ini adalah penginstal otomatis untuk Bot WhatsApp yang menggunakan library [@whiskeysockets/baileys](https://github.com/WhiskeySockets/Baileys). Bot ini dirancang untuk berjalan di VPS sebagai layanan latar belakang (daemon) menggunakan PM2 untuk memastikan bot tetap aktif 24/7.

### 🌟 Fitur Utama
* **Instalasi Sekali Klik:** Mengotomatiskan instalasi Node.js v20, PM2, dan semua dependensi sistem tanpa interaksi manual.
* **Pairing Code:** Login tanpa scan QR, cukup masukkan nomor HP dan input kode 8-digit yang muncul di terminal ke aplikasi WhatsApp Anda.
* **Penyimpanan ID Otomatis:** Mendeteksi dan menyimpan ID Saluran (`@newsletter`) dan ID Grup (`@g.us`) secara otomatis ke dalam file JSON di folder `data/`.
* **REST API:** Kirim notifikasi pesan teks ke WhatsApp secara terprogram melalui endpoint HTTP POST.
* **Menu Management:** Antarmuka menu interaktif di terminal untuk cek log, daftar ID, login ulang, hingga uninstall bersih.

## 📋 Persyaratan Sistem
* **OS:** Ubuntu atau Debian (Direkomendasikan versi terbaru).
* **Akses:** User Root atau akses Sudo.
* **Port:** Pastikan port **3000** terbuka jika ingin mengakses API secara publik.

## 📱 Cara Penggunaan
Setelah proses instalasi selesai, Anda dapat mengelola bot kapan saja dengan mengetik perintah berikut di terminal:

`menu`

### Panduan Langkah-Demi-Langkah:
1. **Login WhatsApp:** Pilih menu **nomor 1**, masukkan nomor HP (contoh: 628123456789). Buka WhatsApp di HP > Perangkat Tertaut > Tautkan Perangkat > Tautkan dengan nomor telepon, lalu masukkan kode yang muncul di terminal.
2. **Mendapatkan ID:** Setelah terhubung, kirimkan satu pesan teks ke saluran atau grup yang ingin Anda ambil ID-nya.
3. **Cek Daftar ID:** Pilih menu **nomor 2** untuk Saluran atau **nomor 3** untuk Grup guna melihat daftar ID yang berhasil ditangkap.
4. **Monitoring:** Pilih menu **nomor 4** untuk melihat log aktivitas bot (status koneksi dan riwayat pesan).

## 📡 Integrasi API (Kirim Notifikasi)
Anda bisa mengirim pesan secara otomatis dari script eksternal atau aplikasi lain menggunakan endpoint API bot:

**Endpoint:** `http://IP_VPS_ANDA:3000/send-notification`  
**Method:** `POST`  
**Headers:** `Content-Type: application/json`  
**Body (JSON):**
```json
{
  "target_id": "120363284729102@newsletter",
  "pesan": "Halo! Ini adalah notifikasi otomatis."
}
