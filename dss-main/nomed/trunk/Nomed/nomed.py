#!/usr/bin/python
# -*- coding: utf8 -*- 
import gtk
import dbus
if getattr(dbus, 'version', (0,0,0)) >= (0,41,0):
    import dbus.glib
from utils.device import Device
from utils.actor import Actor
from utils.rules import RulesParser
from utils.config import ConfigParser
from utils.voice import VoiceParser
from utils.notification import NotificationDaemon
from utils.icon import IconPath
from utils.trayicon import TrayIcon
import os.path
#from nomed import Notify

class DeviceManager:
    def __init__(self,appdir):
        print appdir
        self.trayicon=TrayIcon()
        self.msg_render=NotificationDaemon()     
        self.appdir=appdir
        
        self.udi_dict = {}
        self.config = {}
        self.voice = {}
        self.virtual_root = {}
        self.bus = dbus.SystemBus()
        
        self.hal_manager_obj = self.bus.get_object('org.freedesktop.Hal', 
                                                   '/org/freedesktop/Hal/Manager')
        self.hal_manager = dbus.Interface(self.hal_manager_obj,
                                          'org.freedesktop.Hal.Manager')
       
        # gdl_changed will be invoked when the Global Device List is changed
        # per the hal spec
        self.hal_manager.connect_to_signal("DeviceAdded", 
                         lambda *args: self.gdl_changed("DeviceAdded", *args))
        #print self.hal_manager
        self.hal_manager.connect_to_signal("DeviceRemoved", 
                         lambda *args: self.gdl_changed("DeviceRemoved", *args))
        #print self.hal_manager
        self.hal_manager.connect_to_signal("NewCapability", 
                         lambda *args: self.gdl_changed("NewCapability", *args)) 
        #print self.hal_manager
        
        # Add listeners for all devices
        try:
            device_names = self.hal_manager.GetAllDevices()
        except:
            print 'add here notification-daemon error'
        
        
        
        for name in device_names:
	        self.add_device_signal_recv (name); 
        
        self.update_device_dict()
        # config.xml dict
        config=ConfigParser(filename=self.appdir+"/config.xml")
        #print config
        self.config=config.dict_config
        # voice.xml dict
        voice=VoiceParser(filename=self.appdir+"/voice.xml")
        # print voice
        self.voice=voice.dict_voice
        
        print "Nomed Volume Manager started"
        
        gtk.main()
        
    def get_tray_coordinates(self,trayicon):
        """
        get the trayicon coordinates to send to 
        notification-daemon
        trayicon=egg.trayicon.TrayIcon 
        return : [x,y]
        """
        coordinates=trayicon.window.get_origin()
        size=trayicon.window.get_size()
        screen=trayicon.window.get_screen()
        screen_height=screen.get_height()
        if coordinates[1] <= screen_height/2:
            y=coordinates[1]+size[1]/2
        else:
            y=coordinates[1]-size[1]/2
        msg_xy=[coordinates[0],y]
        return msg_xy
            
            
    def properties_rules(self,device_udi):
        """
        Parse the rules.xml file for actions
        input=device udi
        return:device properties dict,actions,required
        """
        properties = self.udi_to_properties(device_udi) 
        rules=RulesParser(filename=self.appdir+"/rules.xml",input=properties)
        required=rules.required
        actions=rules.actions
        return required,actions,properties

        
    def property_modified(self, device_udi, num_changes, change_list):
        """
        This method is called when signals on the Device 
        interface is received
        """
        # device_udi: the device identifier
        # change_list :
        # ex: when the volume has been mounted
        # [('volume.mount_point', False, False), ('volume.is_mounted', False, False)]
        # it will read 
        # 1) ('volume.mount_point', False, False) 
        #    i[0] == volume.mount_point [property_name] [key]
        #    i[1] == False              [removed]       [rem=0|1]
        #    i[2] == False              [added]         [add=0|1]
        # 2) ('volume.is_mounted', False, False) 
        #    i[0] == volume.is_mounted  [property_name]
        #    i[1] == False              [removed]
        #    i[2] == False              [added] 
        print "\nPropertyModified, device=%s, num=%s"%(device_udi,num_changes)
        for i in change_list:
            property_name = i[0]
            removed = i[1]
            added = i[2]
            print property_name,removed,added
            #print "  key=%s, rem=%d, add=%d"%(property_name, removed, added)
            if property_name=="info.parent": 
                self.update_device_list()        
            else:
                device_udi_obj = self.bus.get_object("org.freedesktop.Hal", device_udi)
                properties  = self.udi_to_properties(device_udi)
            
            # if from the udi of the devce is possible to find the modified property:
            # value = the value of the hal key:
            # ex: 
            #    key=volume.mount_point
            #    value=/media/usbdisk
            
            if device_udi_obj.PropertyExists(property_name, dbus_interface="org.freedesktop.Hal.Device"):
                properties[property_name] = device_udi_obj.GetProperty(property_name, 
                                                  dbus_interface="org.freedesktop.Hal.Device")
                print "  value=%s"%(properties[property_name])
                rules=RulesParser(filename=self.appdir+"/rules.xml", input=properties)
                #############################################################
                #                 ACTOR                                     #
                #                                                           #
                #if mount is true volume.mount_point property is modified   #
                #                                                           #
                #############################################################
                if "mount" in rules.actions.keys() and rules.actions["mount"]:
                    if property_name == "volume.mount_point":
                        actor=Actor(rules.actions,rules.required,properties,self.msg_render,self.config,self.voice )
                        # if val is empty don't do anything
                        actor.on_modified_mount(properties[property_name])
                else:
                    if property_name in rules.required.keys() and str(properties[property_name]) == str(rules.required[property_name]):
                        pass
                    else:
                        rules.actions={}
                        rules.required={}
            else:
                if device_obj != None:
                    try:
                        del device_obj.properties[property_name]
                    except:
                        pass
	
    def gdl_changed(self, signal_name, device_udi, *args):
        """
        This method is called when a HAL device is added 
        or removed.
        """
        #play sound 
        playsound_removed=''
        playsound_added=''
        if signal_name=="DeviceAdded":
            #print "\nDeviceAdded, udi=%s"%(device_udi)
            self.add_device_signal_recv(device_udi)
            self.update_device_dict()
            required,actions,properties=self.properties_rules(device_udi)
            #get traicon position as a tuple (x,y)
            coordinates=self.get_tray_coordinates(self.trayicon.tray)
            actor=Actor(actions,required,properties,self.msg_render,self.config,self.voice,coordinates=coordinates )
            actor.on_added()
           
                    
        elif signal_name=="DeviceRemoved":
            #print "\nDeviceRemoved, udi=%s"%(device_udi) 
            required,actions,properties=self.properties_rules(device_udi)
            #get traicon position as a tuple (x,y)
            coordinates=self.get_tray_coordinates(self.trayicon.tray)
            actor=Actor(actions,required,properties,self.msg_render,self.config,self.voice,coordinates=coordinates)
            actor.on_removed() 
            self.remove_device_signal_recv(device_udi)
            self.virtual_root.pop(device_udi)
            self.trayicon.on_rem_udi(device_udi)
        elif signal_name=="NewCapability":
            [cap] = args 
            #print "\nNewCapability, cap=%s, udi=%s"%(cap, device_udi)
            
        # not an hal signal: needed to add new parttions
        elif signal_name=="VolumeAdded":
             print "\nVolumeAdded, udi=%s"%(device_udi)
             device_dict=args[0]
             print device_dict.__class__
             self.trayicon.on_add_udi(device_udi,device_dict)
             #for i in device_dict[0]["vm.info.childs"]:
             #    for key in i.keys():
             #        print i[key]
             
            
        
        else:
            print "*** Unknown signal %s"% signal_name
        

    def add_device_signal_recv (self, udi):
	self.bus.add_signal_receiver(lambda *args: self.property_modified(udi, *args),
				     "PropertyModified",
				     "org.freedesktop.Hal.Device",
				     "org.freedesktop.Hal",
				     udi)
    def remove_device_signal_recv (self, udi):
        try:
            self.bus.remove_signal_receiver(None,
				            "PropertyModified",
				            "org.freedesktop.Hal.Device",
				            "org.freedesktop.Hal",
				            udi)
        except Exception, e:
            print "Older versions of the D-BUS bindings have an error when removing signals. Please upgrade."
            print e
    
    def build_device_dict(self):
        """
        Retrieves the device list from the HAL daemon and builds
        a tree of Device (Python) objects. The root is a virtual
        device.
        * vm.info.childs = list of udis of childs in parent
        * vm.info.product = info.product in child from parent
        """
        devices_dict={}
        device_names = self.hal_manager.GetAllDevices()
        
        for name in device_names:
            device_dbus_obj = self.bus.get_object("org.freedesktop.Hal" ,name)
            # properties is the list of hal properies of "name"
            properties = device_dbus_obj.GetAllProperties(dbus_interface="org.freedesktop.Hal.Device")
            # a dictionary of devices{udi:{properies}}
            if name not in devices_dict.keys():
                devices_dict[name]=properties
            # get even info.vendor and info.product for messages
            if "info.parent" in devices_dict[name].keys():
                parent_udi=devices_dict[name]["info.parent"]
                device_dbus_obj = self.bus.get_object("org.freedesktop.Hal" ,parent_udi) 
                parent_prop=device_dbus_obj.GetAllProperties(dbus_interface="org.freedesktop.Hal.Device")
                if parent_udi not in devices_dict.keys():
                    devices_dict[parent_udi]=parent_prop 
                new_volume={}
                if "block.is_volume" in devices_dict[name].keys() and devices_dict[name]["block.is_volume"] and "volume.fstype" and devices_dict[name]["volume.fstype"] != "swap":    
                    new_volume[name]=properties["block.device"]
                    icon=self.get_device_icon(devices_dict[parent_udi]["storage.drive_type"])
                    if "vm.info.childs" in devices_dict[parent_udi].keys():
                        devices_dict[parent_udi]["vm.info.childs"].append(new_volume)
                        #menu_list=[devices_dict[parent_udi],icon]
                        menu_list=[devices_dict,icon]
                        self.gdl_changed("VolumeAdded", parent_udi,menu_list)
                    else:
                        devices_dict[parent_udi]["vm.info.childs"]=[new_volume]
                        #menu_list=[devices_dict[parent_udi],icon]
                        menu_list=[devices_dict,icon]
                        self.gdl_changed("VolumeAdded",parent_udi,menu_list) 
                if "info.product" and "info.vendor" in parent_prop.keys():
                    devices_dict[name]["vm.info.vendor"]=parent_prop["info.vendor"]
                    devices_dict[name]["vm.info.product"]=parent_prop["info.product"]
        return devices_dict

    def get_device_icon(self,drive_type):
        """
        Given a device_type , return the icon path
        """
        if drive_type == "cdrom":
            icon=IconPath("gnome-dev-cdrom").icon_path 
        else:
            icon=IconPath("gnome-dev-harddisk").icon_path 
        return icon
        
    
    def update_device_dict(self):
        """
        Builds, or rebuilds, the device tree
        """
        self.virtual_root = self.build_device_dict()
 
    def udi_to_properties(self, device_udi):
        """
        Given a HAL UDI (Unique Device Identifier) this method 
        returns the corresponding HAL device
        """
        return self.virtual_root[device_udi]

    



def main(appdir="xml"):
    startdev = DeviceManager(appdir)
if __name__ == "__main__":
    main()
    
