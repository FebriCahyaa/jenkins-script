#!/bin/bash

# Set your SourceForge credentials
SF_USERNAME="semutimut76"
SF_PASSWORD="Fbrichy2402"

# Set your SourceForge link for the ROM download
SF_LINK="https://sourceforge.net/projects/semutprjct/files/Lavender/"

# Set your Telegram bot token and chat ID
BOT_TOKEN="634395216f41de7edce9538eba836afb9bdc80b7"
CHAT_ID="YOUR_CHAT_ID"

# Set your branch for device tree, vendor tree, kernel tree, and custom ROM
DT_BRANCH=""
VT_BRANCH=""
KT_BRANCH=""
ROM_BRANCH=""  # Set your custom ROM branch

# Set your source for custom ROM
CUSTOM_ROM_SOURCE="https://github.com/your-username/custom-rom.git"

# Function to send a message to Telegram
send_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message" \
        -d "parse_mode=Markdown"
}

# Function to send a document to Telegram
send_document() {
    local document="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -d "chat_id=$CHAT_ID" \
        -F "document=@$document" \
        -F "caption=Error log"
}

# Example: Send a start message
send_message "Build process has started. 🚀"

# Provide a list of available custom ROMs with links and branches
send_message "List of Available Custom ROMs:"
send_message "- [SupExt](https://github.com/SuperiorExtended/manifest.git), Branch: thirteen"
send_message "- [ROM 2](https://github.com/username/rom2), Branch: develop"
send_message "- [ROM 3](https://github.com/username/rom3), Branch: stable"

# Request user to choose a ROM
send_message "Please choose a ROM from the list above by providing the link. Example: https://github.com/username/rom1"

# Wait for user input
read -p "Enter the link to your selected custom ROM: " custom_rom_link

# Validate custom ROM link
if [ -z "$custom_rom_link" ]; then
    send_message "Invalid custom ROM link. Build process aborted."
    exit 1
fi

# Verify custom ROM path
if [[ ! "$custom_rom_link" =~ ^https://github.com/.*$ ]]; then
    send_message "Invalid custom ROM path. It should be in the format: https://github.com/username/rom"
    exit 1
fi

# Extract repository names
custom_rom_repo=$(basename "$custom_rom_link" .git)
custom_rom_path="custom/rom"

# Initialize the repo if not already done
if [ ! -d "/mnt/rizkyfebian/rom" ]; then
    mkdir -p /mnt/rizkyfebian/rom
    cd /mnt/rizkyfebian/rom
    repo init -u "$custom_rom_link" -b "$ROM_BRANCH"
fi

# Sync the source code
cd /mnt/rizkyfebian/rom
repo sync -j$(nproc --all)

# Move custom ROM to the specified directory
mv "$custom_rom_repo" "$custom_rom_path"

# Request device tree link from user via Telegram
send_message "Please provide the link to your device tree. Example: https://github.com/your-username/device-tree-repo"

# Wait for user input
read -p "Enter the link to your device tree: " device_tree_link

# Validate device tree link
if [ -z "$device_tree_link" ]; then
    send_message "Invalid device tree link. Build process aborted."
    exit 1
fi

# Verify device tree path
if [[ ! "$device_tree_link" =~ ^https://github.com/your-username/device/.*$ ]]; then
    send_message "Invalid device tree path. It should be in the format: https://github.com/your-username/device/brand/codename"
    exit 1
fi

# Extract repository names
device_tree_repo=$(basename "$device_tree_link" .git)
device_tree_path="device/brand/codename"

# Move device tree to the specified directory
mv "$device_tree_repo" "$device_tree_path"

# Request vendor tree link from user via Telegram
send_message "Please provide the link to your vendor tree. Example: https://github.com/your-username/vendor-tree-repo"

# Wait for user input
read -p "Enter the link to your vendor tree: " vendor_tree_link

# Validate vendor tree link
if [ -z "$vendor_tree_link" ]; then
    send_message "Invalid vendor tree link. Build process aborted."
    exit 1
fi

# Verify vendor tree path
if [[ ! "$vendor_tree_link" =~ ^https://github.com/your-username/vendor/.*$ ]]; then
    send_message "Invalid vendor tree path. It should be in the format: https://github.com/your-username/vendor/brand/codename"
    exit 1
fi

# Extract repository names
vendor_tree_repo=$(basename "$vendor_tree_link" .git)
vendor_tree_path="vendor/brand/codename"

# Initialize vendor tree if not already done
if [ ! -d "/mnt/rizkyfebian/vendor" ]; then
    mkdir -p /mnt/rizkyfebian/vendor
    cd /mnt/rizkyfebian/vendor
    repo init -u "$vendor_tree_link" -b "$VT_BRANCH"
    repo sync -j$(nproc --all)
fi

# Move vendor tree to the specified directory
mv "$vendor_tree_repo" "$vendor_tree_path"

# Request kernel tree link from user via Telegram
send_message "Please provide the link to your kernel tree. Example: https://github.com/your-username/kernel-tree-repo"

# Wait for user input
read -p "Enter the link to your kernel tree: " kernel_tree_link

# Validate kernel tree link
if [ -z "$kernel_tree_link" ]; then
    send_message "Invalid kernel tree link. Build process aborted."
    exit 1
fi

# Verify kernel tree path
if [[ ! "$kernel_tree_link" =~ ^https://github.com/your-username/kernel/.*$ ]]; then
    send_message "Invalid kernel tree path. It should be in the format: https://github.com/your-username/kernel/brand/codename"
    exit 1
fi

# Extract repository names
kernel_tree_repo=$(basename "$kernel_tree_link" .git)
kernel_tree_path="kernel/brand/codename"

# Initialize kernel tree if not already done
if [ ! -d "/mnt/rizkyfebian/kernel" ]; then
    mkdir -p /mnt/rizkyfebian/kernel
    cd /mnt/rizkyfebian/kernel
    repo init -u "$kernel_tree_link" -b "$KT_BRANCH"
    repo sync -j$(nproc --all)
fi

# Move kernel tree to the specified directory
mv "$kernel_tree_repo" "$kernel_tree_path"

# Build the ROM with progress updates and log errors
send_message "Building ROM: 0% complete..."

make -j$(nproc --all) 2>&1 | while read -r line; do
    # Extract build progress from the output
    progress=$(echo "$line" | grep -oE "[0-9]+%")
    if [ ! -z "$progress" ]; then
        send_message "Building ROM: $progress complete..."
    fi

    # Capture error log
    if [[ $line == *"error"* || $line == *"Error"* ]]; then
        echo "$line" >>error.log
    fi
done

# Check if error.log exists and send it
if [ -e "error.log" ]; then
    send_message "Build process encountered errors. Sending error log..."
    send_document "error.log"
else
    send_message "Build process has completed. Uploading ROM to SourceForge... 🌐"

    # Change directory to the specified location
    cd /home/frs/project/semutprjct/Lavender

    # Upload ROM to SourceForge using SFTP
    expect <<EOF
    spawn sftp -oBatchMode=no -oStrictHostKeyChecking=no $SF_USERNAME@frs.sourceforge.net:/home/frs/project/semutprjct/Lavender/
    expect "password:"
    send "$SF_PASSWORD\r"
    expect "sftp>"
    send "put /mnt/rizkyfebian/rom/out/target/product/device/*.zip\r"
    expect "sftp>"
    send "bye\r"
EOF

    send_message "ROM has been uploaded to SourceForge. You can download it [here]($SF_LINK). 🎉"
fi
