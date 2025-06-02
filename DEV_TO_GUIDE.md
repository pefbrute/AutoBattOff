# 🔋 Smart Battery Monitoring Script for Linux: Protect Your Laptop from Overcharging and Deep Discharge

**⚠️ Tested on Ubuntu 22.04 with X Server - May require adjustments for other distributions**

Have you ever left your laptop plugged in for hours, slowly damaging the battery? Or worse, forgotten to charge it until it completely dies? This comprehensive guide will help you create a smart battery monitoring system that automatically manages your laptop's charging cycle and prevents battery damage.

**💾 Ready to use? [Download the complete script from GitHub](https://github.com/pefbrute/AutoBattOff) and skip to Step 4!**

## 🎯 What This Script Does

Our battery monitoring script provides four levels of protection:

1. **🔴 Critical Low (≤39%)**: Automatically shuts down the laptop to prevent deep discharge
2. **🟡 Low Warning (40-49%)**: Shows urgent notification to plug in charger
3. **🟠 High Warning (80-89%)**: Notifies to unplug charger during charging
4. **🔴 Critical High (≥90%)**: Automatically shuts down to prevent overcharging

## 📋 Prerequisites

### System Requirements
- **Operating System**: Ubuntu 22.04 (tested) - other Linux distributions may require modifications
- **Display Server**: X Server (X11)

### Required Packages
```bash
# Update package list
sudo apt update

# Install required dependencies
sudo apt install mpg123 yad

# mpg123: for audio notifications
# yad: for GUI notifications (Yet Another Dialog)
```

## 🚀 Step 1: Project Setup

Create the project directory and navigate to it:
```bash
mkdir ~/AutoBattOff
cd ~/AutoBattOff
```

## 🔧 Step 2: Create Configuration File

Create `battery_config.env` with the following content:

```bash
# Battery thresholds (adjust according to your needs)
LOW_BATTERY_THRESHOLD=39
CRITICAL_LOW_BATTERY_THRESHOLD=49
HIGH_BATTERY_THRESHOLD=80
CRITICAL_BATTERY_THRESHOLD=90

# File paths (relative to script directory)
AUDIO_FILE="notification.mp3"
LOG_FILE="battery_log.txt"

# Notification settings
NOTIFICATION_TIMEOUT=10
NOTIFICATION_WIDTH=300
NOTIFICATION_HEIGHT=100

# System environment variables for GUI
DISPLAY=":0"
XAUTHORITY="/home/YOUR_USERNAME/.Xauthority"
XDG_RUNTIME_DIR="/run/user/1000"
DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

# Security (CHANGE THIS!)
SUDO_PASSWORD="YOUR_SUDO_PASSWORD"

# Battery path (usually BAT0, but might be BAT1 on some systems)
BATTERY_PATH="/sys/class/power_supply/BAT0"

# Logging
LOG_LEVEL="INFO"
```

### 🔐 Important Security Notes:
1. **Replace `YOUR_USERNAME`** with your actual username
2. **Replace `YOUR_SUDO_PASSWORD`** with your actual sudo password
3. **Set restrictive permissions**: `chmod 600 battery_config.env`

### 🔍 Finding Your Battery Path:
```bash
# List available power supplies
ls /sys/class/power_supply/

# Check if BAT0 exists, if not, use BAT1 or whatever you find
ls -la /sys/class/power_supply/BAT*/capacity
```

### 🎵 Getting a Notification Sound:
You need an MP3 file named `notification.mp3` in your project directory. You can:
```bash
# Download a free notification sound
wget https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3 -O notification.mp3

# Or create a simple beep sound with ffmpeg
sudo apt install ffmpeg
ffmpeg -f lavfi -i "sine=frequency=1000:duration=1" notification.mp3
```

## 📝 Step 3: Create the Main Script

Create `autobattoff.sh`:

```bash
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
```

## 🔧 Step 4: Make Script Executable

```bash
chmod +x autobattoff.sh
```

## 🧪 Step 5: Test the Script

### Manual Testing:
```bash
# Test the script manually
./autobattoff.sh

# Check the log file
cat battery_log.txt

# Check current battery status manually
cat /sys/class/power_supply/BAT0/capacity
cat /sys/class/power_supply/BAT0/status
```

### Test Different Scenarios:
1. **Test low battery**: Temporarily change `LOW_BATTERY_THRESHOLD` to a value higher than your current battery level
2. **Test high battery**: Plug in charger and temporarily change `HIGH_BATTERY_THRESHOLD` to a value lower than current level
3. **Test notifications**: Ensure you can see and hear notifications

## ⏰ Step 6: Automate with Cron

### Edit your crontab:
```bash
# Edit user crontab
crontab -e

# Add this line to check battery every minute
* * * * * /bin/bash "/path/to/your/script/autobattoff.sh"
```

### Verify Cron Job:
```bash
# List current user's cron jobs
crontab -l

# Monitor real-time log updates
tail -f battery_log.txt
```

## 📊 What the Script Logs

The script creates a `battery_log.txt` file with entries like:
- Script start/completion
- Current battery level and charging status
- Notifications sent
- Shutdown events

You can monitor the log with:
```bash
# View recent logs
tail -20 battery_log.txt

# Follow logs in real-time
tail -f battery_log.txt
```

## 🛡️ Security Note

The script stores your sudo password in plain text in the configuration file. For better security:
1. Set restrictive permissions: `chmod 600 battery_config.env`
2. Alternatively, you can modify `/etc/sudoers` to allow passwordless shutdown:
   ```bash
   sudo visudo
   # Add: YOUR_USERNAME ALL=(ALL) NOPASSWD: /sbin/poweroff
   ```

## 🎯 Configuration Tips

- **Conservative thresholds**: Start with 20% for low and 85% for high
- **Adjust notification timeout**: Increase `NOTIFICATION_TIMEOUT` if you need more time to see notifications
- **Battery path**: Make sure `BATTERY_PATH` points to your actual battery (check `/sys/class/power_supply/`)

## 🚀 Conclusion

You now have a working battery monitoring system that:
- ✅ Prevents overcharging by shutting down at 90%
- ✅ Prevents deep discharge by shutting down at 39%
- ✅ Shows visual and audio notifications
- ✅ Logs all activities for monitoring

The script runs every minute via cron and automatically protects your battery health.

---

**🔗 Complete Repository**: [AutoBattOff on GitHub](https://github.com/pefbrute/AutoBattOff) - Ready to download and use!
**🏷️ Tags**: `#linux` `#ubuntu` `#bash` `#battery` `#automation` `#systemadmin` 