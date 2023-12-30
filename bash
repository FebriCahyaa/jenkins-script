#!/bin/bash

# Skrip awalan untuk direktori /mnt/rizkyfebian/sup dan konfigurasi awal Telegram

# Membuat direktori (jika belum ada)
#mkdir -p /mnt/rizkyfebian/sus

# Pindah ke direktori yang baru dibuat
cd /mnt/rizkyfebian/sus

# Set umask ke 0000
umask 0000

# Konfigurasi awal Telegram
TELEGRAM_API_KEY="6946505231:AAH2L1QKhNWEBfJSDwZImGRhkEwfBLQzyy8"
TELEGRAM_CHAT_ID="-1002039884441"

# Nama file untuk log error, log keberhasilan, dan log saat pembangunan ROM dimulai
LOG_ERROR="error.log"
LOG_SUCCESS="success.log"
LOG_BUILD_START="build_start.log"

# Fungsi untuk mengirim pesan Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_API_KEY/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID&text=$message"
}

# Fungsi untuk mendapatkan waktu saat ini sesuai zona waktu Asia/Jakarta
get_current_time_asia_jakarta() {
    TZ=Asia/Jakarta date +"%Y-%m-%d %H:%M:%S"
}

# Fungsi untuk mencatat waktu awal pembangunan ROM
log_build_start() {
    BUILD_START_TIME=$(get_current_time_asia_jakarta)
    echo "🚀 Memulai proses membangun ROM pada $BUILD_START_TIME" >> "$LOG_BUILD_START"
}

# Fungsi untuk mencatat waktu selesai pembangunan ROM dan total waktu pembangunan
log_build_end() {
    BUILD_END_TIME=$(get_current_time_asia_jakarta)
    echo "🏁 Selesai membangun ROM pada $BUILD_END_TIME" >> "$LOG_BUILD_START"
    start_time_unix=$(date -d "$BUILD_START_TIME" +%s)
    end_time_unix=$(date -d "$BUILD_END_TIME" +%s)
    build_duration=$((end_time_unix - start_time_unix))
    build_duration_min=$((build_duration / 60))
    build_duration_sec=$((build_duration % 60))
    echo "⌛ Total waktu pembangunan: $build_duration_min menit $build_duration_sec detik" >> "$LOG_BUILD_START"
}

# Fungsi untuk membersihkan file-file yang tidak diperlukan setelah selesai membangun ROM
cleanup_after_build() {
    # Hapus direktori 'out'
    rm -rf out
}

# Mengirim pesan awal
send_telegram_message "Inisialisasi skrip telah selesai pada $(get_current_time_asia_jakarta). Memulai tugas..."

# Repo Initialization with Additional Link
REPO_URL="https://github.com/SuperiorExtended/manifest.git"
REPO_BRANCH="thirteen"

# Menggunakan backslash untuk melanjutkan ke baris berikutnya
repo init -u $REPO_URL -b $REPO_BRANCH

# Clone local manifest repository
git clone https://github.com/FebriCahyaa/local_manifest.git -b supext .repo/local_manifests

# Mengirim pesan sebelum repo sync
send_telegram_message "Repo initialization selesai. Memulai repo sync pada $(get_current_time_asia_jakarta)..."

# Repo Sync
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags 2>&1 | \
while IFS= read -r line; do
    if [[ $line == *"fatal"* || $line == *"error"* ]]; then
        send_telegram_message "Error: $line"
    fi
done

# Mengirim pesan setelah repo sync
send_telegram_message "Repo sync selesai pada $(get_current_time_asia_jakarta). Melanjutkan tugas..."

# Bagian build ROM
LUNCH="superior_lavender-userdebug"  # Sesuaikan dengan format yang sesuai dengan proyek Anda

# Memulai pembangunan ROM
send_telegram_message "🚀 Memulai proses membangun ROM ($LUNCH) pada $(get_current_time_asia_jakarta)..."
source build/envsetup.sh
lunch $LUNCH
make -j$(nproc --all) 2>&1 | \
while IFS= read -r line; do
    if [[ $line == *"error"* ]]; then
        send_telegram_message "❌ Error: $line"
    fi
done

# Mengecek apakah pembangunan berhasil atau tidak
if [ -f "out/target/product/lavender/system/build.prop" ]; then
    send_telegram_message "✅ Pembangunan ROM selesai pada $BUILD_END_TIME. ROM berhasil dibuat!"
    log_build_end
    cleanup_after_build
else
    send_telegram_message "❌ Pembangunan ROM gagal pada $BUILD_END_TIME. Cek log untuk detailnya."
fi
