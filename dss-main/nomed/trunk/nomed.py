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
import os.path
#from nomed import Notify

class DeviceManager:
    def __init__(self):
        
        self.msg_render=NotificationDaemon()     
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
        self.hal_manager.connect_to_signal("DeviceRemoved", 
                         lambda *args: self.gdl_changed("DeviceRemoved", *args))
        self.hal_manager.connect_to_signal("NewCapability", 
                         lambda *args: self.gdl_changed("NewCapability", *args)) 

       
        
       
        
        # Add listeners for all devices
        try:
            device_names = self.hal_manager.GetAllDevices()
        except:
            print 'add here notification-daemon error'
        
        
        
        for name in device_names:
	        self.add_device_signal_recv (name); 
        
        self.update_device_dict()
        # config.xml dict
        config=ConfigParser()
        self.config=config.dict_config
        # voice.xml dict
        voice=VoiceParser()
        self.voice=voice.dict_voice
        gtk.main()
        
    def properties_rules(self,device_udi):
        properties = self.udi_to_properties(device_udi) 
        rules=RulesParser(input=properties)
        required=rules.required
        actions=rules.actions
        return required,actions,properties

        
    def property_modified(self, device_udi, num_changes, change_list):
        """This method is called when signals on the Device interface is
        received"""
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
        print "\nPropertyModified, device=%s"%device_udi
        for i in change_list:
            #print i
            property_name = i[0]
            removed = i[1]
            added = i[2]
           
            print "  key=%s, rem=%d, add=%d"%(property_name, removed, added)
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
        
                rules=RulesParser(input=properties)
                

                #############################################################
                #                 ACTOR                                     #
                #                                                           #
                #if mount is true volume.mount_point is modified property   #
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

                #################################################################
                    
                #print device_obj.properties 
                    

            else:
                if device_obj != None:
                    try:
                        del device_obj.properties[property_name]
                    except:
                        pass
	
    def gdl_changed(self, signal_name, device_udi, *args):
        """This method is called when a HAL device is added or removed."""
        #play sound 
        playsound_removed=''
        playsound_added=''
        if signal_name=="DeviceAdded":
            print "\nDeviceAdded, udi=%s"%(device_udi)
            self.add_device_signal_recv(device_udi)
            self.update_device_dict()
            required,actions,properties=self.properties_rules(device_udi)
            actor=Actor(actions,required,properties,self.msg_render,self.config,self.voice )
            actor.on_added()
        elif signal_name=="DeviceRemoved":
            print "\nDeviceRemoved, udi=%s"%(device_udi) 
            required,actions,properties=self.properties_rules(device_udi)

            actor=Actor(actions,required,properties,self.msg_render,self.config,self.voice)

            actor.on_removed() 
            self.remove_device_signal_recv(device_udi)
            self.virtual_root.pop(device_udi)
        elif signal_name=="NewCapability":
            [cap] = args 
            print "\nNewCapability, cap=%s, udi=%s"%(cap, device_udi)
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
        """Retrieves the device list from the HAL daemon and builds
        a tree of Device (Python) objects. The root is a virtual
        device"""
        devices_dict={}
        device_names = self.hal_manager.GetAllDevices()
        for name in device_names:
            device_dbus_obj = self.bus.get_object("org.freedesktop.Hal" ,name)
            # properties is the list of hal properies of "name"
            properties = device_dbus_obj.GetAllProperties(dbus_interface="org.freedesktop.Hal.Device")
            # a dictionary of devices{udi:{properies}}
            devices_dict[name]=properties
            # get even info.vendor and info.product for messages
            #if "info.vendor"  and "info.product" not in devices_dict[name].keys():
            if "info.parent" in devices_dict[name].keys():
                parent=devices_dict[name]["info.parent"]
                device_dbus_obj = self.bus.get_object("org.freedesktop.Hal" ,parent) 
                parent_prop=device_dbus_obj.GetAllProperties(dbus_interface="org.freedesktop.Hal.Device")
                #get info.vendor and info.product from parent
                if "info.product" and "info.vendor" in parent_prop.keys():
                    devices_dict[name]["vm.info.vendor"]=parent_prop["info.vendor"]
                    devices_dict[name]["vm.info.product"]=parent_prop["info.product"]
        return devices_dict

        
    
    def update_device_dict(self):
        """Builds, or rebuilds, the device tree"""
        # We use a virtual root device so we have a single tree
        self.virtual_root = self.build_device_dict()
 
    def udi_to_properties(self, device_udi):
        """Given a HAL UDI (Unique Device Identifier) this method returns
        the corresponding HAL device"""
        return self.virtual_root[device_udi]

    



def main():
    startdev = DeviceManager()
if __name__ == "__main__":
    main()
    
