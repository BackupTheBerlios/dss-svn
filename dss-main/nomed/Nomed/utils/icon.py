#!/usr/bin/python
# -*- coding: utf8 -*-
import sys
import gtk
import os


class IconPath:
    def __init__(self,icon_name):
        icon_path=None
        icon_theme=None
        icon_pixbuf=None
        icon_theme = gtk.icon_theme_get_default()
        self.icon_list=icon_theme.list_icons()
        if os.path.isfile(icon_name):
            icon_path=icon_name
        elif icon_name in self.icon_list:  
            icon_path=self.get_icon_path(icon_theme,icon_name)
            icon_pixbuf=gtk.gdk.pixbuf_new_from_file_at_size(icon_path,48,48)
        #icon_data=[icon_pixbuf,icon_name, icon]
        #list.append(icon_data)
        #self.data=list
        self.icon_theme=icon_theme
        self.icon_path=icon_path
        self.icon_pixbuf=icon_pixbuf

    def get_icon_path(self,icontheme, iconname):
        icon_lookup=icontheme.lookup_icon(iconname,48 ,gtk.ICON_LOOKUP_FORCE_SVG)
        icon=icon_lookup.get_filename()
        return icon
def main():
    import sys
    iconpath=IconPath(sys.argv[1]) 
    print iconpath.icon_path
if __name__ == "__main__":
    main()
