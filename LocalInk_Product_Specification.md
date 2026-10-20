# LocalInk Product Specification

- **Product:** LocalInk
- **Platform:** macOS 13 or newer
- **Current release:** 1.0.1 (build 1)
- **Document status:** Current shipped product specification
- **Last updated:** 2026-10-20

## 1. Product summary

LocalInk is a native, offline macOS screen-annotation app for presentations,
teaching, support calls, design reviews, and screen recordings. It places a
transparent drawing layer over the desktop so the presenter can draw, highlight,
spotlight, and zoom without switching apps or interrupting the application
underneath.

The core promise: **make a point on screen without interrupting the work
underneath.**

LocalInk is free and open source under the MIT license. It has no account,
subscription, telemetry, analytics, automatic upload, or runtime network
requirement.

## 2. Current release status

Version 1.0.1 is shipped and distributed as a universal ZIP and DMG. The
marketing website is live and supports English and Vietnamese.

| Area | Status | Notes |
|---|---|---|
| Menu-bar lifecycle and drawing toggle | Shipped | Status item, global shortcuts, and visible controls window |
| Drawing tools | Shipped | Pen, arrow, line, rectangle, ellipse, highlighter, text, redaction, counter, eraser, selection |
| Editing | Shipped | Undo/redo, move, delete, copy, paste |
| Cursor halo and click ripples | Shipped | Click-through |
| Spotlight | Shipped | Click-through aperture |
| Whiteboard | Shipped | Separate canvas and background color |
| Floating toolbar | Shipped | Tools, colors, width, effects, undo/redo, clear |
| Settings | Shipped | Native tabbed preferences window |
| Global shortcuts | Shipped | Configurable, with conflict reporting and defaults restoration |
| Display handling | Shipped | One overlay per display; annotations survive display changes |
| Magnifier and full-screen zoom | Shipped | Optional; requires Screen Recording permission |
| PNG, clipboard, and SVG export | Shipped | LocalInk windows excluded from captures |
| Session retention | Shipped | Until quit by default; opt-in restore after relaunch |
| Website localization | Shipped | English and Vietnamese |
| App UI localization | Not shipped | The macOS app interface is currently English-only |
| Developer ID notarization | Not shipped | The 1.0.1 build is ad-hoc signed; Gatekeeper guidance is provided |

## 3. Product principles

1. **Instant control.** Drawing can be toggled with one shortcut, menu action, or
   the Start Drawing button.
2. **Safe interaction.** When drawing is off, LocalInk must not intercept clicks,
   drags, or scrolling.
3. **Local privacy.** Core functions work without an account, network connection,
   analytics, or uploading screen content.
4. **Clear permission boundaries.** Drawing, halo, and spotlight work without
   screen capture. Screen Recording is requested only for zoom and export.
5. **Reliable display behavior.** Overlays, marks, and pointer effects stay
   aligned across displays, resolutions, Spaces, and scaling factors.
6. **Honest status.** Documentation, release notes, and the website describe only
   features that are actually shipped, and call out limitations.

## 4. Intended users

- Educators marking up slides or code while teaching.
- Presenters pointing out controls in a live product demonstration.
- Designers and reviewers drawing attention to an interface.
- Support staff walking someone through on-screen steps.
- Creators recording annotated desktop tutorials.
- Developers explaining a code path, log line, or small detail.

## 5. User experience

### 5.1 Launch and entry points

- By default, opening LocalInk shows a native **controls window** with a **Start Drawing**
  button, Settings, a startup-window preference, and an optional Dock icon.
- The window can be reopened from **Welcome & Controls…** in the menu-bar menu or
  by reopening the app.
- Start Drawing enables drawing, shows the floating toolbar, and closes the
  controls window.
- LocalInk otherwise lives as a pencil icon in the menu bar.
- A status-icon fallback (`Ink`) prevents the entry point from becoming invisible
  if an SF Symbol is unavailable.

### 5.2 Interaction states

```text
annotation:        off | drawing | temporaryPassThrough
activeTool:        pen | arrow | line | rectangle | ellipse | text |
                   highlighter | redact | counter | eraser | select
halo:              off | on
spotlight:         off | on
zoom:              off | lens | fullscreen
whiteboard:        off | on
capturePermission: unchecked | allowed | denied
```

Halo, spotlight, and zoom may be active independently of drawing. Displaying an
effect and capturing pointer input are separate decisions.

| State | Pointer behavior |
|---|---|
| Idle | All clicks, drags, and scrolling reach the underlying app |
| Halo or spotlight only | Effects follow the pointer; the underlying app remains fully interactive |
| Drawing active | A gesture creates or edits a mark; the underlying app does not receive it |
| Select active | Empty areas pass clicks and drags to the underlying app; annotations can be selected and moved |
| Temporary pass-through | The gesture goes to the underlying app, then drawing resumes |
| Hold Command while drawing | Temporarily click through; releasing Command restores drawing |
| Toolbar or controls window | Only that window accepts the click; surrounding space follows the current mode |

### 5.3 Drawing and editing

- Pen, arrow, line, rectangle, ellipse, highlighter, text, solid redaction,
  sequential counter, eraser, and selection.
- Shift constrains squares, circles, and 45° arrow snapping.
- Adjustable color, stroke width, and opacity; style changes never recolor older
  marks.
- Auto-erase after a configurable delay, or keep marks until cleared.
- Command-based undo and redo for marks, moves, deletes, clears, pastes, and
  eraser gestures.
- Select, move, delete, copy, and paste annotations.
- With Select active, empty areas pass mouse input to the app underneath; annotations remain selectable and draggable.
- Marks retain their canvas identity across undo, redo, paste, and whiteboard
  changes.

### 5.4 Attention and presentation effects

- Cursor halo with configurable color, size, opacity, and ring-only mode.
- Click ripples for visible feedback.
- Spotlight dims the screen outside an aperture around the pointer.
- Halo and spotlight are click-through: buttons and fields underneath stay
  usable.
- Pointer effects work across multiple displays.

### 5.5 Whiteboard, zoom, and export

- Whiteboard uses an opaque, configurable background and a separate mark list.
- Whiteboard marks and background are included in PNG, clipboard, and SVG export.
- Cursor-following magnifier and full-screen zoom use ScreenCaptureKit.
- Annotated PNG export and clipboard copy combine the captured display with the
  active canvas.
- SVG export preserves display width, arrowheads, highlighter styling, text
  wrapping, and opacity.
- LocalInk's own windows (overlays, toolbar, lens, settings, controls, alerts) are
  excluded from captures.
- Capture streams stop when zoom ends, the app quits, or the Mac sleeps.

### 5.6 Preferences and session behavior

Settings are stored in `UserDefaults` and include:

- default tool, color, stroke width, opacity, and auto-erase delay
- halo appearance
- spotlight size and dim level
- whiteboard color
- lens size and zoom factor
- launch at login and optional Dock icon
- startup controls-window preference
- session retention, shortcut mappings, and export folder

Session retention:

- **Until I quit LocalInk** (default) — drawings are discarded on quit.
- **Until I clear the screen** — drawings are persisted locally and restored on
  the next launch.

## 6. Keyboard shortcuts

Global shortcuts work while LocalInk is in the background. They can be changed in
**Settings → Shortcuts**; conflicts are reported in the menu.

| Shortcut | Action |
|---|---|
| `⌃⌥D` | Toggle drawing |
| `⌃⌥H` | Toggle cursor halo |
| `⌃⌥L` | Toggle spotlight |
| `⌃⌥Z` | Undo |
| `⌃⌥Y` | Redo |
| `⌃⌥K` | Clear all drawings |
| `⌃⌥P` | Toggle temporary click-through |
| `⌃⌥T` | Show or hide the toolbar |

While drawing is active:

| Key | Tool | Key | Tool |
|---|---|---|---|
| `P` | Pen | `T` | Text |
| `A` | Arrow | `X` | Redact |
| `L` | Line | `N` | Counter |
| `R` | Rectangle | `E` | Eraser |
| `O` | Ellipse | `V` | Select |
| `H` | Highlighter | `C` | Cycle color |

| Key | Action |
|---|---|
| `[` / `]` | Decrease / increase width |
| `Delete` | Delete the selection, or the last mark |
| `Escape` | Deselect, or exit drawing |
| `⌘Z` / `⇧⌘Z` | Undo / redo |
| `⌘C` / `⌘V` | Copy / paste selection |
| `⌘R` | Reset the counter |
| Hold `⌘` | Temporarily click through to the app underneath |

## 7. Permissions, privacy, and distribution

- Drawing, halo, and spotlight do not require Screen Recording permission.
- Magnifier, full-screen zoom, PNG export, and clipboard image capture require
  Screen Recording permission. Permission denial leaves the rest of the app
  usable.
- The app contains no telemetry, analytics, account system, or runtime network
  access.
- Raw keystrokes, pointer histories, captured images, and clipboard contents are
  not logged.
- Images are written only where the user chooses.
- Export occurs locally; screen content is not uploaded.
- Builds are ad-hoc signed. They are not notarized with a paid Apple Developer
  account, so macOS may require **System Settings → Privacy & Security → Open
  Anyway** or `xattr -dr com.apple.quarantine /Applications/LocalInk.app` on first
  launch.
- When sharing a screen, sharing the entire display generally captures overlays;
  sharing a single app window may not. Users should verify in their meeting or
  recording app.

## 8. Technical architecture

LocalInk is a native Swift/AppKit application built without an Xcode project or
web runtime.

| Component | Responsibility |
|---|---|
| `AppCoordinator` | Menu bar, lifecycle, actions, export flow, onboarding |
| `ControlWindowController` | Visible Start Drawing and controls window |
| `StateController` | Active modes and the input-capture decision |
| `OverlayCoordinator` | One panel per display, undo/redo, session, model mutations |
| `DrawingOverlay` | Rendering and pointer input for one display |
| `Annotation` | Vector model, tools, hit-testing |
| `Renderer` | Shared live and export drawing |
| `CaptureService` | ScreenCaptureKit permission and capture |
| `ExportService` | PNG, clipboard, and SVG composition |
| `LensController` | Magnifier and full-screen zoom |
| `ToolbarController` | Floating toolbar |
| `SettingsController` | Native settings window |
| `HotkeyManager` | Global Carbon shortcuts |
| `Preferences` | UserDefaults and shortcut migration |

Annotations use logical points in each display's bottom-left coordinate space.
Exports map points to backing pixels with an explicit scale; SVG applies an
explicit Y flip. Live drawing and PNG export share `Renderer`.

## 9. Compatibility

- macOS 13 Ventura or later.
- Apple Silicon and Intel (universal binary).
- Multiple displays, including mixed scaling and negative origins.
- Fullscreen apps and Spaces.
- Keynote, PowerPoint, Google Slides, Zoom, Google Meet, OBS, Figma, VS Code,
  PDFs, and other desktop apps.

## 10. Quality and acceptance

Current automated tests cover geometry and hit-testing, rendering, PNG
composition, SVG output, multiline text layout, and whiteboard export. Manual
acceptance should verify:

- Launch shows the controls window; Start Drawing enables drawing.
- Drawing, halo, and spotlight work with Screen Recording permission denied.
- Click-through works when drawing is off, and during temporary pass-through.
- Marks stay aligned across mixed-scale displays and survive display changes.
- Session drawings restore only when the retention setting requests it.
- PNG, clipboard, and SVG exports match the live overlay and exclude LocalInk
  controls.
- Zoom starts and stops without leaving a capture stream or stuck overlay.

Engineering targets, not measured guarantees:

| Target | Goal |
|---|---|
| Drawing response | p95 under 35 ms on reference hardware |
| Pointer effects | 60 fps target on a normal display |
| Idle CPU | Below 1% of one core after settling |
| Idle memory | Below 80 MB after warm-up |
| Capture resources | No stream running while zoom is off |
| Stability | Two-hour presentation session without input deadlock |

## 11. Known limitations

- The app interface is English-only; the website is available in English and
  Vietnamese.
- The distributed 1.0.1 build is ad-hoc signed and not notarized because no Developer ID account is available. The release scripts are ready for notarized builds once credentials are supplied.
- Sharing a single app window may not include the overlay.
- LocalInk does not record video, provide cloud whiteboards, collaboration, slide
  editing, or AI features.
- There is no automatic update channel.
- PNG, clipboard, and SVG are the available export formats.
- Protected content may capture as blank; this is an OS limitation.

## 12. Roadmap

Future work is planned, not shipped:

1. Developer ID signing and notarization for frictionless first launch.
2. App UI localization, including Vietnamese.
3. Expanded accessibility and keyboard-only QA.
4. Additional onboarding and in-app shortcut help.
5. Further performance and multi-display validation on a documented hardware
   matrix.

## 13. Release and documentation rules

- Release notes and the website must reflect the shipped version and known
  limitations.
- A feature is not described as available until its acceptance check passes.
- Behavior or default changes must update the README, this specification, and the
  changelog.
- The product remains offline by default; any future network feature requires an
  explicit privacy and product decision.
