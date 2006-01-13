import dbus
from icon import IconPath
import os.path
(
        SUMMARY,
        MESSAGE,
        ICON,
        ACTION
) = range(4)

class Actor:

    def __init__(self,actions,required, properties,msg_render):
        
        self.msg_render=msg_render
        self.properties=properties
        self.udi=properties['info.udi']
        self.actions=actions
        #convert hal variable
        for key in self.actions.keys():
            if key != "mount":
                if key != "notify" and key != "unotify":
                    for i in range(len(self.actions[key])):
                        self.actions[key][i]=self.convert_var(self.actions[key][i],self.properties)
                else:
                    for listindex in range(len(self.actions[key])):
                        for i in range(len(self.actions[key][listindex])): 
                            self.actions[key][listindex][i]=self.convert_var(self.actions[key][listindex][i],self.properties)
        print self.actions
        self.exe,self.exeun,self.mount,self.notify,self.unotify=self.convert_actions(self.actions)
        
        

    def convert_var(self,string,properties):
        """Convert hal variables (keys) in strings (values)"""
        if "$" in string:
            list=string.split()
            for i in range(len(list)):
                if list[i].startswith("$") and list[i].endswith("$"):
                    key=list[i].replace("$","")
                    if key in properties.keys():
                        val=properties[key]
                        list[i]=val
            string=""
            for i in list:
                string="%s %s" %(string,i)
            string=string.strip()
        return string
        
    def convert_actions(self,actions):
        """Convert split actions dic and convert hal variables
        using convert_var"""
        #actions_tags=["exec","execun","mount","notify"]
        exe=[]
        exeun=[]
        mount=False
        notify=[]
        unotify=[]
        for tag in actions.keys():
            if tag == "exec":
                for string in actions[tag]:
                    string=string.strip()
                    if not string.endswith("&"):
                        string="%s %s" % (string,"&")
                    exe.append(string)
            elif tag == "exeun":
                for string in actions[tag]:
                    string=string.strip()
                    if not string.endswith("&"):
                        string="%s %s" % (string,"&")
                    exeun.append(string)
            elif tag == "mount":
                #for string in actions[tag]:
                #    mount.append(string)
                mount=actions[tag]
            elif tag == "notify":
                for string in actions[tag]:
                    notify.append(string)
            elif tag == "unotify":
                for string in actions[tag]:
                    unotify.append(string)
        return exe,exeun,mount,notify,unotify
    
    def run_app(self,appname):
        os.system(appname)
        
    def on_added(self):
        if self.mount == True:
            dev=self.properties["block.device"]
            mountcmd="%s %s" % ("pmount",dev)
            print "  exec=%s" % mountcmd
            print
            #self.run_app(mountcmd)
            def pmount():
                os.system(mountcmd)
            #action={"prova": pmount}
            pmount()
            self.msg_render.show_info("volume.mount_point","prova",actions=action)
            
        else:
            for app in self.exe:
                self.run_app(app)
        for notify_list in self.notify:
            icon=IconPath(notify_list[ICON])
            if icon.icon_path == None:
                icon.icon_path = "gtk-dialog-info"
            self.msg_render.show(notify_list[SUMMARY],
                        notify_list[MESSAGE],
                        icon.icon_path
                        )
                

    def on_removed(self):
        for app in self.exeun:
           print "  exeun=%s" % app
           self.run_app(app)
        print self.unotify
        for unotify_list in self.unotify:
            icon=IconPath(unotify_list[ICON])
            if icon.icon_path == None:
                icon.icon_path = "gtk-dialog-info"
            self.msg_render.show(unotify_list[SUMMARY],
                        unotify_list[MESSAGE],
                        icon.icon_path
                        )
            print unotify_list[SUMMARY]
                
    
    def on_modified(self):
        for app in self.exe:
            print "  exec=%s" %app
            self.run_app(app) 
         
    def on_modified_mount(self,val):
        if val == "":
            pass
        else:
            for app in self.exe:
                print "  exec=%s" %app
                self.run_app(app)
        
            
        

if __name__ == "__main__":
    input={'volume.fstype': 'vfat', 'info.category': 'volume', 'info.parent': '/org/freedesktop/Hal/devices/storage_model_MSCN', 'info.product': 'Volume (vfat)', 'volume.fsusage': 'filesystem', 'volume.policy.should_mount': True, 'block.minor': 32, 'volume.is_disc': False, 'linux.sysfs_path': '/sys/block/sdc/fakevolume', 'volume.policy.desired_mount_point': 'usbdisk', 'volume.size': 124649472L, 'block.storage_device': '/org/freedesktop/Hal/devices/storage_model_MSCN', 'volume.fsversion': 'FAT16', 'volume.uuid': 'C025-4348', 'volume.mount_point': '', 'block.device': '/dev/sdc', 'info.udi': '/org/freedesktop/Hal/devices/volume_uuid_C025_4348', 'info.capabilities': ['volume', 'block'], 'volume.label': '', 'volume.is_partition': True, 'volume.policy.mount_filesystem': 'vfat', 'block.is_volume': True, 'linux.sysfs_path_device': '/sys/block/sdc/fakevolume', 'linux.hotplug_type': 3, 'block.major': 8, 'volume.is_mounted': False, 'volume.num_blocks': 243456, 'volume.block_size': 512}

    action={'exeun': ['thunar $info.udi$'], 'exec': ['thunar', 'prova ', 'thunar prova'], 'mount':True}
    a=Actor(action,"",input,"")
    #print Actor.actions
    a.on_added()
