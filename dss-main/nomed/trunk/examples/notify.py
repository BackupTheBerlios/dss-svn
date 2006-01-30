#!/usr/bin/python
"""Usage"""
from subprocess import PIPE, Popen
import os.path
import sys
import getopt
from Nomed.utils.notification import NotificationDaemon

class Notifier:
    def __init__(self):
        self.msg_render=NotificationDaemon() 
        
    def mountcmd(self,cmd,todo):
        if todo == 1:
            command = "pmount"
        elif todo == 0:
            command = "pumount"
        p1 = Popen(command+ " " + cmd, shell=True, stdout=PIPE, stderr=PIPE)
       
        p1.poll()
        toprint=p1.communicate()
        self.error=toprint[1]
        self.output=toprint[0]      
        return self.error, self.output
    def command(self,cmd):
        os.system(cmd)

def usage():
    print __doc__
def main(argv):                         
    nomed=Notifier() 
    command = ''
    summary = ''
    message = ''
    device = ''
    try:                                
        opts, args = getopt.getopt(argv, "hs:m:c:p:u:", ["help", "summary=", "message=", "command=", "device="])
    except getopt.GetoptError:          
        usage()                         
        sys.exit(2)                     
    for opt, arg in opts:               
        if opt in ("-h", "--help"):     
            usage()                     
            sys.exit()                                 
        elif opt in ("-s", "--summary"):
            summary = arg
            #print summary
        elif opt in ("-m", "--message"):
            message = arg
            #print message
        elif opt in ("-c", "--command"):
            command = arg
        elif opt in ("-p", "--pmount"):
            device = arg
            m=1
        elif opt in ("-u", "--pumount"):
            device = arg
            m=0
            
    if device != '':       
        nomed.mountcmd(device,m) 
        if nomed.error != '':
           nomed.msg_render.show_error(summary,nomed.error)
        elif nomed.error == '':
           summary='prova'
           actions = {"Click me": None}
           nid=nomed.msg_render.show(summary,message + '\n' + nomed.output,"gtk-dialog-info",actions = actions)
           self.msg_render.close(nid)
  
    else:
        if command != '':
            nomed.command(command)
            message=message  + command
            print message
        #nomed.msg_render.show_info(summary,message)
	
        def perf_action(act):
            os.system(act) 
        def open_volume():
            os.system('thunar ') 

        actions = {"Mount": open_volume, "Umount": "echo ciao", "Properties": "echo ciao" }
        nid=nomed.msg_render.show(summary,message,"gtk-dialog-info",actions = actions )
        #nomed.msg_render.close(nid)
    source = "".join(args)              
    

    #k = KantGenerator(grammar, source)
    #print k.output()

if __name__ == "__main__":
    main(sys.argv[1:])
