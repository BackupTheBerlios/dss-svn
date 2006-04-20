#!/usr/bin/python
# -*- coding: utf8 -*-
import sys
import gtk



class IconPath:
    def __init__(self):
        list=[]
        listtango=[]
        self.xfceicons=[]
        icon_theme = gtk.icon_theme_get_default() 
        self.iconlist=icon_theme.list_icons()
        self 
        for i in self.iconlist:
            icon=self.get_icon_path(icon_theme,i)
            if 'xfce' in icon:
                self.xfceicons.append(icon)
                
            icon_pixbuf=gtk.gdk.pixbuf_new_from_file_at_size(icon,48,48)
            icon_data=[icon_pixbuf,i, icon]
            list.append(icon_data)
        self.data=list
        self.tango=self.get_icon_tango()
        #print self.tango
        for i in self.tango:
            #print "####"
            icontango=self.get_icon_path(icon_theme,i)
            #print icontango
            
            if icontango != '':
                icontango_pixbuf=gtk.gdk.pixbuf_new_from_file_at_size(icontango,48,48)
                
            else:
                icontango_pixbuf=None
                icontango=None
            
            icontango_data=[icontango_pixbuf,i, icontango]
            listtango.append(icontango_data)
        self.datatango=listtango
        
        
        # 
    
    def get_icon_path(self,icontheme, iconname):
       
        #print iconname
        if icontheme.has_icon(iconname) == True:
            icon_lookup=icontheme.lookup_icon(iconname,48 ,gtk.ICON_LOOKUP_FORCE_SVG)
            icon=icon_lookup.get_filename()
        else:
            icon=''
        return icon
    def get_icon_tango(self):
        import tangoxml
        tangolist=[]
        grammar = "/usr/share/icon-naming-utils/legacy-icon-mapping.xml" 
        tangoicons = tangoxml.TangoGenerator(grammar)
        for i in tangoicons.icons.keys():
            tangolist.append(str(i))
        return tangolist
        
	
    
def main():
    iconpath=IconPath()    
if __name__ == "__main__":
    main()
