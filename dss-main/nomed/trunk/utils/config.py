#!/usr/bin/python
# -*- coding: utf8 -*-

import libxml2


class ConfigParser:
    
    def __init__(self,
                 filename="config.xml",
                 path="/config/*",
                 props=["key","value"]
                 ):
        doc = libxml2.parseFile(filename)
        ctxt = doc.xpathNewContext()
        self.dict_config={}
        res0 = ctxt.xpathEval(path)
        for i in range(len(res0)):
            tag=res0[i].name
            tagpath="/config/"+tag+"/match"
            #print tagpath
            res1=ctxt.xpathEval(tagpath)
            for k in range(len(res1)):
                #print res1[k].name
                haskey=res1[k].hasProp(props[0])
                hasvalue=res1[k].hasProp(props[1])
                
                if haskey != None and hasvalue != None:
                    #print "if2"
                    key=str(haskey.children)
                    value=str(hasvalue.children)
                    dictkey="config."+tag+"."+key
                    self.dict_config[dictkey]=value
           
        doc.freeDoc()

  

if __name__ == "__main__":
   
    filename="config.xml"
    path="/config"
    props=["key","value"]
    ConfigParser()
