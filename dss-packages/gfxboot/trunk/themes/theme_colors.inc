

/black               0x000000          newcolor
/white               0xffffff          newcolor
/blue                0x0000a0          newcolor
/red                 0xc00000          newcolor
/green               0x009000          newcolor
/yellow              0xffff20          newcolor
/lightgray           0xffffff          newcolor
/dotcolor            0xa9bbcd          newcolor
/lightdotcolor       0xeff2f6          newcolor
/somegreen           0x3465a4          newcolor

% some global stuff
/loading_color       somegreen           def
%/loading_color       0x128542          newcolor
/fn_color            somegreen def
/frame_color         0xd0d0ff          newcolor
/dark_frame_color    0x364c65          newcolor
/title.bg            somegreen         def

%/title.bg            0x55963f          newcolor




%common.inc
/menu.text.normal    black         def
/menu.text.select    white             def
/boot.text.options   somegreen             def
/boot.text.normal    black             def
/infobox.bg          red         def
/infobox.text.normal black             def
/menu.bar.color      somegreen       def

%help.inc
/help.light white def
/help.dark somegreen def
/help.font font.normal def
/help.normal.bg white def
/help.normal.fg black def
/help.highlight.fg somegreen def
/help.link.fg somegreen def
/help.link.selected.fg white def
/help.link.selected.bg somegreen def

%panel.inc
/panel.normal	black def
/panel.high	fn_color def
/panel.bg	white def
/panel.border	lightdotcolor def

%xmenu.inc
/xmenu.light		white def
/xmenu.dark		black def
/xmenu.font		font.normal def
/xmenu.normal.bg	white def
/xmenu.normal.fg	black def
/xmenu.selected.fg	white def
/xmenu.selected.bg	somegreen def



