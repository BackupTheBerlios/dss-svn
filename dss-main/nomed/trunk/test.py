import libxml2
#filename='test.xml'
"""
    *  NodeType: The node type, 
    ** 1 for start element, 
    ** 15 for end of element, 
    ** 2 for attributes, 
    ** 3 for text nodes, 
    ** 4 for CData sections, 
    ** 5 for entity references, 
    ** 6 for entity declarations, 
    ** 7 for PIs, 
    ** 8 for comments, 
    ** 9 for the document nodes, 
    ** 10 for DTD/Doctype nodes, 
    ** 11 for document fragment and 
    ** 12 for notation nodes.
    * Name: the qualified name of the node, equal to (Prefix:)LocalName.
    * LocalName: the local name of the node.
    * Prefix: a shorthand reference to the namespace associated with the node.
    * NamespaceUri: the URI defining the namespace associated with the node.
    * BaseUri: the base URI of the node. See the XML Base W3C specification.
    * Depth: the depth of the node in the tree, starts at 0 for the root node.
    * HasAttributes: whether the node has attributes.
    * HasValue: whether the node can have a text value.
    * Value: provides the text value of the node if present.
    * IsDefault: whether an Attribute node was generated from the default value defined in the DTD or schema (unsupported yet).
    * XmlLang: the xml:lang scope within which the node resides.
    * IsEmptyElement: check if the current node is empty, this is a bit bizarre in the sense that <a/> will be considered empty while <a></a> will not.
    * AttributeCount: provides the number of attributes of the current node.

"""
filename='/usr/share/hal/fdi/policy/10osvendor/10-storage-policy.fdi'
dict_match={}
dict_rules=[]
#filename='/home/debaser/.ivman/IvmConfigActions.xml'
def processNode(reader):
    #print "%d %d %s %d %s" % (reader.Depth(), reader.NodeType(),
    #                          reader.Name(), reader.IsEmptyElement(),
    #                          reader.Value())
    a=[15,14,8]
    
    if reader.NodeType() not in a:
        indent=' '*reader.Depth()
        print "%s %d %d (%s) [%s] " %(
            indent,
            reader.Depth(),
            reader.NodeType(),
            reader.Name(),
            #reader.LocalName(),
            #reader.Prefix(),
            #reader.NamespaceUri(),
            #reader.BaseUri(),
            #reader.HasAttributes(),
            #reader.HasValue(),
            reader.Value(),
            #reader.IsDefault,
            #reader.XmlLang(),
            #reader.IsEmptyElement(),
            #reader.AttributeCount()
            )
        if reader.NodeType() == 1: # Element
            while reader.MoveToNextAttribute():
		print '####'
		print indent
                print "%s * %d %d (%s) [%s]" % (indent, reader.Depth(), reader.NodeType(),reader.Name(),reader.Value())
def processNode1(reader):
    #print "%d %d %s %d %s" % (reader.Depth(), reader.NodeType(),
    #                          reader.Name(), reader.IsEmptyElement(),
    #                          reader.Value())
    a=[15,14,8]
    b=1
    if reader.NodeType() not in a:
        indent=' '*reader.Depth()
        #print "%s %d %d (%s) [%s] " %(
        #    indent,
        #    reader.Depth(),
        #    reader.NodeType(),
        #    reader.Name(),
            #reader.LocalName(),
            #reader.Prefix(),
            #reader.NamespaceUri(),
            #reader.BaseUri(),
            #reader.HasAttributes(),
            #reader.HasValue(),
        #    reader.Value(),
            #reader.IsDefault,
            #reader.XmlLang(),
            #reader.IsEmptyElement(),
            #reader.AttributeCount()
        #    )
        if reader.NodeType() == 1: # Element
            #print '###'
            while reader.Name() == 'match':
                while reader.MoveToNextAttribute():
                    #print '####'
                    #print indent
                    #print "%s * %d %d (%s) [%s]" % (indent, reader.Depth(), reader.NodeType(),reader.Name(),reader.Value())
                    key=reader.Value()
                    num=1
                    while reader.MoveToNextAttribute(): 
                        dict_match[key]=reader.Value()
                        indent=reader.Depth()*' '
                        num=num+1
                        print " %s %s %s %s" % (str(num),reader.Depth(),key,dict_match[key])
                    
        #print dict_match
    b=b+1
    print b
    return dict_match
    
def streamFile(filename):
    try:
        reader = libxml2.newTextReaderFilename(filename)
    except:
        print "unable to open %s" % (filename)
        return

    ret = reader.Read()
    num=reader.Depth() 
    #print ret
    while ret == 1:
        
        #print reader.Name()
        ret = reader.Read() 
        processNode1(reader) 
        
        while reader.Depth() == num + 1:
            print "%s %s %s" % ('###Num + 1',reader.Depth(),reader.Name())
            processNode1(reader)
            print "depth %s" %(reader.Depth())
            num = num +1
            #num = 
            #tri = tri +1 
            #print "tri %s" % (tri)
       # while reader.Depth() == num :
       #     print '###Num ' 
       #     processNode1(reader)
        

    if ret != 0:
        print "%s : failed to parse" % (filename)

    #print processNode1(reader)
    dict_rules.append(processNode1(reader))
   # print dict_rules
    return dict_rules

a=streamFile(filename)
#print a
#for i in a:
#    print i


