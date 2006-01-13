#!/usr/bin/python
# -*- coding: utf8 -*-

import libxml2

input={'volume.fstype': 'iso9660', 'info.category': 'volume', 'info.parent': '/org/freedesktop/Hal/devices/storage_serial_Y24F827932', 'info.product': 'DSS Live', 'volume.fsusage': 'filesystem', 'block.minor': 0, 'volume.is_mounted': True, 'linux.sysfs_path': '/sys/block/hdc/fakevolume', 'volume.is_disc': True, 'volume.disc.has_data': True, 'linux.hotplug_type': 3, 'volume.policy.desired_mount_point': 'cdrecorder', 'volume.size': 331644928L, 'block.storage_device': '/org/freedesktop/Hal/devices/storage_serial_Y24F827932', 'volume.fsversion': '', 'volume.uuid': '', 'volume.mount_point': '/media/cdrom', 'volume.disc.is_blank': False, 'block.device': '/dev/hdc', 'info.udi': '/org/freedesktop/Hal/devices/volume_label_', 'block.is_volume': True, 'info.capabilities': ['volume', 'block'], 'volume.is_partition': True, 'volume.disc.has_audio': False, 'volume.disc.is_appendable': False, 'linux.sysfs_path_device': '/sys/block/hdc/fakevolume', 'volume.disc.is_rewritable': True, 'block.major': 22, 'volume.disc.type': 'cd_rw', 'volume.num_blocks': 647744, 'volume.label': 'DSS Live', 'volume.block_size': 2048}

filename="/usr/share/nomed/rules.xml"
path="/deviceinfo/device/*[1]"
props=["key","value"]
class RulesParser:
    
    def __init__(self,filename,input):
        doc = libxml2.parseFile(filename)
        ctxt = doc.xpathNewContext()
        self.required={}
        self.actions={}
        res = ctxt.xpathEval(path)
        

    def PathIncrease(string,pop):
        a=string.split("/")
        a.pop(0)
        if pop == True:
            a.pop()
        if a[len(a) - 1] == "device":
            string=""
            pass
        else:
            string=""
            index=len(a[len(a)-1]) - 2
            num=int(a[len(a)-1][index]) + 1
            a[len(a)-1]=a[len(a)-1].split("[")[0]+"["+str(num)+"]"
            #print a
        for i in a:
            string=string+"/"+i
        return string


