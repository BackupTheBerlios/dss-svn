#!/usr/bin/python
# -*- coding: utf8 -*-
import sys
sys.path.append('.')
import gtk
import time
from utils.notification import NotificationDaemon
import os.path
#from Device import Device
class Notify:
    def __init__(self,mount_point):
        self.msg_render=NotificationDaemon()
        summary="Summary"
        message="Message"
        file_man='rox'
        
        #action_open = self.open_volume('rox',mount_point)
        #print action_open
        #print open_volume()
        icon_theme = gtk.icon_theme_get_default() 
	icon_lookup=icon_theme.lookup_icon('drive-harddisk',48 ,gtk.ICON_LOOKUP_USE_BUILTIN) 
        icon=icon_lookup.get_filename()
        print icon
	#icon=icon_theme.get_builtin_pixbuf() 
	print icon
        #def actions_to():
        #    print 'ciao'
        #print icon
        #self.msg_render.show(summary, message, 
        #        icon, actions = {mount_point: ' ' } )
        self.msg_render.show_warning(summary, message)

        
def main():
    notify = Notify('/dev/sdb')
if __name__ == "__main__":
    #pkges = 'abiword-gnome'
    main()
