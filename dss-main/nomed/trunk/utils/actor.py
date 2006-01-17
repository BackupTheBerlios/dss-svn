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

    def __init__(self,actions,required, properties,msg_render,config,sable):
        
        self.msg_render=msg_render
        self.properties=properties
        self.udi=properties['info.udi']
        self.actions=actions
        self.config=config
        self.sable=sable
        self.cmdaction=''
        self.tagslist=["/n","<b>","</b>",'"','SAY="']
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
        
        #print self.actions
        self.exe,self.exeun,self.mount,self.sound,self.notify,self.unotify,self.voice,self.voiceun=self.convert_actions(self.actions)
        
        
    def cmd_exec(self):
        os.system(self.cmdaction) 
                
    def convert_var(self,string,properties):
        """Convert hal variables (keys) in strings (values)"""
        if "$" in string:
            list=string.split()
            for i in range(len(list)):
                if list[i].startswith("$") and list[i].endswith("$"):
                    key=list[i].replace("$","")
                    if key in properties.keys():
                        val=properties[key]
                    elif key in self.config.keys():
                        val=self.config[key]
                    elif key in self.sable.keys():
                        val=self.sable[key]

                    list[i]=val
            string=""
            for i in list:
                #check if the tag \n is present: new line
                if i in self.tagslist:
                    string="%s%s" %(string,i)
                else:
                    string="%s %s" %(string,i)
            #string=string.strip()
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
        sound=['off']
        voice=[]
        voiceun=[]
        for tag in actions.keys():
            if tag == "exec":
                for string in actions[tag]:
                    string=string.strip()
                    if not string.endswith("&"):
                        string="%s %s" % (string,"&")
                    exe.append(string)
            elif tag == "execun":
                for string in actions[tag]:
                    string=string.strip()
                    if not string.endswith("&"):
                        string="%s %s" % (string,"&")
                    exeun.append(string)        
            elif tag == "mount":
                mount=actions[tag]
            elif tag == "sound":
                sound=actions[tag]
            elif tag == "notify":
                for string in actions[tag]:
                    notify.append(string)
            elif tag == "unotify":
                for string in actions[tag]:
                    unotify.append(string)
            elif tag == "say":
                for string in actions[tag]:
                    voice.append(string)
            elif tag == "sayun":
                for string in actions[tag]:
                    voiceun.append(string)
       # print self.config
        return exe,exeun,mount,sound,notify,unotify,voice,voiceun
    
        
    def on_added(self):
        if self.sound[0] == 'on': 
            self.cmdaction="%s %s" %(self.config["config.sound.exec"],self.config["config.sound.added"])
            self.cmd_exec()
       

        #this is just in case of mount=True
        # then PropertyChange signal occurs
        if self.mount == True:
            dev=self.properties["block.device"]
            summary=self.properties["info.product"]
            body="%s %s" % ("block device",dev)
            cmdmount="%s %s" % ("pmount",dev)
            straction="%s %s" % ("Mount",self.properties["info.category"])
             
            #def pmount():
            #    os.system(cmdmount)
            self.cmdaction=cmdmount
            actions={straction: self.cmd_exec}
            

            if self.properties["volume.fstype"] == "iso9660":
                icon=IconPath(self.config["config.icon.cdrom"]).icon_path
                #icon=gtk.STOCK_CDROM
            else:
                icon=IconPath(self.config["config.icon.harddisk"]).icon_path
                       # print messages
            print "   %s: %s" % ("Icon",str(icon))
            print "   %s: %s" % ("Sound",self.sound)
            print "   %s: %s" % ("Summary",str(summary))
            print "   %s: %s" % ("Body",str(body))
            #print "   %s: %s" % ("Action",)
            print "   %s: %s" % ("Action",cmdmount) 

            self.msg_render.show(summary,body,actions=actions,icon=icon,expires=0)
            for app in self.voice:
                print "   Say: %s" % app
                self.cmdaction=app
                self.cmd_exec()   
            
        else:
            for app in self.exe:
                print "   Exec: %s" % app
                self.cmdaction=app
                self.cmd_exec() 

        for notify_list in self.notify:
            icon=IconPath(notify_list[ICON].strip())
            if icon.icon_path == None:
                icon.icon_path = "gtk-dialog-info"
            # print messages
            print "   %s: %s" % ("Icon",icon.icon_path) 
            print "   %s: %s" % ("Summary",notify_list[SUMMARY])
            print "   %s: %s" % ("Body",notify_list[MESSAGE])
 
            #print notify_list
            self.msg_render.show(notify_list[SUMMARY],
                        notify_list[MESSAGE],
                        icon.icon_path
                        )
    

    def on_removed(self):
        if self.sound[0] == "on": 
            self.cmdaction="%s %s" %(self.config["config.sound.exec"],self.config["config.sound.removed"])
            self.cmd_exec()
        for app in self.exeun:
            print "   Execun: %s" % app
            self.cmdaction=app
            self.cmd_exec()
        for unotify_list in self.unotify:
            icon=IconPath(unotify_list[ICON].strip())
            if icon.icon_path == None:
                icon.icon_path = "gtk-dialog-info"
            
            # print messages
            print "   %s: %s" % ("Icon",icon.icon_path)
            print "   %s: %s" % ("Summary",unotify_list[SUMMARY])
            print "   %s: %s" % ("Body",unotify_list[MESSAGE] )

            self.msg_render.show(unotify_list[SUMMARY],
                        unotify_list[MESSAGE],
                        icon.icon_path
                        )
        for app in self.voiceun:
            print "   Say: %s" % app
            self.cmdaction=app
            self.cmd_exec()       
    
    def on_modified(self):
        for app in self.exe:
            print "  exec=%s" %app
            self.cmdaction=app
            self.cmd_exec() 
         
    def on_modified_mount(self,val):
        if val == "":
            
            dev=self.properties["block.device"]
            summary=self.properties["info.product"]
            body="%s %s" % ("block device",dev)
            cmdaction="%s %s" % (self.config["config.static.eject"],dev)
            straction="%s %s" % (self.config["config.static.streject"],self.properties["info.category"])
             

            
            
            # print messages
            print "   %s: %s" % ("Summary",summary)
            print "   %s: %s" % ("Body",body)
            #print "   %s: %s" % ("Action",)
            print "   %s: %s" % ("Action",cmdaction)
            if self.properties["volume.fstype"] == "iso9660":
                icon=IconPath(self.config["config.icon.cdrom"]).icon_path
                self.cmdaction=cmdaction
                actions={straction: self.cmd_exec} 
                
            else:
                actions=""
                icon=IconPath(self.config["config.icon.harddisk"]).icon_path
            
            self.msg_render.show(summary,body,actions=actions,icon=icon,expires=0)
        else:
            for app in self.exe:
                print "  exec=%s" %app
                self.cmdaction=app
                self.cmd_exec()
        
           
        

if __name__ == "__main__":
    input={'volume.fstype': 'vfat', 'info.category': 'volume', 'info.parent': '/org/freedesktop/Hal/devices/storage_model_MSCN', 'info.product': 'Volume (vfat)', 'volume.fsusage': 'filesystem', 'volume.policy.should_mount': True, 'block.minor': 32, 'volume.is_disc': False, 'linux.sysfs_path': '/sys/block/sdc/fakevolume', 'volume.policy.desired_mount_point': 'usbdisk', 'volume.size': 124649472L, 'block.storage_device': '/org/freedesktop/Hal/devices/storage_model_MSCN', 'volume.fsversion': 'FAT16', 'volume.uuid': 'C025-4348', 'volume.mount_point': '', 'block.device': '/dev/sdc', 'info.udi': '/org/freedesktop/Hal/devices/volume_uuid_C025_4348', 'info.capabilities': ['volume', 'block'], 'volume.label': '', 'volume.is_partition': True, 'volume.policy.mount_filesystem': 'vfat', 'block.is_volume': True, 'linux.sysfs_path_device': '/sys/block/sdc/fakevolume', 'linux.hotplug_type': 3, 'block.major': 8, 'volume.is_mounted': False, 'volume.num_blocks': 243456, 'volume.block_size': 512}

    action={'exeun': ['thunar $info.udi$'], 'exec': ['thunar', 'prova ', 'thunar prova'], 'mount':True}
    a=Actor(action,"",input,"")
    #print Actor.actions
    a.on_added()
