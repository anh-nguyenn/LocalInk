# LocalInk — offline macOS Presentify-style starter app

A native menu-bar application that draws on a transparent, always-on-top overlay across your Mac screens. **No server, cloud, Python, Node, or subscription.**

## Requirements

- macOS 13 or newer
- Xcode Command Line Tools (`xcode-select --install` if not installed)

## Build and run

Open Terminal in this folder, then:

```bash
./build.sh
open dist/LocalInk.app
```

The app appears as a pencil icon in your **menu bar**, not in the Dock. Click it to pick a drawing tool/color.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Control + Option + D | Toggle draw mode (on = mouse draws; off = click-through) |
| Control + Option + H | Toggle cursor highlight ring |
| Control + Option + L | Toggle spotlight |
| Control + Option + Z | Undo most recent stroke in last active display |
| Control + Option + K | Clear drawings on every display |

Menu-bar submenu: choose Pen / Arrow / Rectangle / Ellipse and Red / Yellow / Green / Blue / White.

## What is implemented

- Native `.app` bundle, status bar utility
- Fullscreen transparent AppKit overlays, one per display
- Freehand drawing, arrows, rectangles, ellipses
- Cursor halo, spotlight with dimmed background
- Click-through when draw mode is disabled
- Global shortcuts without logging all keyboard input
- Undo and clear
- Everything runs locally; no networking code, accounts, or telemetry

## What is *not* implemented yet

- Magnifier/zoom (requires proper screen capture using Apple's ScreenCaptureKit and user permission)
- Screenshot export, text, whiteboard, permanent settings, auto-fade, polished settings UI
- Advanced annotated screenshot handling, per-display adaptive scaling, copy/paste, notarized distribution

This is a **starter**, not a feature-complete Presentify clone.

## Practical notes

- The drawing overlay intentionally captures mouse clicks while Draw mode is enabled; press `Control+Option+D` again to interact with other apps. Spotlight/halo can stay visible.
- Drawing strokes are in RAM and are lost on app quit or if monitors are reconfigured.
- macOS may warn about an unsigned app. Build locally from source and launch using `open dist/LocalInk.app`. For redistribution, sign and notarize the app with an Apple Developer account.
- For video calls, sharing the *entire screen* generally works better than sharing just one application window for desktop overlays. Verify behavior in your preferred meeting/recording app.
- The app has been compiled on macOS 26.6.2 with Xcode 27.1. Its menu-bar behavior has not yet been verified in a normal desktop session.

## Suggested next features

1. On-screen tool palette with width and opacity controls
2. User-configurable hotkeys and persisted preferences
3. ScreenCaptureKit magnifier and screenshot exporter
4. Annotation selection and drag / laser pointer
5. Apple Silicon universal release packaging, signing, notarization
