#!/usr/bin/python
# -*- coding: utf8 -*-

import libxml2


class RulesParser:
    
    def __init__(self,
                 filename="xml/rules.xml",
                 input={},
                 path="/deviceinfo/device/*[1]",
                 props=["key","value"]
                 ):
        doc = libxml2.parseFile(filename)
        ctxt = doc.xpathNewContext()
        required={}
        actions={}
        res = ctxt.xpathEval(path)
        while res[0].name != "device":
            match=res[0] 
            if match.name == "match":
                #print "if1"
                haskey=match.hasProp(props[0])
                hasvalue=match.hasProp(props[1])
                if haskey != None and hasvalue != None:
                    #print "if2"
                    key=str(haskey.children)
                    value=str(hasvalue.children)
                    if value == "true" or value == "false":
                        value=value.capitalize()
                    #print required

                    if key in input.keys() and str(input[key]) == value:
                        required[key]=value
                        #print "<match>"
                        #print key,value
                        #print "</match>"
                        #print key,input[key]
                        #print "if3"
                        if ctxt.xpathEval(path+"/merge") != []:
                            #print "if43"
                            path=path+"/merge"  
                            res = ctxt.xpathEval(path)
                        elif ctxt.xpathEval(path+"/*[1]"):
                            #print "else4"
                            path=path+"/*[1]" 
                            res = ctxt.xpathEval(path)
                        else:
                            path="/devinceinfo/device"
                            res = ctxt.xpathEval(path)
                    else:
                        #print "else3"
                        res = ctxt.xpathEval(path)
                        if ctxt.xpathEval(self.PathIncrease(path,pop=False)) != []: 
                            #print "if5"
                            path=self.PathIncrease(path,pop=False)
                            res = ctxt.xpathEval(path)
                            
                        else:
                            #print "else5"    
                            #print path
                            path=self.PathIncrease(path,pop=True)
                            res = ctxt.xpathEval(path)
                            #print path
                            if len(res) == 0:
                                path=self.PathIncrease(path,pop=True)
                                res = ctxt.xpathEval(path) 
                            
                            
            elif match.name == "merge":
                actions["notify"]=[]
                actions["unotify"]=[]
                for match in res:
                    haskey=match.hasProp(props[0])
                    hasvalue=match.hasProp(props[1])
                    if haskey != None and hasvalue != None:
                        key=str(haskey.children)
                        value=str(hasvalue.children)
                        if key == "mount":
                            value=value.capitalize()
                            if value == "True":
                                value=True
                            elif value == "False":
                                value=False
                            actions[key]=value
                        elif key == "notify" or key == "unotify":
                            hasmessage=match.hasProp("message")
                            #hasaction=match.hasProp("action")
                            hasicon=match.hasProp("icon")
                            if hasmessage != None:
                                message=str(hasmessage.children)
                            else:
                                message=None
                            if hasicon != None:
                                icon=str(hasicon.children)
                            else:
                                icon=None
                            #if hasaction != None:
                            #    action=str(hasaction.children)
                            #else:
                            #    action=None
                            
                            actions[key].append([value,message,icon])
                        else:
                            if key in actions.keys():
                                actions[key].append(value)
                            else:
                                actions[key]=[value]
                break
            #print path
        self.required=required
        self.actions=actions
        #print self.required,self.actions
        #print self.actions
        doc.freeDoc()
        
        

    def PathIncrease(self,string,pop):
        a=string.split("/")
        a.pop(0)
        if pop == True:
            a.pop()
            #print path
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

if __name__ == "__main__":
    input={'volume.fstype': 'iso9660', 'info.category': 'volume', 'info.parent': '/org/freedesktop/Hal/devices/storage_serial_Y24F827932', 'info.product': 'DSS Live', 'volume.fsusage': 'filesystem', 'block.minor': 0, 'volume.is_mounted': True, 'linux.sysfs_path': '/sys/block/hdc/fakevolume', 'volume.is_disc': True, 'volume.disc.has_data': True, 'linux.hotplug_type': 3, 'volume.policy.desired_mount_point': 'cdrecorder', 'volume.size': 331644928L, 'block.storage_device': '/org/freedesktop/Hal/devices/storage_serial_Y24F827932', 'volume.fsversion': '', 'volume.uuid': '', 'volume.mount_point': '/media/cdrom', 'volume.disc.is_blank': False, 'block.device': '/dev/hdc', 'info.udi': '/org/freedesktop/Hal/devices/volume_label_', 'block.is_volume': True, 'info.capabilities': ['volume', 'block'], 'volume.is_partition': True, 'volume.disc.has_audio': False, 'volume.disc.is_appendable': False, 'linux.sysfs_path_device': '/sys/block/hdc/fakevolume', 'volume.disc.is_rewritable': True, 'block.major': 22, 'volume.disc.type': 'cd_rw', 'volume.num_blocks': 647744, 'volume.label': 'DSS Live', 'volume.block_size': 2048}
    filename="test/rules.xml"
    path="/deviceinfo/device/*[1]"
    props=["key","value"]
    RulesParser(input=input)
