#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$0")")"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

echo "[1/5] Checking python3-evdev"
python3 -c "import evdev" || {
    echo "python3-evdev is required: sudo apt install -y python3-evdev" >&2
    exit 1
}

echo "[2/5] Installing daemon"
install -o root -g root -m 755 mcanpos-scroll /usr/local/bin/mcanpos-scroll

echo "[3/5] Installing configuration"
if [ -e /etc/default/mcanpos-scroll ]; then
    echo "      /etc/default/mcanpos-scroll exists; keeping it"
else
    install -o root -g root -m 644 mcanpos-scroll.default /etc/default/mcanpos-scroll
fi

echo "[4/5] Installing systemd unit"
install -o root -g root -m 644 mcanpos-scroll.service /etc/systemd/system/mcanpos-scroll.service

echo "[5/5] Enabling and starting the service"
systemctl daemon-reload
systemctl enable --now mcanpos-scroll

echo
echo "=== Result ==="
systemctl is-active mcanpos-scroll
journalctl -u mcanpos-scroll -n 10 --no-pager

cat <<'MSG'

Remember to disable middle-click emulation, or scrolling will not work:

  gsettings set org.gnome.desktop.peripherals.mouse middle-click-emulation false
MSG
