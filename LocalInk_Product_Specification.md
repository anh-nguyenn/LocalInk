# LocalInk Product Specification

**Product:** LocalInk  
**Platform:** macOS 13 or newer  
**Document status:** Product requirements and implementation plan  

## 1. Product definition

LocalInk is a native, offline macOS menu-bar app for drawing and directing attention on top of the desktop during presentations, lessons, demos, and screen recordings. A user can draw over another app, highlight the pointer, or dim the screen around it, then return to normal desktop interaction immediately.

LocalInk is our product. Its name, interface, code, artwork, documentation, and release experience should form a consistent original identity. The core promise is simple: **make a point on screen without interrupting the work underneath.**

### Product principles

1. **Instant control:** Turning drawing on or off should take one shortcut or menu action.
2. **Safe interaction:** When drawing is off, LocalInk must not intercept clicks, drags, or scrolling.
3. **Local privacy:** Core functions work without an account, network connection, analytics, or uploading screen content.
4. **Clear permission boundaries:** Drawing, halo, and spotlight should work without screen capture. Request capture permission only for a feature that needs screen pixels.
5. **Reliable display behavior:** Overlays and pointer effects must remain aligned across supported displays, resolutions, Spaces, and scaling factors.
6. **Honest feature status:** The app and documentation must not expose an unfinished control as though it works.

### Intended users and use cases

- Educators marking up slides or code while teaching.
- Presenters pointing out controls in a live product demonstration.
- Designers and reviewers drawing attention to an interface.
- Support staff walking someone through on-screen steps.
- Creators recording annotated desktop tutorials.

A cloud whiteboard, video recorder, slide editor, collaborative session, and AI assistant are outside the initial product scope.

## 2. Current baseline

The repository currently contains a small AppKit implementation in `Sources/main.swift`, a build script, and an app bundle configuration. `./build.sh` has compiled successfully on macOS 26.6.2 with Xcode 27.1. The menu-bar experience has **not** yet been verified in a normal desktop session, so the items below are code-level status rather than a completed user acceptance test.

| Area | Current code | Next verification or work |
|---|---|---|
| Menu-bar utility | Status item with a tool menu and quit action | Confirm launch, icon visibility, and clean quit on a desktop session |
| Desktop overlay | Transparent `NSPanel` per display | Test click-through, fullscreen apps, Spaces, Retina, and display changes |
| Drawing tools | Pen, arrow, rectangle, ellipse; five colors | Test strokes and shapes in both drag directions |
| Pointer effects | Halo and spotlight | Test pointer alignment and click-through on each display |
| Shortcuts | Global toggles, undo, clear | Test registration, conflicts, and cleanup |
| Undo and clear | Last stroke on last active display; clear all displays | Add redo and command-based editing |
| Settings and export | Not implemented | Design and build as later milestones |
| Zoom and whiteboard | Not implemented | Build only after overlay and input behavior is reliable |

A compiled app is not the same as a tested release. Do not mark a feature complete until its acceptance checks pass in a macOS desktop session.

## 3. Release scope and priorities

**P0 — First usable release:** Safe menu-bar lifecycle, annotation toggle, pen and basic shapes, color and width controls, undo and clear, halo, spotlight, correct multi-display placement, and reliable click-through.

**P1 — Full presenter workflow:** Floating toolbar, redo, selection and moving, text, highlighter, whiteboard, configurable shortcuts and settings, screenshot export, clipboard image, magnifier, and permission handling.

**P2 — Polish:** Click animations, advanced halo shapes, auto-erase, launch at login, presentation presets, optional Dock icon, SVG export, and broader input-device support.

Priorities describe planned work. They do not imply implementation.

## 4. Interaction model

### 4.1 App states

LocalInk should manage these independently:

```text
annotation: off | drawing | temporaryPassThrough
activeTool: pen | arrow | rectangle | ellipse | text | select
halo: off | on
spotlight: off | on
zoom: off | lens | fullscreen
whiteboard: off | on
capturePermission: unchecked | allowed | denied
```

Halo and spotlight may stay active while annotation is off. Displaying an effect and capturing pointer input are separate decisions. The input controller must be the sole authority for whether an overlay receives mouse events.

### 4.2 Pointer routing rules

| State | Pointer behavior |
|---|---|
| App idle | All clicks, drags, and scrolling reach the underlying app |
| Halo or spotlight only | Effects follow the pointer; the underlying app remains fully interactive |
| Drawing active | A drag creates or edits a mark; the underlying app does not receive that gesture |
| Temporary pass-through | The current gesture goes to the underlying app; drawing resumes when the override ends |
| Toolbar interaction | Only the toolbar itself accepts its controls; space outside follows the current mode |
| App quitting or display changing | Input capture is released before overlay teardown |

Mode changes during a drag must finish or cancel the current mark as one action. A half-drawn gesture must never be forwarded to the app underneath. A recovery control must always be available if the overlay captures input unexpectedly.

### 4.3 Representative journeys

1. **Mark up a slide:** Enable drawing, choose a color and rectangle, drag around a detail, then disable drawing to advance the slide.
2. **Call out a control:** Enable halo or spotlight while keeping the destination app clickable.
3. **Correct a mark:** Undo the last drawing action, or select and move an existing item in the later editing release.
4. **Share a result:** Capture the chosen display, combine it with committed annotations, and save or copy the result after permission is granted.
5. **Recover safely:** After sleep, display removal, permission denial, or a shortcut conflict, LocalInk remains quit-able and normal pointer behavior returns.

## 5. Functional requirements

Requirement IDs can be used in issues, implementation notes, and acceptance results.

### 5.1 App lifecycle

| ID | Priority | Requirement | Acceptance check |
|---|---|---|---|
| APP-001 | P0 | Run as a menu-bar utility | Status item appears and app stays alive without a main window |
| APP-002 | P0 | Start with drawing off | Desktop input works normally immediately after launch |
| APP-003 | P0 | Reflect active modes in menu controls | User can tell whether drawing, halo, or spotlight is enabled |
| APP-004 | P0 | Quit completely | Panels, timers, hotkeys, and capture streams stop |
| APP-005 | P1 | Restore saved preferences | Settings load without unexpectedly activating input capture |
| APP-006 | P1 | Provide first-run help | Drawing toggle, menu-bar location, shortcuts, and capture permission are explained |
| APP-007 | P2 | Optional launch at login | Choice persists and can be disabled |

### 5.2 Annotation model and tools

Annotations are vector objects stored in **logical points per display**. Each object records its display identity, tool, geometry, style, creation time, and optional expiry. Conversion to backing pixels happens during rendering or export.

| ID | Priority | Requirement | Acceptance check |
|---|---|---|---|
| ANN-001 | P0 | Pen stroke | Pointer drag produces a continuous mark committed once on release |
| ANN-002 | P0 | Arrow | Drag in any direction produces a line with arrowhead at the end |
| ANN-003 | P0 | Rectangle and ellipse | Negative-direction drags produce correct bounds |
| ANN-004 | P0 | Color presets | Changing color affects future marks without recoloring old ones |
| ANN-005 | P0 | Stroke width | Changing width affects future marks without changing old ones |
| ANN-006 | P0 | Undo last committed mark | One invocation reverses exactly one action |
| ANN-007 | P0 | Clear drawings | Intended display scope is explicit and clear has no partial result |
| ANN-008 | P1 | Redo | New edits invalidate the redo branch |
| ANN-009 | P1 | Constrained shapes | Shift makes a square, circle, or straight line as appropriate |
| ANN-010 | P1 | Highlighter | Translucent stroke emphasizes without hiding content |
| ANN-011 | P1 | Text | User can enter, finish, cancel, select, and edit text |
| ANN-012 | P1 | Select, move, delete | Editing one object leaves other objects unchanged |
| ANN-013 | P1 | Copy and paste objects | Duplicates preserve geometry and style and are undoable |
| ANN-014 | P1 | Persist across mode toggles | Drawings remain until clear, expiry, or the configured end-of-session policy |
| ANN-015 | P2 | Auto-erase | Each mark expires after its own configured delay |
| ANN-016 | P2 | Tablet input | Mouse-equivalent drawing works on tested devices |

An unfinished mark is a preview, not an undo item. Create, move, delete, paste, and clear should each become one undoable command. A small click must not produce a malformed large shape. The drawing renderer should support both the live overlay and image export so they agree on geometry.

### 5.3 Overlays and displays

| ID | Priority | Requirement | Acceptance check |
|---|---|---|---|
| OVR-001 | P0 | Overlay ordinary windows | Marks appear above tested browser, PDF, IDE, and slide windows |
| OVR-002 | P0 | Click-through while drawing off | Click, drag, scroll, and text selection reach the underlying app |
| OVR-003 | P0 | Capture gesture while drawing on | Underlying app does not receive the same pointer gesture |
| OVR-004 | P0 | One correct canvas per display | Negative display origins and mixed scaling do not offset marks |
| OVR-005 | P0 | Recover from display changes | Panels reconcile without leaving invisible input blockers |
| OVR-006 | P1 | Fullscreen and Spaces support | Effects appear in tested presentation contexts without duplicate panels |
| OVR-007 | P1 | Temporary pass-through | User can interact with the underlying app and return to drawing safely |
| OVR-008 | P1 | Floating toolbar | Toolbar controls work without making the rest of the screen a hit target |

### 5.4 Halo and spotlight

| ID | Priority | Requirement | Acceptance check |
|---|---|---|---|
| CUR-001 | P0 | Pointer-following halo | Ring tracks the pointer on the active display |
| CUR-002 | P0 | Click-through halo | A click beneath the ring is delivered once to the underlying app |
| CUR-003 | P0 | Pointer-centered spotlight | Screen dims outside a clear aperture without capturing desktop pixels |
| CUR-004 | P0 | Click-through spotlight | Buttons inside and outside the aperture remain clickable |
| CUR-005 | P1 | Size, color, and opacity controls | Changes apply immediately and persist locally |
| CUR-006 | P1 | Mixed-scale placement | No visible offset when the pointer crosses displays |
| CUR-007 | P2 | Click animations and idle fade | Effects trigger only under configured conditions |

### 5.5 Whiteboard and text

| ID | Priority | Requirement | Acceptance check |
|---|---|---|---|
| WBD-001 | P1 | Enter a blank whiteboard | Opaque background appears behind whiteboard marks |
| WBD-002 | P1 | Set board color | Selected background appears immediately |
| WBD-003 | P1 | Separate board and desktop drawings | Switching modes does not mix unrelated content |
| TXT-001 | P1 | Add and edit text | Editing has clear focus, finish, and Escape behavior |
| TXT-002 | P1 | Style text | Size and color remain attached to the object |

### 5.6 Capture, magnifier, and export

These features require screen pixels and should be behind a permission gate. Drawing, halo, and spotlight continue working if capture permission is denied.

| ID | Priority | Requirement | Acceptance check |
|---|---|---|---|
| CAP-001 | P1 | Capture chosen display | Correct display content is obtained at native scale |
| CAP-002 | P1 | Exclude LocalInk controls from capture | Toolbar and lens do not appear in the source image |
| CAP-003 | P1 | Annotated PNG export | Saved image combines desktop and committed marks once |
| CAP-004 | P1 | Copy annotated image | Image pastes correctly into an image-capable app |
| CAP-005 | P1 | Configurable save location | User chooses a local folder; write failure is reported |
| CAP-006 | P1 | Cursor magnifier | Lens shows enlarged content near the pointer without recursion |
| CAP-007 | P1 | Fullscreen zoom | User can enter and exit without a stuck overlay |
| CAP-008 | P1 | Stop capture when unused | Stream releases resources when zoom or capture ends |
| CAP-009 | P1 | Permission denial and revocation | Clear guidance appears; other features stay usable |

Export pipeline: capture the chosen display while excluding LocalInk windows, render committed annotations at the capture scale, composite in memory, and write PNG or clipboard output. Report success only after the write completes. Protected content may be blank; treat that as an OS limitation and leave the app responsive.

### 5.7 Settings

A native settings panel should organize controls by user task:

| Pane | Controls | Initial behavior |
|---|---|---|
| General | Startup, session retention, menu-bar behavior | Start idle, menu bar visible |
| Drawing | Tool, colors, width, opacity, optional auto-erase | Pen, red, 4 pt, no auto-erase |
| Cursor | Halo shape, size, color, opacity, idle behavior | Ring with visible contrast |
| Spotlight | Aperture size and dim level | Circular aperture |
| Whiteboard | Background color and retention | White board |
| Zoom and capture | Lens size, factor, permission status | Off until requested |
| Shortcuts | Record, disable, restore defaults | Preserve current bindings on upgrade |
| Export | Folder and PNG options | User-selected local destination |
| About and privacy | Version, help, permission guidance | Explain local-only operation |

Preferences belong in `UserDefaults` or application support data. Do not store screen images or sensitive window content in preferences.

## 6. Keyboard shortcuts

### Current bindings

These are the bindings in the existing code and README. They are the compatibility baseline until users can edit shortcuts.

| Shortcut | Action |
|---|---|
| `Control + Option + D` | Toggle drawing |
| `Control + Option + H` | Toggle halo |
| `Control + Option + L` | Toggle spotlight |
| `Control + Option + Z` | Undo the last stroke on the last active display |
| `Control + Option + K` | Clear drawings on all displays |

### Planned shortcut behavior

- Global actions work while LocalInk is unfocused and register only their named combinations.
- Drawing-only keys run only while LocalInk owns the drawing context; they must not intercept typing in another app.
- Preferences can record, disable, and restore mappings. A conflicting mapping shows a clear warning.
- A shortcut migration must preserve existing users' bindings unless they explicitly reset them.
- Losing focus, sleeping, or quitting unregisters context-specific input cleanly.
- A shortcut help view should show the **actual active mapping**, not a hard-coded list.

Use registered hotkeys for standard global combinations. Avoid broad keyboard monitoring for ordinary actions.

## 7. Native macOS design

The existing app uses Swift and AppKit. Continue with a native macOS architecture for the first release.

| Component | Responsibility |
|---|---|
| App coordinator | Menu bar, lifecycle, settings entry point, display reconciliation |
| State controller | Active modes and one authoritative input-capture decision |
| Overlay coordinator | One transparent presentation surface per display |
| Annotation model | Vector objects, display ownership, edit commands, undo/redo |
| Renderer | Consistent live and exported drawing |
| Cursor effects | Halo and spotlight rendering without pointer interception |
| Capture service | ScreenCaptureKit session, permission state, exclusion filters |
| Export service | PNG and clipboard composition, file errors |
| Preferences store | Local settings and shortcut migration |

Keep UI state on the main actor. Run capture and image encoding away from the main thread, then return to the UI thread for status updates. Do not capture a continuous 4K stream just to draw a spotlight mask. Avoid unbounded stroke arrays and undo history.

Use logical points for annotations and explicit transforms for display pixels. Preserve marks when displays change only where coordinates can be mapped safely; otherwise keep them in a recoverable session model instead of silently moving them to the wrong screen.

### Repository evolution

The current `Sources/main.swift` is a compact starting point. As P1 work grows, split the implementation into focused files or modules. Do not require a full Xcode project merely to keep the app buildable; the existing `build.sh` remains a supported local build path until a replacement is tested.

## 8. Privacy, permissions, and distribution

- No account, telemetry, automatic upload, or runtime network requirement in the first release.
- Never log raw keystrokes, pointer histories, captured images, or clipboard contents.
- Ask for Screen Recording permission only when a user starts zoom or screenshot capture.
- Treat capture denial as a normal state and provide a way back to drawing tools.
- Save images only after an explicit user action to a user-selected local location.
- Stop capture streams and input monitors on quit, sleep, and permission loss.
- Use a locally signed development build for testing. Sign and notarize a distributable release before public distribution.
- Explain that sharing a full display and sharing one app window may produce different overlay visibility. Test both before making compatibility claims.

## 9. Quality targets

These are LocalInk engineering targets, not current measurements. Record the Mac model and macOS version used for each result.

| ID | Target | Measurement |
|---|---|---|
| NFR-001 | Drawing response p95 under 35 ms on reference hardware | Pointer event to visible stroke sample |
| NFR-002 | 60 fps target for pointer effects on a normal display | Instruments or display-link trace |
| NFR-003 | Idle CPU below 1% of one core after settling | Five-minute Instruments sample |
| NFR-004 | Idle resident memory target below 80 MB | Activity Monitor after warm-up |
| NFR-005 | No blocked click when drawing is off | Repeated app interaction checks |
| NFR-006 | No forwarded drag when drawing is on | Repeated drawing over interactive content |
| NFR-007 | No crash or stuck overlay on permission denial | Permission matrix test |
| NFR-008 | Core functions work without network access | Offline test |
| NFR-009 | Correct placement on two or more mixed-scale displays | Physical multi-display test |
| NFR-010 | No capture stream while zoom is off | Capture/energy trace |
| NFR-011 | Two-hour presentation without crash or input deadlock | Soak session |
| NFR-012 | Keyboard-accessible controls with useful labels | VoiceOver and keyboard QA |

Performance budgets may be revised after measuring a named baseline machine. Input safety and data privacy remain release gates even if performance targets change.

## 10. Failure cases to handle

| Situation | Expected behavior |
|---|---|
| Display removed or scale changed | Overlay is reconciled; no invisible panel blocks input |
| External display has a negative origin | Pointer and marks stay aligned |
| Mac sleeps or locks | Capture suspends; interaction restores safely on wake |
| App quits during a drag | Overlay closes and desktop input returns |
| Capture permission denied or revoked | Zoom/export stops with guidance; drawing still works |
| Protected content cannot be captured | Blank content is explained without retry loops |
| Export folder unavailable | Error appears; annotations remain intact |
| Shortcut is already used | Conflict is shown; LocalInk stays usable from its menu |
| Pointer moves rapidly between displays | Halo, spotlight, and lens move without stale duplicates |
| Fullscreen presentation uses unusual window levels | Behavior is tested and documented; app remains dismissible |
| Screen share selects a single app window | User receives accurate guidance about overlay visibility |

## 11. Acceptance checks

### P0: usable drawing and pointer effects

- **T01 — Launch:** Build, open, find the menu-bar icon, and quit without an orphan process or panel.
- **T02 — Idle input:** Click Finder, drag a window, scroll a page, and select text. LocalInk intercepts none of them.
- **T03 — Draw toggle:** Draw over a PDF. The mark appears and the PDF does not receive the drag.
- **T04 — Exit drawing:** Toggle drawing off. The same drag interacts with the PDF normally.
- **T05 — Shapes:** Draw arrows, rectangles, and ellipses in both diagonal directions.
- **T06 — Color and undo:** Change color, draw multiple marks, undo once, and clear; prior marks keep their original color.
- **T07 — Pointer effects:** With halo and spotlight enabled, click a browser control. It activates exactly once.
- **T08 — Multiple displays:** Use displays with different scaling and positions; pointer effects and drawing stay aligned.
- **T09 — Recovery:** Sleep/wake and unplug a display while drawing; normal interaction remains available.

### P1: complete presenter workflow

- **T10 — Toolbar:** Use toolbar controls, then click outside it according to the current drawing mode.
- **T11 — Pass-through:** Temporarily interact with the app underneath, release the override, and resume drawing.
- **T12 — Editing:** Select and move one mark, undo the move, then delete it without changing other marks.
- **T13 — Text and board:** Add multiline text, switch to whiteboard and back, and confirm separate canvases.
- **T14 — Preferences:** Change a shortcut, restart, and confirm the saved mapping works.
- **T15 — Capture denial:** Deny capture permission; drawing, halo, and spotlight still work.
- **T16 — Zoom:** Grant permission and move a lens across displays without self-capture recursion.
- **T17 — Export:** Save and copy an annotated display; output has correct pixels and excludes controls.
- **T18 — Revocation:** Revoke capture permission during use; the app recovers without a stuck overlay.
- **T19 — Sharing:** Test whole-display and window-only capture in the intended presentation software and document results.

A requirement is done only when its user-visible behavior passes on the minimum supported macOS release and a current macOS release, or the support matrix documents a deliberate limitation. A settings control alone is not evidence that the feature works.

## 12. Implementation roadmap

### Milestone 0 — Verify the current app

1. Launch the compiled app in a normal macOS desktop session.
2. Run T01–T09 and record hardware, macOS version, and failures.
3. Fix any click-through, input-capture, panel layering, or display-geometry defect before adding features.
4. Make the menu accurately reflect active states.

**Gate:** Current P0 behavior passes on one supported Mac, with remaining compatibility work tracked explicitly.

### Milestone 1 — Strengthen the drawing foundation

1. Separate state, overlay management, annotation data, and rendering from the current single Swift file.
2. Add configurable stroke width, constrained shapes, action-based undo/redo, and floating toolbar.
3. Establish per-display logical-coordinate tests and mixed-scale manual tests.
4. Preserve drawings across mode toggles according to a documented policy.

**Gate:** T01–T10 pass without input deadlock.

### Milestone 2 — Editing and preferences

1. Add selection, move, delete, copy/paste, text, highlighter, and whiteboard.
2. Add a native settings panel and persisted shortcut mappings.
3. Add conflict handling, keyboard help, and session-retention choices.

**Gate:** T11–T14 pass.

### Milestone 3 — Capture and export

1. Add capture permission handling and ScreenCaptureKit display capture.
2. Exclude LocalInk-owned windows from the capture stream.
3. Add magnifier, fullscreen zoom, PNG export, and clipboard image output.
4. Test protected content, permission revocation, scaling, and resource cleanup.

**Gate:** T15–T18 pass without recursive capture or a stuck overlay.

### Milestone 4 — Release readiness

1. Test fullscreen slides, common meeting/recording apps, and whole-display sharing.
2. Profile CPU, memory, energy use, and long-running sessions.
3. Complete accessibility, onboarding, help, original visual identity, and privacy text.
4. Package, sign, notarize, and verify the release artifact.

**Gate:** T19 and the relevant quality targets pass on the documented support matrix.

## 13. Product decisions to keep consistent

- LocalInk targets macOS first and uses a native Swift/AppKit implementation.
- Drawing starts off so launching the app never blocks the desktop.
- Current shortcuts remain valid until users can change them.
- Annotations stay in memory during a session; disk persistence requires an explicit product decision and user-facing setting.
- Core drawing and pointer features remain usable without capture permission.
- Screenshot and zoom features are opt-in and entirely local.
- Every visible feature must be labeled by actual implementation status in release notes and UI.
