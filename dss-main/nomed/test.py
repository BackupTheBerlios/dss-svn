import libxml2
#filename='test.xml'
input={'volume.fstype': 'iso9660', 'info.category': 'volume', 'info.parent': '/org/freedesktop/Hal/devices/storage_serial_Y24F827932', 'info.product': 'DSS Live', 'volume.fsusage': 'filesystem', 'block.minor': 0, 'volume.is_mounted': True, 'linux.sysfs_path': '/sys/block/hdc/fakevolume', 'volume.is_disc': True, 'volume.disc.has_data': True, 'linux.hotplug_type': 3, 'volume.policy.desired_mount_point': 'cdrecorder', 'volume.size': 331644928L, 'block.storage_device': '/org/freedesktop/Hal/devices/storage_serial_Y24F827932', 'volume.fsversion': '', 'volume.uuid': '', 'volume.mount_point': '/media/cdrom', 'volume.disc.is_blank': False, 'block.device': '/dev/hdc', 'info.udi': '/org/freedesktop/Hal/devices/volume_label_', 'block.is_volume': True, 'info.capabilities': ['volume', 'block'], 'volume.is_partition': True, 'volume.disc.has_audio': False, 'volume.disc.is_appendable': False, 'linux.sysfs_path_device': '/sys/block/hdc/fakevolume', 'volume.disc.is_rewritable': True, 'block.major': 22, 'volume.disc.type': 'cd_rw', 'volume.num_blocks': 647744, 'volume.label': 'DSS Live', 'volume.block_size': 2048}

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
filename='10-storage-policy.fdi'
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
    list_match=[]
    if reader.NodeType() not in a:
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
        #print reader.NodeType()
        
        if reader.NodeType() == 1: # Element
            #print '###'
            #while reader.Name() == 'match':
                #print reader.Depth(),reader.Value()
            tag=reader.Name()
            depth=reader.Depth()
            while reader.MoveToNextAttribute():
                #print reader.Depth(),reader.Value()
                #print '####'
                #print indent
                #print "%s * %d %d (%s) [%s]" % (indent, reader.Depth(), reader.NodeType(),reader.Name(),reader.Value())
                key=reader.Value()
                while reader.MoveToNextAttribute():
                    if reader.NodeType() == 2:
                        dict_match={}
                        dict_match[key]=reader.Value()
                        #print "%s %s %s" % (reader.Depth(),key,dict_match[key])
                        list_match=[tag,depth,dict_match]
                        print '%s %s'% (list_match,reader.NodeType())
                    
                       
                            
                            
            
                    
        #print dict_match
    #b=b+1
    #print b
    return list_match
    
def streamFile(filename):
    try:
        reader = libxml2.newTextReaderFilename(filename)
    except:
        print "unable to open %s" % (filename)
        return
    #num=reader.Depth()
    ret = reader.Read()
    
    while ret == 1: 
        list=processNode1(reader) 
        ret = reader.Read()
        while len(list) != 0:
            while reader.Depth() == list[1]:
                list=processNode1(reader)
                ret = reader.Read()
                print 'ciao'
            
       

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


