-- Export Hotkeys to KeyCue properties file format

local M = {
  build_dir = 'build',
  file_name = 'HammerspoonHotkeys.kcustom',
}

local logger = hs.logger.new('CHKs KeyCue exporter')
M.logger = logger

M.keyCueModifierFlags = {
  NSEventModifierFlagCapsLock   = 1 << 16, -- Set if Caps Lock key is pressed.
  NSEventModifierFlagShift      = 1 << 17, -- Set if Shift key is pressed.
  NSEventModifierFlagControl    = 1 << 18, -- Set if Control key is pressed.
  NSEventModifierFlagOption     = 1 << 19, -- Set if Option or Alternate key is pressed.
  NSEventModifierFlagCommand    = 1 << 20, -- Set if Command key is pressed.
  NSEventModifierFlagNumericPad = 1 << 21, -- Set if any key in the numeric keypad is pressed.
  NSEventModifierFlagHelp       = 1 << 22, -- Set if the Help key is pressed.
  NSEventModifierFlagFunction   = 1 << 23, -- Set if any function key is pressed.
}
M.modifierKeys = {
  ["⌘"] = M.keyCueModifierFlags.NSEventModifierFlagCommand,
  ["⇧"] = M.keyCueModifierFlags.NSEventModifierFlagShift,
  ["⌃"] = M.keyCueModifierFlags.NSEventModifierFlagControl,
  ["^"] = M.keyCueModifierFlags.NSEventModifierFlagControl,
  ["⌥"] = M.keyCueModifierFlags.NSEventModifierFlagOption,
}
M.keyCodes = setmetatable({
  ["␣"] = 49,
  ["←"] = 123,
  ["→"] = 124,
  ["↑"] = 126,
  ["↓"] = 125,
}, {__index = hs.keycodes.map})

function M._script_path(level)
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

function M.default_output_file_path()
  local srcfile,srcdir = M._script_path()
  local hsdir = assert(srcdir:match("^(/.+/)Spoons")) or (hs.execute("pwd"))

  local outputdir = (hsdir..M.build_dir.."/")
  hs.execute("mkdir -p "..outputdir)
  return outputdir .. M.file_name
end

function M:export_to_file(file_path, hotkeys)
  local file_path = file_path or self.output_file_path
  local hotkeys = hotkeys or self.capture_hotkeys_spoon.hotkeys

  local output_file = assert(io.open(file_path, "w"))

  self._write_kcustom(output_file, hotkeys)
  output_file:close()
  logger.i('KeyCue mapping file written to '.. file_path)
  return true
end

function M._write_kcustom(f, hotkeys)
  local revHtmlEntities = {}
  for e, u in pairs(hs.http.htmlEntities) do revHtmlEntities[u] = e end

  local fix = function(str)
    return (string.gsub(str, '.', function(c) return revHtmlEntities[c] end))
  end

  f:write([[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>name</key>
	<string>System-wide</string>
	<key>shortcuts</key>
	<array>
]])
  for heading,hkeys in pairs(hotkeys) do
    f:write([[		<dict>
			<key>heading</key>
			<true/>
			<key>title</key>
			<string>]] .. fix(heading) .. [[</string>
		</dict>
]])
    for action,keys in pairs(hkeys) do
      local keycode = assert(M.keyCodes[keys.key])
      assert(type(keycode) == "number", keys.key)
      local optflag
      if #keys.mods == 1 then
        optflag = M.modifierKeys[keys.mods[1]]
      else
        optflag = hs.fnutils.reduce(keys.mods, function(a,b)
          local x = ((type(a) == "number") and a or M.modifierKeys[a])
          assert(type(x) == "number", tostring(x).." isn't a number")
          return x + M.modifierKeys[b]
        end)
      end
      assert(optflag, "optflag nil; keys.mods " .. table.concat(keys.mods, ","))
      assert(type(optflag) == "number", optflag)
      assert(action)
      f:write([[		<dict>
			<key>keycode</key>
			<integer>]] .. keycode .. [[</integer>
			<key>modifiers</key>
			<integer>]] .. optflag .. [[</integer>
			<key>title</key>
			<string>]] .. fix(action) .. [[</string>
		</dict>
]])
    end
  end
  f:write([[	</array>
</dict>
</plist>]])
end

function M:init(capture_hotkeys_spoon)
  M.capture_hotkeys_spoon = assert(capture_hotkeys_spoon, "Parent spoon.CaptureHotkeys must be supplied")
  M.output_file_path = self:default_output_file_path()
  setmetatable(M, { __call = M.to_html, })
  return self
end

return M
