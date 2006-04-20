#!/usr/bin/python
# -*- coding: UTF8 -*-

# Warning: Do not modify any context comment such as #--
# They are required to keep user's code

import os
import gtk
import icondata

from SimpleGladeApp import SimpleGladeApp
from SimpleGladeApp import bindtextdomain

app_name = "tango-icons"
app_version = "0.0.1"

glade_dir = ""
locale_dir = ""

bindtextdomain(app_name, locale_dir)

(
    COLUMN_PIXBUF,
    COLUMN_NAME,
    COLUMN_PATH
) = range(3)

data=icondata.IconPath().data
tangodata=icondata.IconPath().datatango
class Window(SimpleGladeApp):

    def __init__(self, path="tango-icons.glade",
                 root="window",
                 domain=app_name, **kwargs):
        path = os.path.join(glade_dir, path)
        SimpleGladeApp.__init__(self, path, root, domain, **kwargs)
        

    #-- Window.new {
    def new(self):
        #print "A new %s has been created" %self.__class__.__name__
        self.lstore = gtk.ListStore(gtk.gdk.Pixbuf,str,str )
        self.liststore=self.__create_model(data,self.lstore)
        self.treeview.set_model(self.liststore)
        self.__add_columns(self.treeview)
        self.rstore = gtk.ListStore(gtk.gdk.Pixbuf,str,str ) 
        self.liststoretango=self.__create_model(tangodata,self.rstore) 
        self.treetango.set_model(self.liststoretango)
        self.__add_columns(self.treetango)
        self.xfceicons=icondata.IconPath().xfceicons
    #-- Window.new }

    #-- Window custom methods {
    #   Write your own methods here
    #-- Window custom methods }
    def __create_model(self,datamodel,store):
        #store = gtk.ListStore(
        #    gtk.gdk.Pixbuf,
        #    str,
        #    str)
        for item in datamodel:
            iter = store.append()
            #print "####"
            #print item[0]
            #print item[1]
            #print item[2]
            store.set(iter,
                COLUMN_PIXBUF, item[COLUMN_PIXBUF],
                COLUMN_NAME, item[COLUMN_NAME],
                COLUMN_PATH, item[COLUMN_PATH])
        return store
 
    def __add_columns(self, treeview):
        column = gtk.TreeViewColumn('Icon', gtk.CellRendererPixbuf(),pixbuf=COLUMN_PIXBUF)
        treeview.append_column(column)
        column = gtk.TreeViewColumn('Name', gtk.CellRendererText(),text=COLUMN_NAME)
        column.set_sort_column_id(COLUMN_NAME)
        column.set_resizable(True)
        #column.set_sizing(gtk.TREE_VIEW_COLUMN_AUTOSIZE)
        treeview.append_column(column)
        column = gtk.TreeViewColumn('Path', gtk.CellRendererText(),text=COLUMN_PATH)
        column.set_sort_column_id(COLUMN_PATH)
        column.set_resizable(True)
        #column.set_sizing(gtk.TREE_VIEW_COLUMN_AUTOSIZE)
        treeview.append_column(column)

#-- main {

def main():
    window = Window()
    for xfceicon in window.xfceicons:
        print xfceicon
    window.run()
    

if __name__ == "__main__":
    main()

#-- main }
