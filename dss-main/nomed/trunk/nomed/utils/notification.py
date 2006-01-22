#!/usr/bin/python
# -*- coding: utf-8 -*-

import dbus
import thread
import logging
import os
import time

if getattr(dbus, "version", (0, 0, 0)) >= (0, 41, 0):
    import dbus.glib


class NotificationDaemon(object):
    """
    This class is a wrapper for notification-daemon program.
    http://www.galago-project.org/specs/notification/0.7/
    """

    def __init__(self): 
        self.logger = logging.getLogger()
        bus = dbus.SessionBus()
        #bus = dbus.SystemBus() 
        obj = bus.get_object('org.freedesktop.Notifications',
                '/org/freedesktop/Notifications')

        self.iface = dbus.Interface(obj, 'org.freedesktop.Notifications')

    # Main Message #######################################################

    def show(self, summary, message, icon, actions = {},expires=1): 
        #print actions
        if actions != {}:
           
            (notify_actions, action_handlers) = self.process_actions(actions)
            

            def action_invoked(nid, action_id):
                if action_handlers.has_key(action_id) and res == nid:
                    #Execute the action handler
                    thread.start_new_thread(action_handlers[action_id], ())
                    action_handlers[action_id]()
                    self.iface.CloseNotification(dbus.UInt32(nid))

            condition = False
            while not condition:
                try: 
                    #self.logger.debug("Trying to connect to ActionInvoked")
                    self.iface.connect_to_signal("ActionInvoked", action_invoked)
                    condition = True
                except:
                    logmsg = "ActionInvoked handler not configured. "
                    logmsg += "Trying to run notification-daemon."
                    self.logger.warning(logmsg)
                    os.system('/usr/lib/notification-daemon/notification-daemon &')                
                    time.sleep(0.2)

        else:
            #Fixing no actions messages
            notify_actions = [(1, 2)]
        #parameters_map={"sound_file":dbus.Variant("tune.mp3"), "suppress_sound":dbus.Variant(True), "x":dbus.Variant(100), "y":dbus.Variant(50) }
        #parameters_map={ "x":dbus.Variant(), "y":dbus.Variant() }
        parameters_map=[""]
        
        
       # Determine the version of notifications
		# FIXME: This code is blocking, as is the next set. That should be fixed
		# now that we have a class to encapsulate this behavior
        
        try:
            (name, vendor, version) = self.iface.GetServerInfo()
        except:
            # No way to determine the version number, set it to the latest
            # since it doesn't properly support the version number
            version = '0.3.1'
        if version.startswith('0.2'): 
            try:
                res = self.iface.Notify("Nomed", 
                                    [dbus.String(icon)],
                                    dbus.UInt32(0),  
                                    '', 
                                    dbus.Byte(0), 
                                    summary,  
                                    message,  
                                    [dbus.String(icon)], 
                                    notify_actions, 
                                    parameters_map,
                                    dbus.Boolean(expires), 
                                    dbus.UInt32(9))
            except AttributeError:
                version = '0.3.1'
        print version
        if version.startswith('0.3'):
            res = self.iface.Notify("Nomed", 
                    dbus.String(icon),
                    dbus.UInt32(0), 
                    '', 
                    #dbus.Byte(0), 
                    dbus.String(summary),  
                    dbus.String(message),  
                    #[dbus.String(icon)], 
                    notify_actions, 
                    #parameters_map,
                    dbus.UInt32(9*1000)) 
                                    
        
        return res


    # Specific messages #################################

    def show_info(self, summary, message, actions = {}):
        return self.show(summary, message, "gtk-dialog-info", actions)


    def show_warning(self, summary, message, actions = {}):
        return self.show(summary, message, "gtk-dialog-warning", actions)


    def show_error(self, summary, message, actions = {}):
        return self.show(summary, message, "gtk-dialog-error", actions)


    def close(self, nid):
        try:
            self.iface.CloseNotification(dbus.UInt32(nid))
        except:
            pass


    # Private methods ###################################
    def process_actions(self, actions):
       
        #print actions
        if actions == {}:
            #FIXME
            return {}, {}

        for key in actions.keys():
            actions[" "] = None

        notify_actions = {}
        action_handlers = {}
        i = 1
        #print actions.items()
        for key, value in actions.items():
            #print key
            notify_actions[key] = i
            action_handlers[i] = value
            i += 1

        return notify_actions, action_handlers



class FileNotification(object):

    def __init__(self, filepath):
        self.filepath = filepath


    def show (self, summary, body, icon, actions = {}):
        self.__write("show: %s, %s, %s" % (summary, body, icon))


    def show_info(self, summary, body, actions = {}):
        self.__write("show_info: %s, %s, %s" % (summary, body))


    def show_warning(self, summary, body, actions = {}):
        self.__write("show_warning: %s, %s, %s" % (summary, body))


    def show_error(self, summary, body, actions = {}):
        self.__write("show_error: %s, %s, %s" % (summary, body))


    def __write(self, text):
        try:
            objfile = open(self.filepath, 'a')
            objfile.write(text + '\n')
            objfile.close()
        except Exception, e:
            logging.getLogger().error('FileNotification: ' + e)
                
            


