#!/bin/sh

dmenu_bin="${DMENU_BIN:-dmenu}"
systemctl_bin="${SYSTEMCTL_BIN:-systemctl}"
pkill_bin="${PKILL_BIN:-pkill}"

choice="$(printf '%s\n' Suspend Logout Reboot Shutdown | "$dmenu_bin" -i -p "  Power")"

case "$choice" in
    Suspend)
        "$systemctl_bin" suspend
        ;;
    Logout)
        "$pkill_bin" -TERM -x dwm
        ;;
    Reboot)
        "$systemctl_bin" reboot
        ;;
    Shutdown)
        "$systemctl_bin" poweroff
        ;;
esac
