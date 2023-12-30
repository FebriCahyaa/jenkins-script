#!/bin/bash

# Skrip awalan untuk direktori /mnt/rizkyfebian/sup dan konfigurasi awal Telegram

# Mengahpus direktori yang sudah ada
rm -rf /mnt/rizkyfebian/sus

# Membuat direktori (jika belum ada)
mkdir -p /mnt/rizkyfebian/sus
cd /mnt/rizkyfebian/sus

# Set umask ke 0000
umask 0000

# Konfigurasi awal Telegram
TELEGRAM_API_KEY="6946505231:AAH2L1QKhNWEBfJSDwZImGRhkEwfBLQzyy8"
TELEGRAM_CHAT_ID="-1002039884441"

# Konfigurasi SFTP SourceForge
SFTP_USERNAME="semutimut76"
SFTP_PASSWORD="Fbrichy2402"
SFTP_HOST="frs.sourceforge.net"
SFTP_REMOTE_DIR="/home/frs/project/semutprjct/Lavender"

# Nama file untuk log error, log keberhasilan, dan log saat pembangunan ROM dimulai
ERROR_LOG="out/error.log"
LOG_BUILD_START="build_start.log"

# Fungsi untuk mengirim pesan Telegram
send_telegram_message() {
    local message="$1"
    local color="$2"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_API_KEY/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID&text=$color$message" -d "parse_mode=MarkdownV2" --output /dev/null
}

# Fungsi untuk mengirim file error.log ke Telegram
send_error_log() {
    send_telegram_message "📄 Mengirim file error.log..." "🟥"
    curl -F document=@"$ERROR_LOG" "https://api.telegram.org/bot$TELEGRAM_API_KEY/sendDocument?chat_id=$TELEGRAM_CHAT_ID" 2>&1 | \
    while IFS= read -r line; do
        if [[ $line == *"error"* ]]; then
            send_telegram_message "❌ Error saat mengirim file error.log ke Telegram: $line" "🟥"
        fi
    done
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
    rm -rf out
}

# Fungsi untuk mengunggah file ROM ke SFTP SourceForge
upload_to_sftp() {
    local local_file_path="$1"
    local remote_file_path="$2"
    send_telegram_message "🚀 Mengunggah file ROM ke SourceForge..." "🟩"
    sshpass -p "$SFTP_PASSWORD" sftp -oBatchMode=no -b - "$SFTP_USERNAME@$SFTP_HOST" <<EOL | tee -a "$LOG_BUILD_START"
cd "$SFTP_REMOTE_DIR/$remote_file_path"
put "$local_file_path"
bye
EOL
}

# Fungsi untuk mengirimkan persentase pembangunan ke Telegram
send_build_progress() {
    local total_steps=$1
    local current_step=$2
    local percentage=$((current_step * 100 / total_steps))

    # Menentukan emotikon berdasarkan persentase
    if [[ percentage -lt 25 ]]; then
        progress_emoji="🟥"
    elif [[ percentage -lt 50 ]]; then
        progress_emoji="🟧"
    elif [[ percentage -lt 75 ]]; then
        progress_emoji="🟨"
    else
        progress_emoji="🟩"
    fi

    send_telegram_message "🔨 Progress pembangunan: $progress_emoji $percentage%" "🟩"
}

# Fungsi untuk mengirim stiker awal sebagai penanda dimulainya build
send_start_sticker() {
    local sticker_id="CAACAgUAAxkBAAEojkFlkGQne2zszebg67ez9_pe_qc_zAACgwMAAmFGmFeh3JRczKxoDTQE"  # Ganti dengan ID stiker yang Anda inginkan
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_API_KEY/sendSticker" -d "chat_id=$TELEGRAM_CHAT_ID&sticker=$sticker_id"
}

# Mengirim stiker awal sebelum memulai pesan utama
send_start_sticker

# Mengirim pesan awal
send_telegram_message "Inisialisasi skrip telah selesai pada $(get_current_time_asia_jakarta). Memulai tugas..." "🔵"

# Repo Initialization with Additional Link
REPO_URL="https://github.com/FebriCahyaa/manifest.git"
REPO_BRANCH="thirteen"

# Menggunakan backslash untuk melanjutkan ke baris berikutnya
repo init -u $REPO_URL -b $REPO_BRANCH

# Clone local manifest repository
git clone https://github.com/FebriCahyaa/local_manifest.git -b supext .repo/local_manifests

# Mengirim pesan sebelum repo sync
send_telegram_message "Repo initialization selesai. Memulai repo sync pada $(get_current_time_asia_jakarta)..." "🔵"

# Repo Sync
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags 2>&1 | \
while IFS= read -r line; do
    if [[ $line == *"fatal"* || $line == *"error"* ]]; then
        send_telegram_message "Error: $line" "🟥"
    fi
done

# Mengirim pesan setelah repo sync
send_telegram_message "Repo sync selesai pada $(get_current_time_asia_jakarta). Melanjutkan tugas..." "🟩"

# Bagian build ROM
LUNCH="superior_lavender-userdebug"  # Sesuaikan dengan format yang sesuai dengan proyek Anda

# Memulai pembangunan ROM
send_telegram_message "🚀 Memulai proses membangun ROM ($LUNCH) pada $(get_current_time_asia_jakarta)..." "🟨"
log_build_start
source build/envsetup.sh
lunch $LUNCH

# Hitung jumlah langkah dalam proses pembangunan
total_build_steps=$(grep -c ^processor /proc/cpuinfo)
current_build_step=0

# Membuat perulangan untuk mengikuti langkah-langkah pembangunan
while ((current_build_step < total_build_steps)); do
    # Jalankan langkah pembangunan
    make -j$(nproc --all) 2>&1 | \
    while IFS= read -r build_line; do
        if [[ $build_line == *"error"* ]]; then
            send_telegram_message "❌ Error: $build_line" "🟥"
        fi
    done

    # Tambahkan ke langkah pembangunan saat ini
    ((current_build_step++))

    # Kirimkan persentase pembangunan ke Telegram
    send_build_progress "$total_build_steps" "$current_build_step"
done

# Mengecek apakah pembangunan berhasil atau tidak
if [ -f "out/target/product/$DEVICE/*.zip" ]; then
    # Setelah berhasil membangun ROM, mendapatkan lokasi OUT dan DEVICE
    OUT="$(pwd)/out/target/product/$DEVICE"
    DEVICE="$(sed -e "s/^.*_//" -e "s/-.*//" <<< "$LUNCH")"

    send_telegram_message "✅ Pembangunan ROM selesai pada $BUILD_END_TIME. ROM berhasil dibuat!" "🟩"
    log_build_end
    cleanup_after_build

    # Upload ROM ke SFTP SourceForge
    local_rom_file="$OUT/*.zip"
    remote_rom_dir="$DEVICE"
    upload_to_sftp "$local_rom_file" "$remote_rom_dir"

    # Kirim link unduhan ke Telegram bersama dengan md5sum dan size
    md5sum=$(md5sum "$local_rom_file" | awk '{print $1}')
    size=$(ls -sh "$local_rom_file" | awk '{print $1}')
    rom_file_name=$(basename "$local_rom_file")
    rom_download_link="https://downloads.sourceforge.net/project/semutprjct/Lavender/$remote_rom_dir/$rom_file_name"
    md5sum_message="MD5sum: $md5sum"
    size_message="Size: $size"
    send_telegram_message "🔗 [Unduh ROM terbaru]($rom_download_link)\n\n🔍 $md5sum_message\n📦 $size_message" "🔵"

    # Kirim pesan selamat menikmati ROMnya
    send_telegram_message "Selamat menikmati ROMnya! 🚀" "🟩"
else
    send_telegram_message "❌ Pembangunan ROM gagal pada $BUILD_END_TIME. Cek log untuk detailnya." "🟥"
    send_error_log  # Memanggil fungsi untuk mengirim error.log ke Telegram
fi
