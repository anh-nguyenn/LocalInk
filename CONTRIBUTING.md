# Contributing to LocalInk

Thanks for helping improve LocalInk. This guide keeps changes easy to review and
safe for the people who present with the app.

## Before you start

- Search the existing issues to avoid duplicate work.
- For a large feature or a behavior change, open an issue first so we can agree on
  the approach.
- Keep the product offline and account-free. Do not add telemetry, analytics, or
  network calls.

## Build and test

```bash
./build.sh          # universal release build into dist/LocalInk.app
./scripts/test.sh   # headless geometry, rendering, and export tests
./release.sh        # Developer ID signed and notarized ZIP and DMG under dist/
```

Run the app and exercise the change on a real desktop session. A compiled app is
not the same as a tested release.

## What matters for this project

1. **Input safety.** When drawing is off, LocalInk must never intercept clicks,
   drags, or scrolling. When drawing is on, the underlying app must not receive
   the same gesture.
2. **Coordinates.** Store annotations in logical points per display and convert
   to backing pixels only during rendering or export. Test negative display
   origins and mixed scaling.
3. **Permissions.** Drawing, halo, and spotlight must keep working when Screen
   Recording permission is denied or revoked.
4. **Honest UI.** Do not ship a control that looks finished when it is not.

## Code style

- Swift and AppKit, native macOS. Keep UI state on the main thread.
- Prefer small, focused files. Split by responsibility rather than growing a
  single file.
- Do not add code comments that restate the obvious. Comment non-obvious tradeoffs.
- Match the formatting and naming of the surrounding code.
- Avoid unbounded stroke arrays and undo history.

## Website

The marketing site lives in `website/` and is deployed by the GitHub Pages
workflow. It supports English and Vietnamese; any copy change must update both
languages in `website/assets/app.js`. Keep the page structure and translations in
sync, and run `node --check website/assets/app.js` before opening a pull request.

## Pull requests

- Keep each pull request focused on one change.
- Describe the user-visible behavior and how you tested it.
- Include your Mac model and macOS version for interaction or display changes.
- Update the README or product specification when behavior or defaults change.

## Reporting bugs

Include:

- Mac model and macOS version
- Display setup (count, scaling, external displays)
- Whether drawing, halo, spotlight, zoom, or export was active
- Steps to reproduce and what you expected instead

Please do not include screenshots or logs that contain sensitive screen content.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
