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
        
        #define tags
        self.dict_config={"tag.n":"\n"}
        self.dict_config["tag.bash"]='"'
        self.dict_config["tag.bopen"]="<b>"
        self.dict_config["tag.bclose"]="</b>"
        self.dict_config["tag.sayopen"]='SAY="'
        self.dict_config["tag.sayclose"]=self.dict_config["tag.bash"]
        
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
                    if value == "@content":
                        value=res1[k].content
                        print k,value
                    self.dict_config[dictkey]=value
           
        doc.freeDoc()

  

if __name__ == "__main__":
   
    filename="config.xml"
    path="/config"
    props=["key","value"]
    ConfigParser()
