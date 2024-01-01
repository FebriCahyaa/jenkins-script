#!/bin/bash

# Informasi Proyek
clean_directory="/mnt/rizkyfebian/rom"
CORE=12
TELEGRAM_API_KEY="6946505231:AAH2L1QKhNWEBfJSDwZImGRhkEwfBLQzyy8"
TELEGRAM_CHAT_ID="-1002039884441"
SF_USERNAME="semutimut76"
SF_HOST="frs.sourceforge.net"
SF_REMOTE_DIR="/home/frs/project/semutprjct/Lavender"
SF_PASSWORD="Fbrichy2402"
ROM_NAME="Afterlife"
LUNCH="afterlife_lavender-userdebug"  # Sesuaikan dengan proyek Anda
MAINTAINER="FebriCahyaa"
CHANGES_FILE="changelog.txt"
ERROR_LOG="error.log"

# Fungsi untuk mengirim pesan Telegram
send_telegram_message() {
    local message="$1"
    local color="$2"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_API_KEY/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID&text=$color$message" -d "parse_mode=MarkdownV2" --output /dev/null
}

# Fungsi untuk menampilkan angka yang berjalan
show_progress() {
    local total=$1
    for ((i = 1; i <= total; i++)); do
        echo -ne "Proses berlangsung: $i% \r"
        sleep 0.1
    done
    echo -e "\n"
}

# Fungsi untuk menghapus dan membuat direktori
clean_and_create_directory() {
    local directory="$1"
    send_telegram_message "🔄 Menghapus dan membuat direktori pada: $(date +"%Y-%m-%d %H:%M:%S")" "🔄"
    rm -rf "$directory"
    mkdir -p "$directory"
    send_telegram_message "✅ Direktori dibuat pada: $(date +"%Y-%m-%d %H:%M:%S")" "✅"
}

# Fungsi untuk repo sync
repo_sync() {
    send_telegram_message "🔄 Repo Sync dimulai dengan $CORE core..." "🔄"
    show_progress 100
    repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$CORE  2>&1 | \
    while IFS= read -r line; do
        if [[ $line == *"fatal"* || $line == *"error"* ]]; then
            send_telegram_message "❌ Error: $line" "❌"
            echo "$(date +"%Y-%m-%d %H:%M:%S") - $line" >> "$ERROR_LOG"
            exit 1
        fi
    done
    send_telegram_message "✅ Repo Sync selesai dengan $CORE core." "✅"
}

# Fungsi untuk inisialisasi repo
init_repo() {
    local url="$1"
    local branch="$2"
    send_telegram_message "🚀 Inisialisasi repo dimulai pada: $(date +"%Y-%m-%d %H:%M:%S")" "🚀"
    repo init --depth=1 --no-repo-verify -u "$url" -b "$branch" -g default,-mips,-darwin,-notdefault
    send_telegram_message "🚀 Inisialisasi repo selesai pada: $(date +"%Y-%m-%d %H:%M:%S")" "🚀"
}

# Fungsi untuk clone local manifest repository
clone_manifest() {
    local url="$1"
    local branch="$2"
    send_telegram_message "🚀 Clone local manifest repository dimulai pada: $(date +"%Y-%m-%d %H:%M:%S")" "🚀"
    git clone "$url" -b "$branch" .repo/local_manifests
    send_telegram_message "🚀 Clone local manifest repository selesai pada: $(date +"%Y-%m-%d %H:%M:%S")" "🚀"
}

# Fungsi untuk skenario build ROM
build_rom() {
    send_telegram_message "🔄 Skenario build ROM dimulai..." "🔄"
    source build/envsetup.sh
    send_telegram_message "🚀 Memilih perangkat dan mode build (LUNCH) pada: $(date +"%Y-%m-%d %H:%M:%S")" "🚀"
    lunch $LUNCH
    send_telegram_message "🛠️ Perintah make untuk membangun ROM:" "🛠️"
    send_telegram_message "📋 make -j$CORE" "📋"
    make -j$CORE
    send_telegram_message "🚀 Pembangunan ROM selesai pada: $(date +"%Y-%m-%d %H:%M:%S")" "🚀"
}

# Fungsi untuk membuat changelog
create_changelog() {
    send_telegram_message "🚀 Membuat changelog pada: $(date +"%Y-%m-%d %H:%M:%S")" "🚀"
    git log --pretty=format:"%h - %s (%an)" > "$CHANGES_FILE"
    if [ -f "$CHANGES_FILE" ]; then
        while IFS= read -r line; do
            send_telegram_message "$line" ""
        done < "$CHANGES_FILE"
    else
        send_telegram_message "❌ Changelog tidak ditemukan." "❌"
    fi
}

# Fungsi untuk upload ROM ke SourceForge
upload_rom() {
    send_telegram_message "🚀 Upload ROM dimulai pada: $(date +"%Y-%m-%d %H:%M:%S")" "🚀"
    ROM_FILENAME="$(date +'%Y%m%d')_${ROM_NAME}.zip"
    sshpass -p "$SF_PASSWORD" sftp "$SF_USERNAME@$SF_HOST:$SF_REMOTE_DIR" <<EOF
      put out/target/product/$LUNCH/$ROM_FILENAME
      exit
EOF

    # Penanganan kesalahan upload
    if [ $? -eq 0 ]; then
        upload_end_time=$(date +"%Y-%m-%d %H:%M:%S")
        send_telegram_message "🚀 Upload ROM selesai pada: $upload_end_time" "🚀"

        # Menampilkan link download setelah berhasil upload
        ROM_DOWNLOAD_LINK="https://your_sourceforge_url/path/to/$ROM_FILENAME"
        send_telegram_message "🔗 Link download ROM: [Download Here]($ROM_DOWNLOAD_LINK)" "🔗"
    else
        send_telegram_message "❌ Error: Upload ROM gagal." "❌"
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Error: Upload ROM gagal." >> "$ERROR_LOG"
        send_telegram_message "❌ Proses upload ROM gagal. Silakan periksa log untuk informasi lebih lanjut." "❌"

        # Hapus directory setelah selesai mengupload jika proses upload berhasil
        send_telegram_message "🔄 Menghapus direktori setelah upload selesai..." "🔄"
        rm -rf "$clean_directory"
        send_telegram_message "✅ Direktori dihapus setelah upload selesai." "✅"
    fi
}

# Fungsi untuk menghitung integritas SHA untuk ROM
calculate_sha() {
    send_telegram_message "🔄 Menghitung integritas SHA untuk ROM..." "🔄"
    SHA_SUM=$(sha256sum "out/target/product/$LUNCH/$ROM_FILENAME" | awk '{print $1}')
    send_telegram_message "✅ Integritas SHA ROM: $SHA_SUM" "✅"
}

# Fungsi untuk membuat error log ketika mengalami masalah
create_error_log() {
    send_telegram_message "🔄 Membuat error log pada: $(date +"%Y-%m-%d %H:%M:%S")" "🔄"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Terjadi kesalahan selama proses." >> "$ERROR_LOG"
    send_telegram_message "✅ Error log telah dibuat." "✅"
}

# Main Script

# Menghapus dan membuat direktori
clean_and_create_directory "$clean_directory"

# Repo Sync
repo_sync

# Inisialisasi repo dengan link GitHub
repo_url="https://github.com/your/repo.git"
repo_branch="main"  # Ganti dengan nama branch yang diinginkan
init_repo "$repo_url" "$repo_branch"

# Clone local manifest repository
git_url="https://github.com/FebriCahyaa/local_manifest.git"
manifest_branch="after"
clone_manifest "$git_url" "$manifest_branch"

# Repo Sync kembali dengan jumlah core yang ditentukan
repo_sync

# Skenario build ROM
build_rom

# Membuat changelog
create_changelog

# Upload ROM ke SourceForge
upload_rom

# Menghitung integritas SHA untuk ROM
calculate_sha

# Membuat error log jika terjadi masalah
create_error_log
