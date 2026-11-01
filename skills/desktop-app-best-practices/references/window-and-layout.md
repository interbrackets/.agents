# Window and Layout

## Sizing

- Design resizable windows so they stay usable when small. Users resize freely and snap to 1/2, 1/3, and 1/4 of the screen.
- Set a minimum window size if content stops being usable below it.
- Larger windows should show more data, not just more empty space.
- Everything must stay reachable by scrolling or panning, however small the window gets.
- Restore the last size and position on launch. If that position is now off-screen, because a monitor was unplugged, fall back to a visible one.
- Center an owned window on its owner, never underneath it.
- Show a contextual window near the object that opened it, without covering that object.

## Scaling

Test across window sizes, DPI settings, and scale settings, including text scaling at 200%. Check for clipped controls and text, and for stretched icons or bitmaps.

Web content in a webview scales with the browser engine, but native parts such as window icons, tray icons, and custom title bars need assets for each scale.

## Window chrome

- Let the system draw borders and shadows when you can. Custom ones can break rounded corners and the snap layout menu.
- With a custom title bar, keep drag regions and standard minimize, maximize, and close behavior. Hovering maximize should still offer snap layouts.

## Themes

- Support light and dark, following the system setting by default.
- The title bar may not follow the theme automatically, so check it.
- Do not use pure black or pure white. Windows 11 softens both.
- Test critical flows with contrast themes, and do not rely on color alone to carry meaning.

## Native feel

- Use a system font stack. On Windows that means Segoe UI Variable.
- Text should be selectable, and copyable. Editable text should support cut and paste.
- Do not use blue text unless it is a link.
- Use the hand pointer only for links.
- Do not let the app behave like a website: no page-level text selection of chrome, no rubber-band scroll on the shell, and no browser context menu in production.

## Offline

A desktop app is expected to open without a network.

- Render the shell and any local data first, and treat the network as optional.
- Show which features are unavailable, rather than failing silently or showing an endless spinner.
- Queue or disable actions that need the network, and say which.

## Performance

- Define key interactions, and measure cold start, warm start, and those interactions on lower-end and Arm64 hardware.
- Show the first meaningful frame fast. Load the rest afterward.
- Keep memory low in the foreground, and release resources while in the background.
- Do not wake the CPU in the background without a reason. Use push rather than polling where you can.
- Size caches sensibly, and watch for leaks in long-running sessions. Desktop apps stay open for days, unlike web pages.
