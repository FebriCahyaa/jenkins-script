#!/bin/bash

# Script ini dikembangkan oleh FebriCahyaa <febricahya12345@gmail.com>
# Hak Cipta © 2023 FebriCahyaa. Seluruh hak cipta dilindungi oleh undang-undang.
# Dilepaskan di bawah Lisensi MIT.

# Telegram Bot Token dan Chat ID (gantilah dengan informasi bot dan chat ID kamu)
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"

# Informasi SourceForge SFTP (gantilah dengan informasi akun kamu)
SF_USERNAME="your_sf_username"
SF_PASSWORD="your_sf_password"
SF_HOST="frs.sourceforge.net"
SF_REMOTE_DIR="/home/frs/project/your_project_name"

# Fungsi untuk mengirim pesan ke Telegram
function sendTelegramMessage() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$1" \
        --header "Content-Type: application/json"
}

# Fungsi untuk mengupdate progres dan mengirim notifikasi
function updateProgress() {
    sendTelegramMessage "Progres: $1%"
}

# Fungsi untuk menangkap output dan memperbarui log error
function captureError() {
    output=$("$@" 2>&1)
    sendTelegramMessage "Output: $output"
}

# Fungsi untuk membuat changelog
function createChangelog() {
    changelog=$(git log --pretty=format:"- %s" $(git describe --abbrev=0 --tags)..HEAD)
    sendTelegramMessage "Changelog:\n$changelog"
}

# Fungsi untuk menghitung waktu persentase
function calculateTimePercentage() {
    start_time=$1
    end_time=$2
    current_time=$3
    total_time=$(($end_time - $start_time))
    elapsed_time=$(($current_time - $start_time))
    percentage=$((elapsed_time * 100 / total_time))
    updateProgress $percentage
}

# Memulai waktu
start_time=$(date +%s)

# Meminta input nama direktori
read -p "Masukkan nama direktori: " dir_name

# Menghitung waktu untuk pembuatan direktori
mkdir_start_time=$(date +%s)

# Membuat directory /mnt/rizkyfebian dengan nama yang dimasukkan
mkdir -p "/mnt/rizkyfebian/$dir_name"

# Menghitung waktu selesai pembuatan direktori
mkdir_end_time=$(date +%s)

# Mengatur unmask
umask 0000

# Masuk ke directory yang baru dibuat
cd "/mnt/rizkyfebian/$dir_name"

# Mengirim notifikasi ke Telegram bahwa cloning repo init dimulai
sendTelegramMessage "Memulai cloning repo init..."
captureError repo init -u <URL_REPO_INIT> -b <BRANCH>

# Menghitung waktu untuk cloning repo init
repo_init_start_time=$(date +%s)

# Mengirim notifikasi ke Telegram bahwa syncing kode sumber dimulai
sendTelegramMessage "Memulai syncing kode sumber..."
captureError repo sync -j$(nproc)

# Menghitung waktu untuk syncing kode sumber
repo_sync_start_time=$(date +%s)

# Mengirim notifikasi ke Telegram bahwa cloning local_manifests dimulai
sendTelegramMessage "Memulai cloning local_manifests..."
captureError git clone <URL_LOCAL_MANIFESTS>

# Menghitung waktu selesai cloning local_manifests
repo_sync_end_time=$(date +%s)

# Mengirim notifikasi ke Telegram bahwa proses clone selesai
sendTelegramMessage "Proses clone selesai."

# Setup lingkungan build
source build/envsetup.sh

# Pilih perangkat yang ingin dibangun (ganti 'device' dengan nama perangkat yang sesuai)
lunch custom_device-userdebug

# Menghitung waktu untuk setup lingkungan build
build_setup_start_time=$(date +%s)

# Mengirim notifikasi ke Telegram bahwa proses build dimulai
sendTelegramMessage "Memulai proses build..."

# Contoh perintah build dengan update progres setiap langkah
updateProgress 25
# make clean
captureError make clean
updateProgress 50
# make -j$(nproc)
captureError make -j$(nproc)
updateProgress 75

# Menjalankan build dengan menggunakan 'm bacon -j$(nproc --all)'
captureError m bacon -j$(nproc --all)

# Pemeriksaan keberhasilan build
if [ -f "out/target/product/custom_device/custom_rom.zip" ]; then
    # ROM berhasil dibuat
    sendTelegramMessage "Build selesai! ROM berhasil dibuat. Membuat changelog..."

    # Menghitung waktu untuk membuat changelog
    changelog_start_time=$(date +%s)

    # Membuat dan mengirimkan changelog
    createChangelog

    # Memberikan lokasi checkout ROM
    rom_location="/mnt/rizkyfebian/$dir_name/out/target/product/custom_device/custom_rom.zip"
    sendTelegramMessage "Lokasi ROM: $rom_location"

    # Menghitung waktu untuk pengunggahan ke SourceForge
    sf_upload_start_time=$(date +%s)

    # Melakukan pengunggahan ke SourceForge
    sendTelegramMessage "Mengunggah ROM ke SourceForge..."
    echo "put out/target/product/custom_device/custom_rom.zip $SF_REMOTE_DIR" | sftp -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o PubkeyAuthentication=no -o User=$SF_USERNAME:$SF_PASSWORD $SF_HOST

    # Mendapatkan link SourceForge
    sf_link="https://sourceforge.net/projects/your_project_name/files/$dir_name/custom_rom.zip"
    
    # Mengirim link SourceForge ke Telegram
    sendTelegramMessage "Link SourceForge: $sf_link"

    # Menghitung waktu untuk pengunggahan ke GitHub Release
    gh_upload_start_time=$(date +%s)

    # Mendapatkan tag terbaru dari GitHub
    tag=$(git describe --abbrev=0 --tags)

    # Mengunggah ROM ke GitHub Release
    sendTelegramMessage "Mengunggah ROM ke GitHub Release..."
    gh release create $tag "$rom_location" -t "Versi $tag" -n "Deskripsi versi"
else
    # Build gagal
    sendTelegramMessage "Build gagal. Silakan periksa log untuk detailnya."
fi

# Menghitung waktu selesai proses build
build_end_time=$(date +%s)

# Menghitung waktu total
total_time=$(($build_end_time - $start_time))

# Menambahkan informasi hak cipta dan lisensi
sendTelegramMessage "Hak Cipta © 2023 FebriCahyaa. Seluruh hak cipta dilindungi oleh undang-undang."
sendTelegramMessage "Dilepaskan di bawah Lisensi MIT."

# Mengirim notifikasi ke Telegram bahwa proses build selesai
updateProgress 100
sendTelegramMessage "Proses build selesai. Total waktu: $total_time detik."
