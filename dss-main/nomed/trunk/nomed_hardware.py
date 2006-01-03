#!/usr/bin/python
# -*- coding: utf8 -*- 
import gtk
import dbus
if getattr(dbus, 'version', (0,0,0)) >= (0,41,0):
    import dbus.glib
from utils.device import Device
#from nomed import Notify

class DeviceManager:
    def __init__(self): 
       
            
        self.udi_dict = {}
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

       
        #self.virtual_root = self.build_device_tree()
        #print self.virtual_root.print_tree(0)
        
        # Add listeners for all devices
        try:
            device_names = self.hal_manager.GetAllDevices()
        except:
            print 'add here notification-daemon error'
        
        #print device_names
        
        for name in device_names:
	        self.add_device_signal_recv (name); 
        self.update_device_list()
        gtk.main()
    
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
        print "#######################"
        print num_changes
        print "#######################"
        print change_list
        print "#######################"  
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
                device_obj = self.udi_to_device(device_udi)
            
            # if from the udi of the devce is possible to find the modified property:
            # value = the value of the hal key:
            # ex: 
            #    key=volume.mount_point
            #    value=/media/usbdisk
            
            if device_udi_obj.PropertyExists(property_name, dbus_interface="org.freedesktop.Hal.Device"):
                device_obj.properties[property_name] = device_udi_obj.GetProperty(property_name, 
                                                  dbus_interface="org.freedesktop.Hal.Device")
                print "  value=%s"%(device_obj.properties[property_name])
                
                # run notification-daemon if volume has been mounted
                if property_name == 'volume.mount_point':
                    print "Notify here"
                    #Notify(device_obj.properties[property_name])

            else:
                if device_obj != None:
                    try:
                        del device_obj.properties[property_name]
                    except:
                        pass

            #device_focus_udi = self.get_current_focus_udi()
            #if device_focus_udi != None:
            #    device = self.udi_to_device(device_udi)
            #    if device_focus_udi==device_udi:
            #        self.update_device_notebook(device)
	
    def gdl_changed(self, signal_name, device_udi, *args):
        """This method is called when a HAL device is added or removed."""
        self.virtual_root = self.build_device_tree
        if signal_name=="DeviceAdded":
            print "\nDeviceAdded, udi=%s"%(device_udi)
            #Notify(device_udi)
	    self.add_device_signal_recv (device_udi)
            self.update_device_list()
        elif signal_name=="DeviceRemoved":
            print "\nDeviceRemoved, udi=%s"%(device_udi)
            #Notify(device_udi) 
	    self.remove_device_signal_recv (device_udi)
            self.update_device_list()
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
    
    def build_device_tree(self):
        """Retrieves the device list from the HAL daemon and builds
        a tree of Device (Python) objects. The root is a virtual
        device"""
        device_names = self.hal_manager.GetAllDevices()
        device_names.sort()

        virtual_root = Device("virtual_root", None, {})
        self.device_list = [virtual_root]
        
        # first build list of Device objects
        # name == device's udi 
        for name in device_names:
            device_dbus_obj = self.bus.get_object("org.freedesktop.Hal" ,name)

            # properties is the list of hal properies of "name"
            properties = device_dbus_obj.GetAllProperties(dbus_interface="org.freedesktop.Hal.Device")
            #print 
            #print "#######################"
            #print properties
            #print "#######################" 
            try:
                parent_name = properties["info.parent"]
            except KeyError:
                # no parent, must be parent of virtual_root
                parent_name = "/"
            except TypeError:
                print "Error: no properties for device %s"%name
                continue
            device = Device(name, parent_name, properties)
            self.device_list.append(device)

        # set parent_device and children for each Device object
        for device in self.device_list:
            parent_name = device.parent_name
            device.parent_device = virtual_root
            if parent_name!="/":
                for p in self.device_list:
                    if p.device_name==parent_name:
                        device.parent_device = p
                        p.children.append(device)
            if device!=virtual_root and device.parent_device==virtual_root:
                virtual_root.children.append(device)
            if device==virtual_root:
                device.parent_device=None
        return virtual_root
    
    def update_device_list(self):
        """Builds, or rebuilds, the device tree"""
        # We use a virtual root device so we have a single tree
        self.virtual_root = self.build_device_tree()
 
    def udi_to_device(self, device_udi):
        """Given a HAL UDI (Unique Device Identifier) this method returns
        the corresponding HAL device"""
        #self.virtual_root = self.build_device_tree
        return self.virtual_root.find_by_udi(device_udi) 

    



def main():
    startdev = DeviceManager()
if __name__ == "__main__":
    #pkges = 'abiword-gnome'
    main()
    
