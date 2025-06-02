# Battery Script Configuration

## Configuration File: `battery_config.env`

All script settings are moved to a separate configuration file for easy modification without editing the code.

### Battery Settings:
- `LOW_BATTERY_THRESHOLD` - critical minimum (default 39%)
- `CRITICAL_LOW_BATTERY_THRESHOLD` - low battery warning (default 49%)
- `HIGH_BATTERY_THRESHOLD` - high battery warning (default 80%)
- `CRITICAL_BATTERY_THRESHOLD` - critical maximum (default 90%)

### File Paths:
- `AUDIO_FILE` - audio file for notifications
- `LOG_FILE` - log file
- `BATTERY_PATH` - path to system battery information

### Notification Settings:
- `NOTIFICATION_TIMEOUT` - notification display time (seconds)
- `NOTIFICATION_WIDTH` - notification window width
- `NOTIFICATION_HEIGHT` - notification window height

### System Variables:
- `DISPLAY`, `XAUTHORITY`, `XDG_RUNTIME_DIR`, `DBUS_SESSION_BUS_ADDRESS` - environment variables for GUI

### Security:
- `SUDO_PASSWORD` - **WARNING**: sudo password in plain text (needs improvement)

## Usage:
1. Edit `battery_config.env` to suit your needs
2. Run `./autobattoff.sh`
3. The script will automatically load settings from the configuration

## Automation with Cron:
To run the battery check automatically every minute, add the following line to your crontab:

```bash
# Edit crontab
crontab -e

# Add this line (replace with your actual script path):
* * * * * /bin/bash "/path/to/your/autobattoff.sh"

# Example:
* * * * * /bin/bash "/home/fedor/AutoBattOff/autobattoff.sh"
```

This will check the battery status every minute and take appropriate actions based on your configuration.

## Recommendations:
- Don't store passwords in plain text
- Set access permissions for the configuration file: `chmod 600 battery_config.env` 