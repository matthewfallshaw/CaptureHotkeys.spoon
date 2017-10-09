--- === CaptureHotkeys ===
---
--- Capture Spoon hotkeys as they are assigned, capture arbitrary hotkeys, and display them all.
--- A Spoon for Hammerspoon.
---
--- In your `~/.hammerspoon/init.lua`, ...  
--- Add `hs.loadSpoon("CaptureHotkeys")` before any other Spoons or hotkeys you want to capture.  
--- Assign a hotkey to display captured hotkeys: `spoon.CaptureHotkeys:bindHotkeys({show = {{ "⌘", "⌥", "⌃", "⇧" }, "k"}})`.
--- Start capturing: `spoon.CaptureHotkeys:start()`
--- Load your other spoons.
---
--- Example `~/.hammerspoon/init.lua`:
---
---     hs.loadSpoon("CaptureHotkeys")
---     spoon.CaptureHotkeys:bindHotkeys({show = {{ "⌘", "⌥", "⌃", "⇧" }, "k"}})
---     spoon.CaptureHotkeys:start()
---
---     ...

local M = {}
M.__index = M

-- Metadata
M.name = "CaptureHotkeys"
M.version = "0.1"
M.author = "Matthew Fallshaw <m@fallshaw.me>"
M.license = "MIT - https://opensource.org/licenses/MIT"
M.homepage = "https://github.com/matthewfallshaw/CaptureHotkeys.spoon"


--- CaptureHotkeys.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
M.logger = hs.logger.new("Capture Hotkeys")


-- Utility functions and tables
function M.script_path(level)
  local src
  if level then
    src = debug.getinfo(level,"S").source:sub(2)
  else
    local sources = {}
    for level=1,5 do
      src = debug.getinfo(level,"S").source:sub(2)
      table.insert(sources, src)
      if src:match("%.lua$") then
        return src, src:match("(.+/)[^/]+")
      end
    end
    return nil, "{\"".. table.concat(sources, "\",\"") .."\"}"
  end
  return src
end

M.key_cleanup = setmetatable(
  { command = "⌘", cmd = "⌘", alt = "⌥", opt = "⌥", ctrl = "⌃", shift = "⇧",
    Left = "←", Right = "→", Up = "↑", Down = "↓", space = "␣" },
  { __index = function(t, k) return k end })


-- Variables

--- CaptureHotkeys.hotkeys
--- Variable
--- The captured hotkeys. 
M.hotkeys = {}


--- CaptureHotkeys.hotkeys
--- Variable
--- Exporters for various formats. 
---
--- Currently:
--- html - CaptureHotkeys.exporters.html:to_html() (or `…exporters.html()`)
--- an HTML string used for the default hotkey view ( `CaptureHotkeys:show()` )
---
--- keyCue - spoon.CaptureHotkeys.exporters.keyCue.export_to_file() (or `…exporters.keyCue()`)
--- write a custom shortcuts file for "KeyCue.app"[http://www.ergonis.com/products/keycue/] to `build/HammerspoonHotkeys.kcustom`
M.exporters = {}

-- Module methods

--- CaptureHotkeys:capture()
--- Method
--- Manually capture non-Spoon hotkeys.
---
--- Parameters:
---  * hotkey_group_name - a string
---  * mapping - a table: { hotkey_action = { { mods }, "key" } }
---      eg. `{["Toggle layout engine"] = { {"⌘", "⌥", "⌃", "⇧"}, "s" }}`
--- 
--- Returns:
---  * The CaptureHotkeys object
function M:capture(hotkey_group_name, mapping)
  if not self.hotkeys[hotkey_group_name] then self.hotkeys[hotkey_group_name] = {} end
  local count = 0
  for hotkey_action, key_map in pairs(mapping) do
    local mods, hotkey = key_map[1], M.key_cleanup[key_map[2]]
    for k,mod in pairs(mods) do mods[k] = M.key_cleanup[mod] end
    table.sort(mods)
    self.hotkeys[hotkey_group_name][hotkey_action] = { mods = mods, key = hotkey}
    count = count + 1
  end
  if count == 0 then self.hotkeys[hotkey_group_name] = nil end
end


--- CaptureHotkeys:start()
--- Method
--- Starts capturing Spoon hotkeys assigned with :bindHotkeys().
---
--- Parameters:
---  * None
---
--- Returns:
---  * The CaptureHotkeys object
function M:start()
  local captureHotkeysSpoon = self                -- self will be shadowed by later function calls
  captureHotkeysSpoon.__loadSpoon = hs.loadSpoon  -- preserve original hs.loadSpoon
  function hs.loadSpoon(...)                      -- redefine hs.loadSpoon, decorating it with our collector
    obj = captureHotkeysSpoon.__loadSpoon(...)      -- inside the loaded Spoon, call original hs.loadSpoon

    obj.__bindHotkeys = obj.bindHotkeys             -- preserve original bindHotkeys
    function obj:bindHotkeys(mapping)               -- redefine bindHotkeys, decorating it with our collector
      self.__bindHotkeys(obj, mapping)                -- call original bindHotkeys
      captureHotkeysSpoon:capture(obj.name, mapping)  -- capture the mapping
    end

    return obj
  end
  return self
end


--- CaptureHotkeys:stop()
--- Method
--- Stops CaptureHotkeys.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The CaptureHotkeys object
function M:stop()
  if self.__loadSpoon then
    hs.loadSpoon = self.__loadSpoon
  end

  for name, s in pairs(spoon) do
    if s.__bindHotkeys then
      s.bindHotkeys = s.__bindHotkeys
    end
  end

  return self
end


--- CaptureHotkeys:show()
--- Method
--- Hide the hotkeys webview
---
--- Parameters:
---  * None
---
--- Returns:
---  * The CaptureHotkeys object
function M:show()
  local cscreen = hs.screen.mainScreen()
  local cres = cscreen:fullFrame()
  self.sheetView:frame({
    x = cres.x+cres.w*0.15/2,
    y = cres.y+cres.h*0.25/2,
    w = cres.w*0.85,
    h = cres.h*0.75
  })
  self.sheetView:html(self.exporters.html:to_html())
  self.sheetView:show()
  self.visible = true
  return self
end


--- CaptureHotkeys:hide()
--- Method
--- Hide the hotkeys webview
---
--- Parameters:
---  * None
---
--- Returns:
---  * The CaptureHotkeys object
function M:hide()
  self.sheetView:hide()
  self.visible = false
  return self
end


--- CaptureHotkeys:toggleList()
--- Method
--- Show if hidden, Hide if visible, the hotkeys webview
---
--- Parameters:
---  * None
---
--- Returns:
---  * The CaptureHotkeys object
function M:toggle()
  if self.visible then
    self:hide()
  else
    self:show()
  end
  return self
end


--- CaptureHotkeys.defaultHotkeys
--- Variable
--- Table containing a sample set of hotkeys that can be --- assigned to the different operations. These are not bound
--- by default - if you want to use them you have to call:
--- `spoon.CaptureHotkeys:bindHotkeys(spoon.CaptureHotkeys.defaultHotkeys)`
--- after loading the spoon. Value:
--- ```
---  {
---    show = { {"ctrl", "alt", "cmd", "shift"}, "k" },
---  }
--- ```
M.defaultHotkeys = {
   show = { {"ctrl", "alt", "cmd", "shift"}, "k" },
}


--- CaptureHotkeys:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for CaptureHotkeys
---
--- Parameters:
---  * mapping - A table containing hotkey objifier/key details for the following items:
---   * top_left, top_right, bottom_left, bottom_right - resize and move the window to the corresponding quarter of the screen
function M:bindHotkeys(mapping)
   local hotkeyDefinitions = {
      show = function() self:toggle() end,
   }
   hs.spoons.bindHotkeysToSpec(hotkeyDefinitions, mapping)
   return self
end


function M:init()
  self.sheetView = hs.webview.new({x=0, y=0, w=0, h=0})
    :windowTitle("Hotkeys")
    :windowStyle({ "utility", "closable", "nonactivating" })
    :allowMagnificationGestures(true)
    :allowNewWindows(false)
    :level(hs.drawing.windowLevels.modalPanel)
    :closeOnEscape(true)

  local _,script_dir = self.script_path()
  self.exporters = {}
  for _,format in pairs({"html", "keyCue"}) do
    local script_file = script_dir .. "exporters/" .. format .. "Exporter.lua"
    local f=io.open(script_file,"r")
    if f~=nil then
      io.close(f)
      self.exporters[format] = dofile(script_file):init(self)
    else
      self.logger.e("Couldn't load ".. format .." exporter: ".. script_file .." not found")
    end
  end

  return self
end


return M
