# Changelog

All notable changes to LocalInk are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-10-20

First public release.

### Added

- Native macOS menu-bar app with a per-display transparent overlay and reliable
  click-through when drawing is off.
- Drawing tools: pen, arrow, line, rectangle, ellipse, highlighter, text, solid
  redaction, sequential counter, eraser, and selection.
- Constrained shapes and 45° line snapping with Shift.
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

[1.0.0]: https://github.com/anh-nguyenn/LocalInk/releases/tag/v1.0.0
