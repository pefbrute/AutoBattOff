#!/bin/bash

# Get the directory where the script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
config_file="$script_dir/battery_config.env"
if [[ -f "$config_file" ]]; then
    source "$config_file"
    echo "Configuration loaded from $config_file"
else
    echo "Configuration file $config_file not found!"
    exit 1
fi

# Set full file paths
audio_file="$script_dir/$AUDIO_FILE"
log_file="$script_dir/$LOG_FILE"
low_battery_threshold=$LOW_BATTERY_THRESHOLD
critical_low_battery_threshold=$CRITICAL_LOW_BATTERY_THRESHOLD
high_battery_threshold=$HIGH_BATTERY_THRESHOLD
critical_battery_threshold=$CRITICAL_BATTERY_THRESHOLD
sudo_password="$SUDO_PASSWORD"

# Set environment variables from configuration
export DISPLAY="$DISPLAY"
export XAUTHORITY="$XAUTHORITY"
export XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR"
export DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS"

log() {
    echo "$(date) - $1" >> $log_file
}

log "Script started"

# Check for required utilities
if ! command -v mpg123 &> /dev/null; then
    log "mpg123 not found. Please install mpg123."
    exit 1
fi

if ! command -v yad &> /dev/null; then
    log "yad not found. Please install yad."
    exit 1
fi

notify_user() {
    local message="$1"
    local title="$2"
    log "$message"
    mpg123 $audio_file &
    yad --title="$title" --text="$message" --button=OK --width=$NOTIFICATION_WIDTH --height=$NOTIFICATION_HEIGHT --timeout=$NOTIFICATION_TIMEOUT &
    log "Notification sent: $message"
}

check_battery_status() {
    battery_level=$(cat ${BATTERY_PATH}/capacity)
    charging_status=$(cat ${BATTERY_PATH}/status)
    if [[ -z "$battery_level" || -z "$charging_status" ]]; then
        log "Error reading battery data."
        exit 1
    fi
    log "Battery level: $battery_level"
    log "Charging status: $charging_status"
}

check_battery_status

# Main battery check logic
if [[ $battery_level -lt $low_battery_threshold && "$charging_status" != "Charging" ]]; then
    log "Critical battery level. Shutting down..."
    echo $sudo_password | sudo -S /sbin/poweroff
elif [[ $battery_level -ge $low_battery_threshold && $battery_level -le $critical_low_battery_threshold && "$charging_status" != "Charging" ]]; then
    notify_user "URGENT: PLUG IN THE CHARGER!" "Charging Warning"
elif [[ $battery_level -gt $high_battery_threshold && $battery_level -lt $critical_battery_threshold && "$charging_status" == "Charging" ]]; then
    notify_user "Urgently disconnect the charger!" "Charging Warning"
elif [[ $battery_level -ge $critical_battery_threshold && "$charging_status" == "Charging" ]]; then
    log "Battery at 90% or higher. Shutting down laptop..."
    echo $sudo_password | sudo -S /sbin/poweroff
else
    if [[ "$charging_status" == "Charging" ]]; then
        log "Laptop is charging."
    else
        log "Battery charge is normal."
    fi
fi

log "Script completed"