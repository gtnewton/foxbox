# Foxbox — Clean Firefox for Web Development

## The problem it solves

Testing a website properly requires a browser with no memory of previous visits: no cached files serving stale CSS, no old cookies interfering with session logic, no lingering Service Workers from a previous build. It also needs to trust your local SSL certificate so you can test over HTTPS without clicking through security warnings every time.

Private browsing doesn't fully solve this. Firefox behaves slightly differently in private mode — it skips certain APIs and alters some timing behaviour — so you're not testing what a real first-time visitor experiences.

**foxbox** solves both problems:

- Every session starts from a clean slate — no cache, no cookies, no history
- Your local development server's SSL certificate is trusted automatically, with no warnings

---

## What it installs and changes

Running `install.sh` does the following:

**System-level (once, permanent):**
- Installs `mkcert`'s local Certificate Authority into your system trust store. This is what allows Firefox — and other tools — to trust locally-generated SSL certificates without warnings. This change persists after uninstalling foxbox.

**Your home directory:**
- Creates a master Firefox profile at `~/.mozilla/dev`. This is the clean baseline that every dev session is cloned from.
- Installs the `foxbox` command to `~/.local/bin/foxbox`.
- Installs a GNOME launcher entry (with its own icon) so foxbox appears in your application menu and can be pinned to the dock. The launcher's right-click menu includes an **Edit master profile** action for deliberately changing the baseline.

**What it does not touch:**
- Your regular Firefox profile and browsing data are completely unaffected.
- No system files are modified beyond the mkcert CA (which requires your password once).

---

## Installation

### Before you start

You need two tools installed:

- **mkcert** — generates the local CA and certificates
  - Ubuntu 22.04+: `sudo apt install mkcert`
  - Any distro: download from https://github.com/FiloSottile/mkcert/releases
- **libnss3-tools** — lets the installer inject the CA into the Firefox profile
  - `sudo apt install libnss3-tools`

### Run the installer

```bash
cd foxbox
./install.sh
```

The installer will:

1. Check that all required tools are present
2. Prompt for the Firefox UI locale (default: `en-CA` — press Enter to accept)
3. Install the mkcert CA into your system trust store
4. Create a fresh Firefox profile at `~/.mozilla/dev`
5. Inject the CA into that profile so locally-signed certificates are trusted
6. Download and stage the extensions listed in `extensions.conf`
7. Launch Firefox once, headless, to register and enable those extensions and write the profile's startup caches — no interaction required
8. Install the `foxbox` command and GNOME launcher

The baseline configuration — devtools layout, window state, pinned sites, locale, telemetry-off, and the auto-enabling of extensions — is defined declaratively in `user.js`, so there is nothing to set up by hand.

### Generating certificates for your project

After installation, run this once in your project directory to generate a locally-trusted SSL certificate:

```bash
mkcert localhost 127.0.0.1
```

Point your local dev server at the resulting `.pem` files. Firefox will trust them automatically with no warnings.

---

## Using foxbox

```bash
foxbox
foxbox https://localhost:3000
```

Each session launches a fresh Firefox window cloned from your master profile. When you close the window, everything — cache, cookies, history, session storage — is discarded automatically. The next session starts clean again.

The browser window is fully isolated from your regular Firefox. Both can run at the same time.

---

## Adding or removing extensions

Open `extensions.conf` in this directory. Each line is one extension:

```
web-developer                  {c45c406e-ab73-11d8-be73-000a95be3b12}
# bitwarden-password-manager     {446900e4-71c2-419f-a6a7-df9c091e268b}
```

**To remove an extension:** comment out or delete its line, then re-run `install.sh`.

**To add an extension:**

1. Find its slug — the last part of its URL on [addons.mozilla.org](https://addons.mozilla.org). For example, `addons.mozilla.org/en-US/firefox/addon/react-devtools/` → slug is `react-devtools`.

2. Find its GUID by running:
   ```bash
   curl -s "https://addons.mozilla.org/api/v5/addons/addon/react-devtools/" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['guid'])"
   ```

3. Add a line to `extensions.conf`:
   ```
   react-devtools     {your-guid-here}
   ```

4. Re-run `install.sh`. When prompted about the existing profile, keep it. The installer will download the new extension and add it to the profile.

### Adding a theme

Themes use the same slug/GUID format as extensions:

```
firefox-alpenglow     {your-guid-here}
```

The theme XPI will be downloaded and installed into the profile, but Firefox will not automatically switch to it. After the first `foxbox` launch, open `about:addons`, activate the theme, then run `foxbox --edit` and close the window — this saves the active theme back to the master profile so every future session uses it.

---

## The master profile

The master profile lives at `~/.mozilla/dev`.

**Don't open it directly with a bare `firefox --profile ~/.mozilla/dev`.** Browsing in it that way writes cache, cookies, and history back into the master, contaminating every future foxbox session. foxbox detects this on its next run and warns you; if it happens, re-run `install.sh` and overwrite the profile.

**To change your baseline deliberately** — add an extension, adjust the devtools layout, tweak an `about:config` setting — use the sanctioned edit mode:

```bash
foxbox --edit
```

or choose **Edit master profile** from the foxbox launcher's right-click menu. This opens the master directly and re-stamps its baseline on close, so the change isn't later mistaken for contamination. Anything you adjust persists to every future session.

Preference-level defaults can also be changed declaratively by editing `user.js` and re-running `install.sh` (it re-copies `user.js` even when you keep the existing profile).

---

## Uninstalling

```bash
./uninstall.sh
```

This removes the `foxbox` command, the GNOME launcher entry, its icon, and optionally the master profile. It does not remove the mkcert CA from your system trust store, since other tools may rely on it. To remove the CA as well:

```bash
mkcert -uninstall
```

---

## License

MIT — see [LICENSE](LICENSE).
