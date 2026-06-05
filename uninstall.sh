#!/bin/bash
set -euo pipefail

BIN_FILE="${HOME}/.local/bin/foxbox"
DESKTOP_FILE="${HOME}/.local/share/applications/foxbox.desktop"
ICON_FILE="${HOME}/.local/share/icons/hicolor/scalable/apps/foxbox.svg"
PROFILE_DIR="${HOME}/.mozilla/dev"

echo "Removing foxbox..."

[[ -f "$BIN_FILE" ]]     && rm "$BIN_FILE"     && echo "Removed $BIN_FILE"
[[ -f "$DESKTOP_FILE" ]] && rm "$DESKTOP_FILE" && echo "Removed $DESKTOP_FILE"
[[ -f "$ICON_FILE" ]]    && rm "$ICON_FILE"    && echo "Removed $ICON_FILE"
update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache -f -t "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true

if [[ -d "$PROFILE_DIR" ]]; then
    echo ""
    read -rp "Remove master profile at $PROFILE_DIR? [y/N] " choice
    case "$choice" in
        [yY]|[yY][eE][sS])
            rm -rf "$PROFILE_DIR"
            echo "Removed $PROFILE_DIR"
            ;;
        *)
            echo "Master profile left in place."
            [[ -f "${PROFILE_DIR}/user.js" ]] && rm "${PROFILE_DIR}/user.js" && echo "Removed ${PROFILE_DIR}/user.js"
            ;;
    esac
fi

echo ""
echo "NOTE: mkcert root CA was not removed — it may be used by other tools."
echo "      To remove it: mkcert -uninstall"
echo ""
echo "Done."
