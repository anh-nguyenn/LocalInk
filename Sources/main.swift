import AppKit

// LocalInk — an offline macOS menu-bar app for drawing and directing attention
// on top of the desktop. Core drawing and pointer effects never require screen
// capture; only optional zoom and export do.

let app = NSApplication.shared
let coordinator = AppCoordinator()
app.delegate = coordinator
app.run()
