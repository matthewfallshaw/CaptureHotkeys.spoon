-- Export Hotkeys to HTML string format

M = {}

--- CaptureHotkeys.exporters.html
--- Function
--- Export captured hotkeys as html.
function M.to_html(hotkeys)
  local hotkeys = hotkeys or M.capture_hotkeys_spoon.hotkeys

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
    <div class="content maincontent">
    ]] .. M._html_fragment_hotkeys(hotkeys) .. [[
    </div>
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


function M:_html_fragment_hotkeys(hotkeys)
  local hotkeys = hotkeys or M.capture_hotkeys_spoon.hotkeys

  local html = ""
  local count = 0
  for spoonname, hotkeys in pairs(hotkeys) do
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

function M:init(capture_hotkeys_spoon)
  M.capture_hotkeys_spoon = assert(capture_hotkeys_spoon, "Parent spoon.CaptureHotkeys must be supplied")
  setmetatable(M, { __call = M.to_html, })
  return self
end

return M
