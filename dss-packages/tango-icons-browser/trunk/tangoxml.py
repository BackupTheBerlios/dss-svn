#!/usr/bin/env python
# -*- coding: UTF8 -*-
from xml.dom import minidom
import sys
import getopt
import toolbox
class TangoGenerator:
    """generates  grammar"""

    def __init__(self, grammar):
        self.loadGrammar(grammar)

    def _load(self, source):
        """load XML input source, return parsed XML document
        """
        sock = toolbox.openAnything(source)
        xmldoc = minidom.parse(sock).documentElement
        sock.close()
        return xmldoc

    def loadGrammar(self, grammar):                         
        """load context-free grammar"""                     
        self.grammar = self._load(grammar)                  
        self.icons = {}                                      
        for icon in self.grammar.getElementsByTagName("icon"):
            self.icons[icon.attributes["name"].value] = icon
    
    
def main(argv):                         
    grammar = "/usr/share/icon-naming-utils/legacy-icon-mapping.xml"                
    try:                                
        opts, args = getopt.getopt(argv, "hg:d", ["help", "grammar="])
    except getopt.GetoptError:          
        usage()                         
        sys.exit(2)                     
    for opt, arg in opts:               
        if opt in ("-h", "--help"):     
            usage()                     
            sys.exit()                  
        elif opt == '-d':               
            global _debug               
            _debug = 1                  
        elif opt in ("-g", "--grammar"):
            grammar = arg               

    #source = "".join(args)              
    tangoicons = TangoGenerator(grammar)
    #print tangoicons.icons.keys()
    list=[]
    for i in tangoicons.icons.keys():
        list.append(str(i))
    print list

if __name__ == "__main__":
    main(sys.argv[1:])

   
