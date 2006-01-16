#!/usr/bin/python
# -*- coding: utf8 -*-

import libxml2


class VoiceParser:
    
    def __init__(self,
                 filename="voice.xml",
                 path="/voice/*",
                 props=["key","value"],
                 filepath="/tmp/."
                 ):
        xmlvesrion='<?xml version="1.0"?>'
        dtd='<!DOCTYPE SABLE PUBLIC "-//SABLE//DTD SABLE speech mark up//EN" "Sable.v0_2.dtd" []>'
        self.dict_voice={}
        doc = libxml2.parseFile(filename)
        ctxt = doc.xpathNewContext()
        res = ctxt.xpathEval(path)
        for i in range(len(res)):
            #tag=res[i].name
            haskey=res[i].hasProp(props[0])
            hasvalue=res[i].hasProp(props[1])
            if haskey != None and hasvalue != None:
                key=str(haskey.children)
                value=str(hasvalue.children)
                dictkey="voice."+key
                if value == "@content":
                    tagsable="/voice/"+res[i].name+"["+str(i+1)+"]"+"/SABLE"
                    dotsable=filepath+key+".sable"
                    f=open(dotsable,"w")
                    f.flush() 
                    f.write(xmlvesrion)
                    f.write(dtd)
                    ctxt.xpathEval(tagsable)[0].saveTo(f)
                    f.close()                   
                    self.dict_voice[dictkey]=dotsable
           
        doc.freeDoc()

  

if __name__ == "__main__":
   
    filename="voice.xml"
    path="/voice"
    props=["key","value"]
    VoiceParser()
