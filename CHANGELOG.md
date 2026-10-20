# Changelog

All notable changes to LocalInk are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] — 2026-10-20

First public release.

### Added

- Native macOS menu-bar app with a transparent, click-through overlay for every
  display.
- A visible controls window with **Start Drawing**, Settings, startup-window
  preference, and an optional Dock icon.
- Drawing tools: pen, arrow, line, rectangle, ellipse, highlighter, text, solid
  redaction, sequential counter, eraser, and selection.
- Shift-constrained squares, circles, and 45° arrow snapping.
- Command-based undo/redo, plus select, move, delete, copy, and paste.
- Select mode passes clicks through empty areas while keeping annotations
  selectable and draggable.
- Cursor halo with size, color, opacity, and ring-only controls, plus click
  ripples.
- Spotlight that dims the screen outside an aperture around the pointer.
- Whiteboard with a separate canvas and configurable background.
- Floating toolbar for tools, colors, width, effects, undo/redo, and clear.
- Native settings window with panes for general, drawing, cursor, spotlight,
  whiteboard, zoom and capture, shortcuts, export, and about.
- Customizable global shortcuts with conflict reporting and defaults restoration.
- Single-key tool shortcuts, color cycling, and width stepping while drawing.
- Cursor magnifier and full-screen zoom using ScreenCaptureKit.
- Annotated PNG export, clipboard copy, and SVG export. LocalInk's own windows
  are excluded from captures.
- Auto-erase, temporary Command click-through, launch at login, and session
  retention.
- Universal build for Apple Silicon and Intel, packaged as a ZIP and DMG.
- Marketing website with English and Vietnamese localization.
- Release tooling that validates Developer ID and notarytool credentials and
  notarizes/staples both distribution formats for future trusted releases.

### Fixed

- Text annotations can be typed, edited, and selected.
- Exports and the magnifier capture at the display's native pixel size.
- Turning drawing off no longer leaves a whiteboard sheet over the desktop.
- Whiteboard annotations and background are included in exports.
- The macOS 13 capture path cannot hang or resume twice.
- Settings, lens, and other LocalInk windows are excluded from captures.
- Multi-line and wrapped text render and export consistently.
- Undo, redo, paste, and eraser undo keep marks on their original canvas.
- Display configuration changes preserve annotations.
- Session retention reliably restores drawings when enabled.
- SVG exports include display width, arrowheads, highlighter styling, wrapping,
  and opacity.
- The magnifier is not vertically flipped and stops cleanly.
- Auto-erase participates in undo/redo.
- Command click-through restores drawing when Command is released.
- The pointer timer stops when no effect needs it, and shortcut recording rejects
  global hotkeys without a modifier.
- Opening LocalInk manually always shows the controls window; the startup-window
  preference now only suppresses it on automatic login launches.
- Overlay windows stop at the menu bar, so drawing never blocks the LocalInk
  status icon.
- Starting drawing from the menu or a shortcut activates LocalInk so Escape and
  keyboard shortcuts keep working.

### Notes

- This build is **ad-hoc signed and not notarized** because no Apple Developer
  account is available. If macOS blocks the first launch, use the official
  Gatekeeper guidance in the README and packaged Read Me.
- Older 1.0.0 and 1.0.2 test releases are retained as archived pre-releases on
  GitHub for reference; this 1.0.1 release is the first public release.

[1.0.1]: https://github.com/anh-nguyenn/LocalInk/releases/tag/v1.0.1
