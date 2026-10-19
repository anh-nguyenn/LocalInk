# Changelog

All notable changes to LocalInk are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] — 2026-10-20

### Fixed

- Opening LocalInk now shows a visible controls window with a **Start Drawing**
  button, so the app is usable even if the menu-bar icon is missed. The window
  can be reopened from **Welcome & Controls…** in the menu or by reopening the
  app.
- Drawing activation now uses the modern app-activation API, and the status icon
  falls back to an “Ink” title if an SF Symbol is unavailable.
- Added a startup checkbox and optional Dock icon to the controls window.

### Documentation

- Redesigned the marketing website with a modern product layout, new visuals, and
  an English/Vietnamese language toggle.
- Refreshed the README, product specification, and contributing guide to match
  the shipped 1.0.2 product and its known limitations.

## [1.0.1] — 2026-10-20

### Fixed

- Text annotations can be typed, edited, and selected: overlay panels are now
  key-capable.
- Exports and the magnifier capture at the display's real pixel size instead of
  ScreenCaptureKit's 1920×1080 default.
- Turning drawing off while the whiteboard is visible no longer leaves a
  click-through white sheet over the desktop.
- Whiteboard annotations and background are included in PNG, clipboard, and SVG
  export.
- The macOS 13 single-shot capture path can no longer hang or resume its
  continuation twice.
- Settings, lens, and other LocalInk windows are excluded from captures.
- Multi-line and wrapped text render and export consistently.
- Undo, redo, paste, and eraser undo keep marks on their original canvas.
- Display configuration changes preserve annotations instead of clearing them.
- The "Until I clear the screen" session setting now persists and restores
  drawings.
- SVG exports include display width, arrowheads, highlighter styling, text
  wrapping, and correct opacity.
- The magnifier is no longer vertically flipped.
- Auto-erase participates in undo/redo and restarts the expiry clock when a mark
  is restored.
- The pointer timer stops when no effect needs it, and the shortcut recorder
  rejects global hotkeys without a modifier.
- Releasing Command reliably restores drawing after a click-through, even when
  the click activated another app.

## [1.0.0] — 2026-10-20

First public release.

### Added

- Native macOS menu-bar app with a per-display transparent overlay and reliable
  click-through when drawing is off.
- Drawing tools: pen, arrow, line, rectangle, ellipse, highlighter, text, solid
  redaction, sequential counter, eraser, and selection.
- Constrained shapes and 45° arrow snapping with Shift.
- Command-based undo and redo, plus select, move, delete, copy, and paste.
- Cursor halo with size, color, opacity, and ring-only controls, plus click ripples.
- Spotlight that dims the screen outside an aperture around the pointer.
- Whiteboard with a separate canvas and configurable background.
- Floating toolbar for tools, colors, width, effects, and clear.
- Native settings window with panes for general, drawing, cursor, spotlight,
  whiteboard, zoom and capture, shortcuts, export, and about.
- Customizable global shortcuts with conflict reporting and defaults restoration.
- Single-key tool shortcuts, color cycling, and width stepping while drawing.
- Cursor magnifier and full-screen zoom using ScreenCaptureKit.
- Annotated PNG export, clipboard copy, and SVG export with LocalInk controls
  excluded from captures.
- Screen Recording permission handling with clear guidance when denied.
- Auto-erase, temporary click-through, launch at login, and an optional Dock icon.
- Universal build for Apple Silicon and Intel, ad-hoc signed and packaged as a
  ZIP and DMG.
- Headless logic tests for geometry, rendering, and export composition.
- Marketing website with an animated product demo.

[1.0.2]: https://github.com/anh-nguyenn/LocalInk/releases/tag/v1.0.2
[1.0.1]: https://github.com/anh-nguyenn/LocalInk/releases/tag/v1.0.1
[1.0.0]: https://github.com/anh-nguyenn/LocalInk/releases/tag/v1.0.0
