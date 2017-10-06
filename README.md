# CaptureHotkeys.spoon

Capture hotkeys assigned hotkeys and display them.
A Spoon for Hammerspoon.


## Install

Copy directory as CaptureHotkeys.spoon to ~/.hammerspoon/Spoons/


## Use

In your `~/.hammerspoon/init.lua`, ...  
Add `hs.loadSpoon("CaptureHotkeys")` before any other Spoons or hotkeys you want to capture.  
Assign a hotkey to display captured hotkeys: `spoon.CaptureHotkeys:bindHotkeys({show = {{ "⌘", "⌥", "⌃", "⇧" }, "k"}})`.
Start capturing: `spoon.CaptureHotkeys:start()`
Load your other spoons.

Example `~/.hammerspoon/init.lua`:

    hs.loadSpoon("CaptureHotkeys")
    spoon.CaptureHotkeys:bindHotkeys({show = {{ "⌘", "⌥", "⌃", "⇧" }, "k"}})
    spoon.CaptureHotkeys:start()

    ...
