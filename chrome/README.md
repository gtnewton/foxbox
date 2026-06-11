# Editing the foxbox chrome theme

The foxbox "theme" is a single `userChrome.css` file that restyles Firefox's own
toolbar/tab UI (the *chrome*), plus two SVG assets it references. It is not a
WebExtension theme and needs no signing — it is plain CSS that Firefox loads at
startup because `user.js` sets
`toolkit.legacyUserProfileCustomizations.stylesheets = true`.

This doc is the fettling guide: how to change it, see your changes, and find the
right selectors.

## The two copies (important)

There are two copies of the theme, and you need to know which one matters when.

| Copy | Path | Role |
|------|------|------|
| **Repo (source)** | `chrome/` in this repo | The canonical version. `install.sh` stages this into new profiles. |
| **Master (live)** | `~/.mozilla/dev/chrome/` | What actually gets used. foxbox **clones the master profile** on every launch, so this copy is what each session sees. |

Editing the repo copy does **not** affect running sessions until you stage it
into the master. For fast iteration, edit the **master** copy directly, then copy
your finished result back to the repo (see "Promote when happy" below).

Editing files under `~/.mozilla/dev/chrome/` does **not** trip foxbox's
dirty-master warning — that check only watches `prefs.js`, not `chrome/`.

## Stage the repo copy into the master

"Staging" just means copying the repo `chrome/` files over the master copy at
`~/.mozilla/dev/chrome/`, since the master is what foxbox actually clones and
runs. Do this whenever you want a running session to reflect what's in the repo.

```bash
mkdir -p ~/.mozilla/dev/chrome
cp chrome/userChrome.css chrome/*.svg ~/.mozilla/dev/chrome/
```

The `mkdir -p` is just a safety net — it's harmless if the directory already
exists. Run both lines from the repo root. (`install.sh` does this same copy
automatically when it sets up a fresh profile; this is the manual equivalent for
iterating without re-running the installer.)

## Run it to test, right now

foxbox is already installed and reads the **master** copy, so to see the current
theme just launch a session:

```bash
foxbox about:blank
```

If you've edited the **repo** copy and want to test *that*, stage it into the
master first, then launch:

```bash
cp chrome/userChrome.css chrome/*.svg ~/.mozilla/dev/chrome/ && foxbox about:blank
```

Close the window when you're done; the session is ephemeral and leaves nothing
behind.

## The edit loop

`userChrome.css` is read **once, at startup**. There is no live reload, so each
change needs a fresh launch — which foxbox gives you anyway, since every launch
is a new clone.

1. Edit `~/.mozilla/dev/chrome/userChrome.css`.
2. Launch a session: `foxbox about:blank`
3. Look. Close it. Back to step 1.

To save typing while iterating, edit the master copy in your editor of choice:

```bash
$EDITOR ~/.mozilla/dev/chrome/userChrome.css
```

### Promote when happy

When the master copy looks right, copy it (and any changed/added SVGs) back into
the repo so `install.sh` ships your version:

```bash
cp ~/.mozilla/dev/chrome/userChrome.css chrome/userChrome.css
# if you added or changed image assets, copy those too, e.g.:
# cp ~/.mozilla/dev/chrome/<asset>.svg chrome/
```

## The fast way to find selectors: the Browser Toolbox

Editing chrome CSS blind is painful. The **Browser Toolbox** is a second devtools
window that inspects Firefox's *own UI* — you can hover over a toolbar button and
see its ID, and live-edit CSS rules that apply **instantly, no restart**. This is
by far the best way to work out a selector or trial a colour before committing it
to `userChrome.css`.

Enable it once (in a foxbox session, via `about:config`):

- `devtools.chrome.enabled = true`
- `devtools.debugger.remote-enabled = true`

Then open it with **Ctrl+Alt+Shift+I**. (It asks for confirmation the first time.)
Use the inspector's element picker on the toolbar to find IDs like `#nav-bar`,
`#TabsToolbar`, `#urlbar`. Tweak rules in the Rules pane until it looks right,
then paste the working declarations into `userChrome.css`.

> These two prefs open a privileged debugging surface. Fine to flip in an
> ephemeral session for fettling; don't bake them into `user.js`.

## How the current file is built

`userChrome.css` has three sections. Each is commented inline, and every value
meant to be tuned is flagged `-- tune --`.

1. **Lightweight-theme variables** (`:root { --lwt-* … }`)
   Firefox's own chrome CSS reads these variables, so setting them recolours the
   toolbars, tabs, icons, and address bar — the same levers a real theme pulls.
   This is where the frame/toolbar/text colours live.

2. **Toolbox background** (`#navigator-toolbox`)
   The dark fill plus two stacked background layers: the fox mark
   (`foxbox.svg`, pinned top-right) on top, the circuit pattern (`bg.svg`, tiled)
   beneath. `#TabsToolbar` is made transparent so these show through the tab strip.

3. **Accent line** (`#nav-bar`)
   The orange rule under the address bar.

## Common edits

**Change the accent colour** — section 3, the `border-bottom` colour:
```css
#nav-bar { border-bottom: 2px solid #e66000 !important; }  /* try #00b3a4, etc. */
```

**Change frame / toolbar / text colours** — section 1:
```css
--lwt-accent-color: #1a1a1a !important;   /* window frame        */
--toolbar-bgcolor:  rgba(51,51,51,0.45) !important;  /* nav bar  */
--toolbar-color:    #ffffff !important;   /* toolbar text/icons  */
```

**Make the pattern show through more / less** — lower the *alpha* (last number)
of `--toolbar-bgcolor` to reveal more pattern through the nav bar; raise it
toward `1.0` for a more solid, legible bar.

**Move or resize the fox mark** — section 2, the first layer of
`background-position` and `background-size`:
```css
background-position: right 14px top 4px, left top !important;  /* fox, then tile */
background-size:     auto 24px,          100px 100px !important; /* fox height, tile */
```
`right 14px top 4px` pins it 14 px from the right, 4 px from the top; `auto 24px`
sets its height. Increase the height and it grows; change `right`→`left` to move it.

**Swap the background pattern** — drop a new SVG beside `userChrome.css`, then
point the second layer at it:
```css
background-image: url("foxbox.svg"), url("my-pattern.svg") !important;
```
The alternate patterns you set aside (`circuit.svg`, `foxbox_bg.svg`, …) are in
`cruft/` — copy one into `~/.mozilla/dev/chrome/` to try it.

**Remove a piece** — delete its rule. Drop the whole `#nav-bar` rule for no accent
line; remove the first background layer (and its position/size/repeat entries) for
no fox mark.

## Gotchas

- **Restart to see changes.** `userChrome.css` is read only at startup. A running
  session won't pick up edits — relaunch.
- **`!important` is usually required.** Firefox already styles these elements, so
  your rule has to outweigh the built-in one.
- **Paths are relative to `chrome/`.** Any image you reference must sit in the same
  directory as `userChrome.css`, in both the repo and the master copy.
- **Selectors drift between Firefox versions.** This targets Firefox 151. After a
  major Firefox update, if something looks broken, re-check the IDs with the
  Browser Toolbox — Mozilla renames chrome elements occasionally.
- **Keep the two copies in sync.** The master is what you see; the repo is what
  ships. Promote your finished master copy back to the repo when you're happy.
