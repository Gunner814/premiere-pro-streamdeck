# Premiere Pro — Stream Deck + XL

A Stream Deck plugin and profile for Adobe Premiere Pro (Windows), built for the
**Stream Deck + XL** (9×4 keys, 6 dials, touch strip). Same stack as
[lightroom-classic-pro-streamdeck](https://github.com/Gunner814/lightroom-classic-pro-streamdeck): Node/TypeScript on
Elgato's SDK.

- **Keys** use Stream Deck's built-in Hotkey / Page actions, so they work with no plugin.
- **Dials** use this repo's **Timeline Dial** action, which gives full control of rotate / push /
  touch (the built-in Hotkey action only fires on dial press).
- Keystrokes are sent **only while Premiere Pro is the foreground app**.

Shortcuts are Premiere's **default Windows keyboard shortcuts**. If you customised yours, edit
`scripts/build-profile.ps1` (keys) or `src/modes.ts` (dials).

## Dials (same on every page)

| Dial | Mode | Turn | Press |
|---|---|---|---|
| 1 | Frame scrub | ← / → (accelerates on fast spins) | **Cut at playhead** (Ctrl+K) |
| 2 | Fast scrub | Shift+← / → (5 frames) | **Cut at playhead** (Ctrl+K) |
| 3 | Edit-to-edit | ↑ / ↓ | Cut all tracks (Ctrl+Shift+K) |
| 4 | Timeline zoom | − / = | Fit sequence (`\`) |
| 5 | JKL shuttle | J / L | Stop (K) |
| 6 | Undo / Redo | Ctrl+Z / Ctrl+Shift+Z | Save (Ctrl+S) |

Tapping any dial's **touch strip** = Play / Pause. Each dial's mode can be changed in Stream Deck's
property inspector.

## Keys (text only, one colour per row)

**Page 1, Edit** (most-used keys on the left; bottom row is closest to the hand)
| Row | Category | Keys |
|---|---|---|
| 1 | Cut (red) | Cut at Playhead · Cut All Tracks · Delete + Close Gap · Delete (Keep Gap) · Trim Back / Fwd (ripple-trim the neighbouring edit to the playhead, Q / W) · Extend Edit (E, extend the selected edit to the playhead) · Lift · Extract |
| 2 | Tools (green) | Select · Razor · Ripple Edit · Rate Stretch · Slip · Slide · Pen · Hand · Zoom Tool |
| 3 | Undo / Marks (amber) | **Undo · Redo** · Mark In · Mark Out · Clear In/Out · Add Marker · Snap · Save · **MORE >** |
| 4 | Playback (blue) | **PLAY / PAUSE (bottom-left)** · Back 1 · Fwd 1 · Back 5 · Fwd 5 · Previous Edit · Next Edit · Play Reverse · Play Forward |

**Page 2, More**: Clip (purple: speed, link, group, transition, enable/disable, render) ·
Clipboard (grey) · Project (amber: import, export, save as, new bin, **< BACK**) · View (blue: go to
In/Out, match frame, timeline zoom, fit, maximize panel). **< BACK** sits in the same spot as **MORE >**.

## Build & install

```powershell
npm install
npm run icons      # placeholder icons
npm run build      # bundles src/ -> com.gunner814.premiere-pro.sdPlugin/bin/plugin.js

# Quit Stream Deck first (tray icon > Quit), then:
.\scripts\build-profile.ps1 -Install
```

`-Install` backs up your `ProfilesV3` folder to `Documents\StreamDeck-backup-<timestamp>`, replaces
only a previous "Premiere Pro" profile made by this script (your other profiles are untouched),
adds the new profile, and copies the plugin into Stream Deck's `Plugins` folder. Then start Stream
Deck and pick **Premiere Pro** in the profile dropdown (it also auto-switches when Premiere is
focused). Run without `-Install` to only generate the profile into `dist/`.

Assumes Premiere Pro 2026 at the default path (override with `-PremiereExe`). The device ID is
copied from an existing Stream Deck + XL profile on the machine.

## How it works

`src/keys.ts` keeps one long-running PowerShell helper (`helpers/keys.ps1`) that taps keys with
`keybd_event`, and ignores input unless the foreground window is `Adobe Premiere Pro`. Fast dial
spins arrive as `ticks > 1`; presses = `round(ticks ^ curve)`, capped per mode (see `src/modes.ts`).

## Roadmap

- [x] 36-key edit page + 27-key "More" page
- [x] Six-dial Timeline Dial plugin (scrub, 5-frame, edit-to-edit, zoom, shuttle, undo)
- [ ] Live timecode on the dial touch strip via a Premiere UXP plugin or the Premiere MCP bridge
  (UXP can't script many native commands, so editing commands stay on keystrokes)
- [ ] Custom key icons
