"""This file contains the Device class."""



class Device:
    def __init__(self, device_name, parent_name, properties):
        self.device_name = device_name
        #print self.device_name
        self.parent_name = parent_name
        self.parent_device = None
        self.properties = properties
        self.children = []

    def print_tree(self, indent):
        if indent==0:
            print " "*indent + self.device_name
        else:
            print " "*indent + "- " + self.device_name
        for c in self.children:
            c.print_tree(indent+4)

    
            
    def find_by_udi(self, device_udi):
        if self.device_name==device_udi:
            return self
        for c in self.children:
            rc = c.find_by_udi(device_udi)
            if rc!=None:
                return rc
        return None
