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
local logger = hs.logger.new("Capture Hotkeys")


-- Utility functions
function M:html()
  local html = [[
    <!DOCTYPE html>
    <html>
    <head>
    <style type="text/css">
    *{margin:0; padding:0;}
    html, body{
      background-color:#eee;
      font-family: arial;
      font-size: 13px;
    }
    a{
      text-decoration:none;
      color:#000;
      font-size:12px;
    }
    li.title{text-align:center;}
    ul, li{list-style: inside none; padding: 0 0 5px;}
    header{
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      height:48px;
      background-color:#eee;
      z-index:99;
    }
    header hr{padding: 15px 0px 0px 0px;}
    .title{padding: 15px;}
    li.title{padding: 0  10px 15px}
    .content{
      padding: 0 0 15px;
      font-size:12px;
      overflow:hidden;
    }
    .content.maincontent{
      position: relative;
      height: 577px;
      margin-top: 46px;
    }
    .content > .col{
      width: 23%;
      padding:20px 0 20px 20px;
    }

    li:after{
      visibility: hidden;
      display: block;
      font-size: 0;
      content: " ";
      clear: both;
      height: 0;
    }
    .cmdModifiers{
      width: 90px;
      padding-right: 5px;
      text-align: right;
      float: left;
      font-weight: bold;
    }
    .cmdKey{
      width: 20px;
      padding-right: 0px;
      text-align: left;
      float: left;
      font-weight: bold;
    }
    .cmdtext{
      float: left;
      overflow: hidden;
      width: 165px;
    }
    </style>
    </head>
    <body>
    <header>
    <div class="title"><strong>Hotkeys</strong></div>
    <hr />
    </header>
    <div class="content maincontent">]] .. self:spoonsToHtml() .. [[</div>
    <br>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.isotope/2.2.2/isotope.pkgd.min.js"></script>
    <script type="text/javascript">
    var elem = document.querySelector('.content');
    var iso = new Isotope( elem, {
      // options
      itemSelector: '.col',
      layoutMode: 'masonry'
    });
    </script>
    </body>
    </html>
    ]]

  return html
end


function M:spoonsToHtml()
  local html = ""
  local count = 0
  for spoonname, hotkeys in pairs(self.hotkeys) do
    count = count + 1
    html = html .. "<ul class='col col" .. count .. "'>"
    html = html .. "<li class='title'><strong>" .. spoonname .. "</strong></li>"
    for hotkey_action, key_map in pairs(hotkeys) do
      html = html .. "<li><div class='cmdModifiers'>" .. table.concat(key_map.mods, ",") .. "</div><div class='cmdKey'>" .. key_map.key .. "</div><div class='cmdtext'>" .. hotkey_action .. "</div></li>"
    end
    html = html .. "</ul>"
  end
  return html
end


-- Variables

--- CaptureHotkeys.hotkeys
--- Variable
--- The captured hotkeys. 
M.hotkeys = {}


M.key_cleanup = setmetatable(
  { command = "⌘", cmd = "⌘", alt = "⌥", opt = "⌥", ctrl = "⌃", shift = "⇧",
    Left = "←", Right = "→", Up = "↑", Down = "↓", space = "␣" },
  { __index = function(t, k) return k end })


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
  return captureHotkeysSpoon
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
  self.sheetView:html(self:html())
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


function M:init()
  self.sheetView = hs.webview.new({x=0, y=0, w=0, h=0})
    :windowTitle("Hotkeys")
    :windowStyle({ "utility", "closable", "nonactivating" })
    :allowMagnificationGestures(true)
    :allowNewWindows(false)
    :level(hs.drawing.windowLevels.modalPanel)
    :closeOnEscape(true)

  return self
end


--- CaptureHotkeys.defaultHotkeys
--- Variable
--- Table containing a sample set of hotkeys that can be
--- assigned to the different operations. These are not bound
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


return M
