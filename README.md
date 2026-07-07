# Instalasi Bot WhatsApp (Notifikasi & Cek ID)

Salin dan tempel perintah di bawah ini ke terminal VPS Anda (sebagai **root**) untuk memulai instalasi:

```bash
wget -qO- https://raw.githubusercontent.com/tendostore/Cek-ID-Saluran-Group-WhatsApp/main/install.sh | bash
```

## 🚀 Tentang Script Ini

Script ini adalah penginstal otomatis untuk Bot WhatsApp yang menggunakan library [@whiskeysockets/baileys](https://github.com/WhiskeySockets/Baileys). Bot ini dirancang untuk berjalan di VPS sebagai layanan latar belakang (daemon) menggunakan PM2 agar tetap aktif 24/7, dan menyediakan REST API sederhana untuk mengirim notifikasi WhatsApp dari sistem lain.

## 🌟 Fitur Utama

- **Instalasi Sekali Klik** — Mengotomatiskan instalasi Node.js v20, PM2, dan semua dependensi sistem tanpa interaksi manual.
- **Pairing Code** — Login tanpa scan QR, cukup masukkan nomor HP dan input kode 8-digit yang muncul di terminal ke aplikasi WhatsApp Anda.
- **Penyimpanan ID Otomatis** — Mendeteksi dan menyimpan ID Saluran (`@newsletter`) dan ID Grup (`@g.us`) secara otomatis ke dalam file JSON di folder `data/`.
- **REST API Terproteksi** — Kirim notifikasi pesan teks ke WhatsApp secara terprogram melalui endpoint HTTP POST, diamankan dengan API key unik yang digenerate otomatis saat instalasi.
- **Auto-Reconnect dengan Backoff** — Jika koneksi WhatsApp terputus, bot mencoba menyambung kembali secara bertahap (exponential backoff, maksimum 60 detik) agar tidak membanjiri server saat terjadi gangguan.
- **Menu Management** — Antarmuka menu interaktif di terminal untuk cek log, daftar ID, lihat API key, login ulang, hingga uninstall bersih.

## 📋 Persyaratan Sistem

- **OS:** Ubuntu atau Debian (direkomendasikan versi terbaru).
- **Akses:** User **root** (script akan otomatis berhenti jika dijalankan tanpa akses root).
- **Port:** Pastikan port **3000** terbuka jika ingin mengakses API secara publik/dari luar VPS.

## 📱 Cara Penggunaan

Setelah proses instalasi selesai, Anda dapat mengelola bot kapan saja dengan mengetik perintah berikut di terminal:

```bash
menu
```

### Menu yang Tersedia

| No | Menu | Keterangan |
|----|------|------------|
| 1 | Login WhatsApp (Pairing Code) | Masukkan nomor HP untuk mendapatkan kode pairing |
| 2 | Cek ID Saluran WhatsApp | Menampilkan daftar ID saluran yang terdeteksi |
| 3 | Cek ID Group WhatsApp | Menampilkan daftar ID grup yang terdeteksi |
| 4 | Cek Status Bot (Logs) | Menampilkan log PM2 terbaru |
| 5 | Tampilkan API Key | Menampilkan API key untuk endpoint `/send-notification` |
| 6 | Hapus Semua Script (Uninstall Bersih) | Menghapus bot, proses PM2, dan direktori proyek |
| 7 | Keluar | Menutup menu |

### Panduan Langkah-Demi-Langkah

1. **Login WhatsApp** — Pilih menu **nomor 1**, masukkan nomor HP (contoh: `628123456789`). Buka WhatsApp di HP → **Perangkat Tertaut** → **Tautkan Perangkat** → **Tautkan dengan nomor telepon**, lalu masukkan kode yang muncul di terminal.
2. **Mendapatkan ID** — Setelah terhubung, kirimkan satu pesan teks ke saluran atau grup yang ingin Anda ambil ID-nya.
3. **Cek Daftar ID** — Pilih menu **nomor 2** untuk Saluran atau **nomor 3** untuk Grup guna melihat daftar ID yang berhasil ditangkap.
4. **Monitoring** — Pilih menu **nomor 4** untuk melihat log aktivitas bot (status koneksi dan riwayat pesan).
5. **Ambil API Key** — Pilih menu **nomor 5** untuk melihat API key yang dibutuhkan saat memanggil endpoint API.

## 📡 Integrasi API (Kirim Notifikasi)

Anda bisa mengirim pesan secara otomatis dari script eksternal atau aplikasi lain menggunakan endpoint API bot. Endpoint ini **dilindungi API key** — setiap request wajib menyertakan header `x-api-key` yang cocok dengan key yang dibuat otomatis saat instalasi (bisa dilihat lewat menu **nomor 5** atau file `/root/wa-notif-bot/apikey.txt`).

**Endpoint:** `http://IP_VPS_ANDA:3000/send-notification`
**Method:** `POST`
**Headers:**

```
Content-Type: application/json
x-api-key: <API_KEY_ANDA>
```

**Body (JSON):**

```json
{
  "target_id": "120363284729102@newsletter",
  "pesan": "Halo! Ini adalah notifikasi otomatis."
}
```

**Contoh dengan `curl`:**

```bash
curl -X POST http://IP_VPS_ANDA:3000/send-notification \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY_ANDA>" \
  -d '{"target_id": "120363284729102@g.us", "pesan": "Halo dari API!"}'
```

**Respons sukses:**

```json
{ "status": true, "message": "Notifikasi berhasil dikirim." }
```

**Respons jika API key salah/tidak ada:**

```json
{ "status": false, "message": "Unauthorized. Header x-api-key tidak valid." }
```

## 🔒 Keamanan

- Endpoint `/send-notification` **wajib** menyertakan header `x-api-key` yang valid; request tanpa key yang cocok akan ditolak (`401 Unauthorized`).
- File `apikey.txt` disimpan dengan permission `600` (hanya bisa dibaca oleh root).
- Disarankan untuk **tidak membuka port 3000 ke publik** kecuali diperlukan — gunakan firewall (`ufw`) atau reverse proxy (nginx) dengan HTTPS jika API akan diakses dari luar VPS.
- Sesi login WhatsApp (`auth_info_baileys`) bersifat sensitif — jangan bagikan folder ini ke siapa pun.

## 🗑️ Uninstall

Untuk menghapus bot beserta seluruh datanya, jalankan `menu` lalu pilih **nomor 6**. Proses ini akan:

- Menghentikan dan menghapus proses PM2 (`wa-notif-bot`)
- Menghapus direktori proyek `/root/wa-notif-bot` (termasuk sesi login dan API key)
- Menghapus command `menu` dari sistem

> Catatan: Uninstall ini tidak menghapus Node.js/PM2 dari sistem, hanya bot dan datanya.

## ⚠️ Disclaimer

Proyek ini menggunakan library tidak resmi ([Baileys](https://github.com/WhiskeySockets/Baileys)) untuk terhubung ke WhatsApp. Gunakan dengan bijak dan sesuai [Ketentuan Layanan WhatsApp](https://www.whatsapp.com/legal/terms-of-service). Risiko pemblokiran nomor sepenuhnya menjadi tanggung jawab pengguna.
