#!/bin/bash
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="${HOME}/.mozilla/dev"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/scalable/apps"

# ── Dependency checks ────────────────────────────────────────────────────────

if ! command -v mkcert &>/dev/null; then
    echo "ERROR: mkcert is required but not found."
    echo ""
    echo "Install options:"
    echo "  Ubuntu 22.04+:  sudo apt install mkcert"
    echo "  Any distro:     https://github.com/FiloSottile/mkcert/releases"
    echo "                  sudo wget -O /usr/local/bin/mkcert <url-for-your-arch>"
    echo "                  sudo chmod +x /usr/local/bin/mkcert"
    exit 1
fi

if ! command -v certutil &>/dev/null; then
    echo "ERROR: certutil (libnss3-tools) is required but not found."
    echo "Install: sudo apt install libnss3-tools"
    exit 1
fi

if ! command -v firefox &>/dev/null; then
    echo "ERROR: firefox is required but not found."
    exit 1
fi

if ! command -v curl &>/dev/null; then
    echo "ERROR: curl is required but not found."
    echo "Install: sudo apt install curl"
    exit 1
fi

# ── Locale ───────────────────────────────────────────────────────────────────

DEFAULT_LOCALE="en-CA"
read -rp "Firefox UI locale [${DEFAULT_LOCALE}]: " locale_input
LOCALE="${locale_input:-${DEFAULT_LOCALE}}"
echo "Locale set to: ${LOCALE}"

# ── mkcert root CA ───────────────────────────────────────────────────────────

echo "Installing mkcert root CA into system trust store..."
mkcert -install

CA_ROOT=$(mkcert -CAROOT)
CA_CERT="${CA_ROOT}/rootCA.pem"
CA_NAME="mkcert development CA"

if [[ ! -f "$CA_CERT" ]]; then
    echo "ERROR: mkcert CA certificate not found at $CA_CERT"
    exit 1
fi

# ── Master profile ───────────────────────────────────────────────────────────

CREATE_PROFILE=true

if [[ -d "$PROFILE_DIR" ]]; then
    echo ""
    echo "A master profile already exists at $PROFILE_DIR"
    read -rp "Overwrite it with a fresh profile? Existing config will be lost. [y/N] " choice
    case "$choice" in
        [yY]|[yY][eE][sS])
            echo "Removing existing profile..."
            rm -rf "$PROFILE_DIR"
            ;;
        *)
            echo "Keeping existing profile."
            CREATE_PROFILE=false
            ;;
    esac
fi

if [[ "$CREATE_PROFILE" == true ]]; then
    echo "Creating master profile at $PROFILE_DIR..."
    mkdir -p "$PROFILE_DIR"
    certutil -N -d "sql:${PROFILE_DIR}" --empty-password
else
    # Existing profile may lack cert9.db if it was created by an old Firefox
    if [[ ! -f "${PROFILE_DIR}/cert9.db" ]]; then
        echo "cert9.db missing from existing profile — initialising NSS database..."
        certutil -N -d "sql:${PROFILE_DIR}" --empty-password
    fi
fi

# ── CA injection ─────────────────────────────────────────────────────────────

if certutil -L -d "sql:${PROFILE_DIR}" 2>/dev/null | grep -qF "$CA_NAME"; then
    echo "mkcert CA already trusted in profile, skipping."
else
    echo "Injecting mkcert CA into profile..."
    certutil -A -d "sql:${PROFILE_DIR}" -t "C,," -n "$CA_NAME" -i "$CA_CERT"
    echo "mkcert CA injected."
fi

# ── Baseline preferences ─────────────────────────────────────────────────────

cp "${BUNDLE_DIR}/user.js" "${PROFILE_DIR}/user.js"
echo "user_pref(\"intl.locale.requested\", \"${LOCALE}\");" >> "${PROFILE_DIR}/user.js"
echo "Baseline preferences installed (locale: ${LOCALE})."

# ── Extensions ───────────────────────────────────────────────────────────────

if [[ -f "${BUNDLE_DIR}/extensions.conf" ]]; then
    mkdir -p "${PROFILE_DIR}/extensions"
    while read -r slug guid; do
        [[ -z "$slug" || "$slug" == \#* ]] && continue
        echo "Downloading extension: ${slug}..."
        # AMO returns the download URL and a "sha256:<hex>" hash for the XPI.
        read -r url hash < <(curl -sf "https://addons.mozilla.org/api/v5/addons/addon/${slug}/" \
              | python3 -c "import sys,json; f=json.load(sys.stdin)['current_version']['file']; print(f['url'], f['hash'])") || {
            echo "  WARNING: Could not fetch metadata for ${slug} — skipping."
            continue
        }
        xpi="${PROFILE_DIR}/extensions/${guid}.xpi"
        if ! curl -sL --fail "$url" -o "$xpi"; then
            echo "  WARNING: Download failed for ${slug} — skipping."
            rm -f "$xpi"
            continue
        fi
        if [[ ! -s "$xpi" ]]; then
            echo "  WARNING: Downloaded file is empty for ${slug} — skipping."
            rm -f "$xpi"
            continue
        fi
        # Verify integrity against the AMO-published hash before trusting the XPI.
        if [[ "${hash%%:*}" == "sha256" ]] && command -v sha256sum &>/dev/null; then
            if ! echo "${hash#sha256:}  ${xpi}" | sha256sum -c --status; then
                echo "  WARNING: Checksum mismatch for ${slug} — removing and skipping."
                rm -f "$xpi"
                continue
            fi
        else
            echo "  WARNING: Cannot verify checksum for ${slug} (unexpected hash format or sha256sum missing)."
        fi
        # Verify the XPI is a valid archive and its internal extension ID matches
        # the GUID in extensions.conf. Firefox uses the XPI filename as the
        # extension ID for sideloading, so a mismatch silently prevents loading.
        actual_id=$(python3 - "$xpi" <<'PY' 2>/dev/null
import zipfile, json, sys
try:
    with zipfile.ZipFile(sys.argv[1]) as z:
        m = json.loads(z.read('manifest.json'))
        gecko = (m.get('browser_specific_settings') or m.get('applications') or {}).get('gecko', {})
        print(gecko.get('id', ''))
except Exception:
    sys.exit(1)
PY
        ) || { echo "  WARNING: ${slug} XPI is not a valid archive — removing and skipping."; rm -f "$xpi"; continue; }
        if [[ -n "$actual_id" && "$actual_id" != "$guid" ]]; then
            echo "  WARNING: Extension ID mismatch for ${slug}: XPI contains '${actual_id}', expected '${guid}'."
            echo "           Verify the GUID in extensions.conf (see format notes at the top of that file)."
            rm -f "$xpi"
            continue
        fi
        echo "  OK: ${slug}"
    done < "${BUNDLE_DIR}/extensions.conf"
fi

# ── Profile warm-up (non-interactive) ────────────────────────────────────────
# Launch Firefox once, headless, so it registers the sideloaded extensions and
# writes its startup caches into the master profile. extensions.autoDisableScopes=0
# (set in user.js) makes the add-ons activate without the manual approval prompt,
# so no user interaction is needed here. The baseline UI/devtools/pinned-site
# config all comes from user.js — there is nothing to configure by hand.

# Returns 0 once every profile-scoped extension is registered and active.
extensions_ready() {
    python3 - "$1" <<'PY' 2>/dev/null
import json, sys
try:
    addons = json.load(open(sys.argv[1]))["addons"]
except Exception:
    sys.exit(1)
prof = [a for a in addons if a.get("location") == "app-profile"]
sys.exit(0 if prof and all(a.get("active") for a in prof) else 1)
PY
}

if [[ "$CREATE_PROFILE" == true ]]; then
    echo "Warming up profile (headless) to register and enable extensions..."
    MOZ_DISABLE_CRASH_REPORTER=1 firefox --headless --profile "$PROFILE_DIR" --no-remote about:blank >/dev/null 2>&1 &
    FF_PID=$!

    # Poll until the extensions are active (≈ a few seconds), capped at 30s.
    for _ in $(seq 1 60); do
        extensions_ready "${PROFILE_DIR}/extensions.json" && break
        sleep 0.5
    done
    sleep 1  # let addonStartup.json.lz4 / xulstore.json flush

    kill "$FF_PID" 2>/dev/null || true
    wait "$FF_PID" 2>/dev/null || true

    if extensions_ready "${PROFILE_DIR}/extensions.json"; then
        echo "Extensions registered and enabled."
    else
        echo "WARNING: extensions did not all activate; check ${PROFILE_DIR}/extensions.json."
    fi

    # Record baseline timestamp so foxbox can detect accidental direct use.
    stat -c %Y "${PROFILE_DIR}/prefs.js" 2>/dev/null > "${PROFILE_DIR}/.foxbox-baseline" || true
    echo "Profile baseline ready."
    echo ""
    echo "WARNING: Do not open this profile directly (e.g. firefox --profile ${PROFILE_DIR})."
    echo "         Browsing in it will corrupt your clean baseline with cache, cookies,"
    echo "         and history. Use 'foxbox' exclusively — it always clones a fresh copy."
fi

# ── Install script ───────────────────────────────────────────────────────────

mkdir -p "$BIN_DIR"
cp "${BUNDLE_DIR}/foxbox" "${BIN_DIR}/foxbox"
chmod +x "${BIN_DIR}/foxbox"
echo "foxbox installed to ${BIN_DIR}/foxbox"

if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo "NOTE: ${BIN_DIR} is not in your PATH. Add it to ~/.bashrc or ~/.profile:"
    echo "      export PATH=\"\${HOME}/.local/bin:\${PATH}\""
fi

# ── Install icon ─────────────────────────────────────────────────────────────

if [[ -f "${BUNDLE_DIR}/foxbox.svg" ]]; then
    mkdir -p "$ICON_DIR"
    cp "${BUNDLE_DIR}/foxbox.svg" "${ICON_DIR}/foxbox.svg"
    gtk-update-icon-cache -f -t "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
    echo "Icon installed to ${ICON_DIR}/foxbox.svg"
fi

# ── Install .desktop file ────────────────────────────────────────────────────

mkdir -p "$DESKTOP_DIR"
cp "${BUNDLE_DIR}/foxbox.desktop" "${DESKTOP_DIR}/foxbox.desktop"
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
echo "foxbox.desktop installed to ${DESKTOP_DIR}/foxbox.desktop"

# ── Done ─────────────────────────────────────────────────────────────────────

echo "Installation complete."
echo ""
echo "Usage: foxbox [URL]"
