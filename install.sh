#!/bin/bash

echo "=================================================="
echo "  Memulai Instalasi Bot WhatsApp (Notifikasi) "
echo "=================================================="

# 1. Update sistem & install dependency dasar
echo "[1/6] Memperbarui sistem dan menginstal dependensi dasar..."
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git jq

# 2. Install Node.js v20 & PM2
echo "[2/6] Menginstal Node.js v20 dan PM2..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g pm2

# 3. Setup Direktori Proyek & Folder Data
echo "[3/6] Menyiapkan direktori proyek di /root/wa-notif-bot..."
mkdir -p /root/wa-notif-bot/data
cd /root/wa-notif-bot

# 4. Membuat package.json
echo "[4/6] Membuat file konfigurasi package.json..."
cat << 'EOF' > package.json
{
  "name": "wa-notif-bot",
  "version": "1.1.0",
  "description": "WhatsApp Bot untuk Notifikasi Saluran & Grup dengan Pairing Code",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@whiskeysockets/baileys": "^6.7.5",
    "express": "^4.19.2",
    "pino": "^8.20.0"
  }
}
EOF

echo "Menginstal package NPM..."
npm install

# 5. Membuat file utama index.js (Full)
echo "[5/6] Membuat script utama index.js..."
cat << 'EOF' > index.js
const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const pino = require('pino');
const express = require('express');
const fs = require('fs');

const app = express();
app.use(express.json());
const PORT = 3000;

let sock;

// Fungsi untuk menyimpan ID ke file JSON
function saveId(filename, id) {
    const path = `./data/${filename}`;
    let data = [];
    if (fs.existsSync(path)) {
        try {
            data = JSON.parse(fs.readFileSync(path, 'utf8'));
        } catch (e) {
            data = [];
        }
    }
    
    // Cek apakah ID sudah ada
    if (!data.find(item => item.id === id)) {
        data.push({ id, detectedAt: new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' }) });
        fs.writeFileSync(path, JSON.stringify(data, null, 2));
    }
}

async function connectToWhatsApp() {
    const { state, saveCreds } = await useMultiFileAuthState('auth_info_baileys');
    const { version } = await fetchLatestBaileysVersion();

    // Membaca nomor HP dari config jika ada
    let phoneNumber = '';
    if (fs.existsSync('./config.json')) {
        try {
            const config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));
            phoneNumber = config.phoneNumber;
        } catch (e) {
            console.error('Gagal membaca config.json');
        }
    }

    sock = makeWASocket({
        version,
        logger: pino({ level: 'silent' }),
        printQRInTerminal: false, // Matikan QR untuk menggunakan Pairing Code
        auth: state,
        browser: ['Ubuntu', 'Chrome', '20.0.0'] // Konfigurasi browser agar pairing code bekerja
    });

    // Proses Pairing Code jika belum terdaftar dan ada nomor HP
    if (!sock.authState.creds.registered && phoneNumber) {
        setTimeout(async () => {
            try {
                // Menghilangkan karakter non-angka dari nomor HP
                const cleanNumber = phoneNumber.replace(/[^0-9]/g, '');
                const code = await sock.requestPairingCode(cleanNumber);
                console.log('\n================================================================');
                console.log(`🔐 KODE PAIRING ANDA: ${code}`);
                console.log('Silakan buka notifikasi WhatsApp di HP Anda dan masukkan kode ini.');
                console.log('================================================================\n');
            } catch (error) {
                console.error('\n❌ Gagal meminta kode pairing. Pastikan nomor HP benar dan gunakan format 62xxx.');
                console.error('Pesan Error:', error.message);
            }
        }, 3000);
    }

    sock.ev.on('connection.update', async (update) => {
        const { connection, lastDisconnect } = update;
        
        if (connection === 'close') {
            const shouldReconnect = lastDisconnect.error?.output?.statusCode !== DisconnectReason.loggedOut;
            console.log('Koneksi terputus. Menghubungkan kembali:', shouldReconnect);
            if (shouldReconnect) {
                connectToWhatsApp();
            } else {
                console.log('Sesi telah logout. Silakan login kembali melalui menu.');
            }
        } else if (connection === 'open') {
            console.log('\n✅ WhatsApp Berhasil Terhubung!');
            console.log('Bot siap mendeteksi ID Saluran dan Grup.\n');
        }
    });

    sock.ev.on('creds.update', saveCreds);

    // Listener untuk menangkap dan menyimpan ID Saluran & Grup otomatis
    sock.ev.on('messages.upsert', async m => {
        try {
            const msg = m.messages[0];
            if (!msg || !msg.key) return;
            
            const remoteJid = msg.key.remoteJid;
            
            // Deteksi Saluran (Newsletter)
            if (remoteJid && remoteJid.endsWith('@newsletter')) {
                saveId('channels.json', remoteJid);
            }
            
            // Deteksi Group
            if (remoteJid && remoteJid.endsWith('@g.us')) {
                saveId('groups.json', remoteJid);
            }
        } catch (error) {
            console.error('Error saat membaca pesan masuk:', error);
        }
    });
}

// Endpoint API REST untuk mengirim notifikasi
app.post('/send-notification', async (req, res) => {
    const { target_id, pesan } = req.body;
    
    if (!sock) {
        return res.status(500).json({ status: false, message: 'Bot WhatsApp belum terhubung.' });
    }
    
    if (!target_id || !pesan) {
        return res.status(400).json({ status: false, message: 'Parameter target_id dan pesan wajib dikirim.' });
    }

    try {
        await sock.sendMessage(target_id, { text: pesan });
        console.log(`[API] Berhasil mengirim notifikasi ke: ${target_id}`);
        res.json({ status: true, message: 'Notifikasi berhasil dikirim.' });
    } catch (error) {
        console.error('[API] Gagal mengirim pesan:', error);
        res.status(500).json({ status: false, message: 'Gagal mengirim pesan.', error: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`Server API berjalan di port ${PORT}`);
    connectToWhatsApp();
});
EOF

# 6. Membuat Shortcut Menu di Terminal
echo "[6/6] Membuat shortcut menu interaktif..."
cat << 'EOF' > /usr/local/bin/menu
#!/bin/bash

while true; do
    clear
    echo "========================================="
    echo "         MENU BOT WHATSAPP VPS           "
    echo "========================================="
    echo "1. Login WhatsApp (Pairing Code)"
    echo "2. Cek ID Saluran WhatsApp"
    echo "3. Cek ID Group WhatsApp"
    echo "4. Cek Status Bot (Logs)"
    echo "5. Hapus Semua Script (Uninstall Bersih)"
    echo "6. Keluar"
    echo "========================================="
    read -p "Pilih menu [1-6]: " pilihan

    case $pilihan in
        1)
            echo ""
            read -p "Masukkan Nomor HP Anda (Gunakan awalan 62, contoh: 628123456789): " nomer
            
            # Menyimpan nomor HP ke config
            echo "{\"phoneNumber\": \"$nomer\"}" > /root/wa-notif-bot/config.json
            
            # Menghapus sesi lama agar bisa login ulang
            rm -rf /root/wa-notif-bot/auth_info_baileys
            
            echo "Memulai ulang bot dan memproses kode pairing..."
            pm2 restart wa-notif-bot > /dev/null 2>&1
            
            echo "Menunggu kode dari server... (Silakan tunggu 5-10 detik)"
            sleep 8
            
            echo "=== LOG PAIRING CODE ==="
            # Menampilkan log PM2 untuk mendapatkan kode pairing
            pm2 logs wa-notif-bot --lines 20 --nostream
            echo "========================"
            echo "Jika kode belum muncul, tunggu sebentar lalu pilih menu nomor 4 (Cek Status Bot)."
            
            echo ""
            read -p "Tekan Enter untuk kembali ke menu..."
            ;;
        2)
            echo ""
            echo "=== DAFTAR ID SALURAN WHATSAPP ==="
            if [ -f /root/wa-notif-bot/data/channels.json ]; then
                cat /root/wa-notif-bot/data/channels.json | jq -r '.[] | "ID: \(.id)\nDitambahkan: \(.detectedAt)\n"'
            else
                echo "Belum ada ID Saluran yang terdeteksi."
                echo "Cara: Kirim 1 pesan ke saluran yang Anda kelola, lalu kembali ke menu ini."
            fi
            echo "=================================="
            read -p "Tekan Enter untuk kembali ke menu..."
            ;;
        3)
            echo ""
            echo "=== DAFTAR ID GROUP WHATSAPP ==="
            if [ -f /root/wa-notif-bot/data/groups.json ]; then
                cat /root/wa-notif-bot/data/groups.json | jq -r '.[] | "ID: \(.id)\nDitambahkan: \(.detectedAt)\n"'
            else
                echo "Belum ada ID Group yang terdeteksi."
                echo "Cara: Kirim 1 pesan ke grup WhatsApp Anda, lalu kembali ke menu ini."
            fi
            echo "================================"
            read -p "Tekan Enter untuk kembali ke menu..."
            ;;
        4)
            echo ""
            echo "=== STATUS & LOG BOT ==="
            pm2 logs wa-notif-bot --lines 30 --nostream
            echo ""
            read -p "Tekan Enter untuk kembali ke menu..."
            ;;
        5)
            echo ""
            read -p "⚠️ Anda yakin ingin MENGHAPUS SEMUA SCRIPT dan reset VPS ini? (y/n): " confirm
            if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                echo "Menghapus bot dari PM2..."
                pm2 delete wa-notif-bot
                pm2 save
                echo "Menghapus direktori proyek /root/wa-notif-bot..."
                rm -rf /root/wa-notif-bot
                echo "Menghapus command menu di terminal..."
                rm /usr/local/bin/menu
                echo "✅ Script berhasil dihapus bersih! Anda tidak perlu rebuild VPS."
                exit 0
            else
                echo "Penghapusan dibatalkan."
                sleep 2
            fi
            ;;
        6)
            clear
            exit 0
            ;;
        *)
            echo "Pilihan tidak valid, silakan pilih 1-6."
            sleep 2
            ;;
    esac
done
EOF

# Memberikan izin eksekusi pada shortcut menu
chmod +x /usr/local/bin/menu

# Menjalankan bot pertama kali dengan PM2
echo "Menjalankan Bot menggunakan PM2..."
pm2 start index.js --name "wa-notif-bot"
pm2 save
pm2 startup > /dev/null 2>&1

echo "=================================================="
echo " ✅ Instalasi Selesai! "
echo "=================================================="
echo "Ketik perintah: menu"
echo "Untuk membuka menu pengaturan WhatsApp."
echo "=================================================="
