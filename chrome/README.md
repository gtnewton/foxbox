# Editing the foxbox chrome theme

The foxbox "theme" is plain CSS that restyles Firefox's own toolbar/tab UI (the
*chrome*) and the new-tab page, plus the image assets it references. It is not a
WebExtension theme and needs no signing — Firefox loads it at startup because
`user.js` sets `toolkit.legacyUserProfileCustomizations.stylesheets = true`.

The pieces:

- `userChrome.css` — restyles the toolbar/tab UI. References `foxbox.svg` (fox
  mark) and `bg.svg` (tiled circuit pattern).
- `userContent.css` — restyles `about:home` / `about:newtab`. References
  `foxbox.svg` and `foxbox_bg.jpg` (full-page background).
- `bg.svg`, `foxbox_bg.jpg` — theme assets, kept here in `chrome/`.
- `foxbox.svg` — shared with the app launcher icon, so it lives at the **repo
  root**, not in `chrome/`. `install.sh` stages it into the profile's `chrome/`
  alongside the others. In a *live profile* all assets sit together in `chrome/`;
  only in the *repo* does `foxbox.svg` live one level up.

This doc is the fettling guide: how to change it, see your changes, and find the
right selectors.

## The two copies (important)

There are two copies of the theme, and you need to know which one matters when.

| Copy | Path | Role |
|------|------|------|
| **Repo (source)** | this repo (`chrome/` + root `foxbox.svg`) | The canonical version. `install.sh` stages this into new profiles. |
| **Master (live)** | `~/.mozilla/dev/chrome/` | What actually gets used. foxbox **clones the master profile** on every launch, so this copy is what each session sees. |

Editing the repo copy does **not** affect running sessions until you stage it
into the master. For fast iteration, edit the **master** copy directly, then copy
your finished result back to the repo (see "Promote when happy" below).

Editing files under `~/.mozilla/dev/chrome/` does **not** trip foxbox's
dirty-master warning — that check only watches `prefs.js`, not `chrome/`.

## Stage the repo copy into the master

"Staging" means copying the repo theme files over the master copy at
`~/.mozilla/dev/chrome/`, since the master is what foxbox actually clones and
runs. Do this whenever you want a running session to reflect what's in the repo.
Run from the repo root:

```bash
mkdir -p ~/.mozilla/dev/chrome
cp chrome/userChrome.css chrome/userContent.css chrome/bg.svg chrome/foxbox_bg.jpg ~/.mozilla/dev/chrome/
cp foxbox.svg ~/.mozilla/dev/chrome/
```

Note `foxbox.svg` comes from the repo root, the rest from `chrome/`. The
`mkdir -p` is a harmless safety net. (`install.sh` does this same copy
automatically when it sets up a fresh profile; this is the manual equivalent for
iterating without re-running the installer.)

## Run it to test, right now

foxbox is already installed and reads the **master** copy, so to see the current
theme just launch a session:

```bash
foxbox about:blank
```

If you've edited the **repo** copy and want to test *that*, stage it into the
master first (see above), then launch.

Close the window when you're done; the session is ephemeral and leaves nothing
behind.

## The edit loop

`userChrome.css` and `userContent.css` are read **once, at startup**. There is no
live reload, so each change needs a fresh launch — which foxbox gives you anyway,
since every launch is a new clone.

1. Edit the **master** copy, e.g. `~/.mozilla/dev/chrome/userChrome.css`.
2. Launch a session: `foxbox about:blank`
3. Look. Close it. Back to step 1.

To save typing while iterating, point your editor at the master copy:

```bash
$EDITOR ~/.mozilla/dev/chrome/userChrome.css
```

### Promote when happy

When the master copy looks right, copy it (and any changed/added assets) back
into the repo so `install.sh` ships your version:

```bash
cp ~/.mozilla/dev/chrome/userChrome.css  chrome/userChrome.css
cp ~/.mozilla/dev/chrome/userContent.css chrome/userContent.css
# changed image assets too — note foxbox.svg goes back to the repo root:
# cp ~/.mozilla/dev/chrome/bg.svg         chrome/bg.svg
# cp ~/.mozilla/dev/chrome/foxbox_bg.jpg  chrome/foxbox_bg.jpg
# cp ~/.mozilla/dev/chrome/foxbox.svg     foxbox.svg
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

## How `userChrome.css` is built

The file is organised top-to-bottom as:

1. **Lightweight-theme variables** (`:root { --lwt-* … }`)
   Firefox's own chrome CSS reads these variables, so setting them recolours the
   toolbars, tabs, icons, and address-bar field. This is where the frame, text,
   url-field, and focus-ring colours live. The accent throughout is purple,
   `rgba(105,60,185, …)`.

2. **Toolbox background** (`#navigator-toolbox`)
   A translucent dark fill plus two stacked background layers: the fox mark
   (`foxbox.svg`, pinned near the top-right) over the circuit pattern
   (`bg.svg`, tiled) beneath. `#TabsToolbar` and `#nav-bar` are made transparent
   so both layers show through the toolbar strip.

3. **Window controls** (`.titlebar-button`)
   The min/max/close icons restyled as translucent pills.

4. **Tabs** (`.tab-background`)
   Inactive tabs get a faint purple wash; the selected tab a stronger one.

5. **Address bar** (`#urlbar-background`)
   Transparent field with a solid purple border. A trailing `toolbarspring`
   spacer reserves room so the url bar doesn't slide under the fox mark.

## Common edits

**Change the accent colour** — it's the purple `rgba(105,60,185, …)` repeated in
the tab backgrounds (section 4), the url-bar border (section 5), and the
`--focus-outline-color` variable (section 1). Replace those to recolour the theme:
```css
--focus-outline-color: rgba(105,60,185,0.9) !important;  /* try rgba(0,179,164,0.9) */
```

**Change frame / text colours** — section 1:
```css
--lwt-accent-color: #1a1a1a !important;   /* window frame       */
--lwt-text-color:   #ffffff !important;   /* toolbar text/icons */
```

**Make the pattern show through more / less** — raise or lower the alpha on
`#navigator-toolbox { background-color: rgba(0,0,0,.25) … }` (section 2): toward
`0` reveals more pattern, toward `1` makes the bar more solid.

**Move or resize the fox mark** — section 2, the first layer of
`background-position` and `background-size`:
```css
background-position: right 188px top -32px, left top !important;  /* fox, then tile */
background-size:     auto 180px,            100px 100px !important; /* fox height, tile */
```
`right 188px top -32px` pins the fox; `auto 180px` sets its height. Increase the
height and it grows; change `right`→`left` to move it.

**Swap the background pattern** — drop a new SVG into `chrome/` (repo) and the
master's `chrome/` (live), then point the second layer at it:
```css
background-image: url("foxbox.svg"), url("my-pattern.svg") !important;
```
The alternate patterns set aside during development are in `cruft/` — copy one
into `~/.mozilla/dev/chrome/` to try it.

**Remove a piece** — delete its rule. Remove the first background layer (and its
matching position/size/repeat entries) in section 2 for no fox mark.

## Gotchas

- **Restart to see changes.** The stylesheets are read only at startup. A running
  session won't pick up edits — relaunch.
- **`!important` is usually required.** Firefox already styles these elements, so
  your rule has to outweigh the built-in one.
- **Assets are referenced relative to the stylesheet.** Any image a stylesheet
  references must sit in the same `chrome/` dir in the *master profile*. In the
  repo that means `chrome/` for `bg.svg`/`foxbox_bg.jpg` but the **root** for
  `foxbox.svg` — `install.sh` reconciles the two when it stages the profile.
- **Selectors drift between Firefox versions.** This targets Firefox 151. After a
  major Firefox update, if something looks broken, re-check the IDs with the
  Browser Toolbox — Mozilla renames chrome elements occasionally.
- **Keep the two copies in sync.** The master is what you see; the repo is what
  ships. Promote your finished master copy back to the repo when you're happy.
