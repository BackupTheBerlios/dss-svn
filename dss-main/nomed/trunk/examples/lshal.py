import dbus
if getattr(dbus, 'version', (0,0,0)) >= (0,41,0):
    import dbus.glib
from utils.device import Device
import sys
device_udi = '/org/freedesktop/Hal/devices/volume_uuid_C025_4348'
udi_dict = {}
bus = dbus.SystemBus()
hal_manager_obj = bus.get_object('org.freedesktop.Hal', '/org/freedesktop/Hal/Manager')
hal_manager = dbus.Interface(hal_manager_obj,'org.freedesktop.Hal.Manager')
device_names = hal_manager.GetAllDevices() 
device_udi_obj = bus.get_object("org.freedesktop.Hal", device_udi)
#print device_udi_obj

device_names.sort()

#print device_names

virtual_root = Device("virtual_root", None, {})

device_list = [virtual_root]

#print device_list

for name in device_names:
    device_dbus_obj = bus.get_object("org.freedesktop.Hal" ,name)
    properties = device_dbus_obj.GetAllProperties(dbus_interface="org.freedesktop.Hal.Device")
    try:
        parent_name = properties["info.parent"]
    except KeyError:
        # no parent, must be parent of virtual_roo
        parent_name = "/"
    except TypeError:
        print "Error: no properties for device %s"%name
        continue
    device = Device(name, parent_name, properties)
    device_list.append(device)

#print device_list

for device in device_list:
    parent_name = device.parent_name
    #print parent_name
    device.parent_device = virtual_root
    if parent_name!="/":
        for p in device_list:
            if p.device_name==parent_name:
                device.parent_device = p
                p.children.append(device)
    if device!=virtual_root and device.parent_device==virtual_root:
        virtual_root.children.append(device)
    if device==virtual_root:
        device.parent_device=None

#device_obj = virtual_root.find_by_udi(device_udi)
if len(sys.argv) == 1:
    device_udi=device_names
else:
    device_udi=[sys.argv[1]]
#
for udi in device_udi:
    print
    print "--------------"
    print "udi: %s" %(udi)
    device_prop = virtual_root.find_by_udi(udi)
    for key in  device_prop.properties.keys():
        print "%s: %s" % (key,device_prop.properties[key])
    #for key in device_prop.properties.keys():

    #    print "%s : %s" % (key ,device_prop.properties[key])

#print device_obj.properties.keys()
