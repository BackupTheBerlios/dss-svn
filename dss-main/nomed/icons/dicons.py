#!/usr/bin/env python

import pygtk
pygtk.require('2.0')
import gtk, pango
BORDER_WIDTH=1
DEFAULT_WIDTH = 0
DEFAULT_HEIGHT = 0
class GraphArea(gtk.DrawingArea):
    def __init__(self,text, bgcolor, fgcolor, fontdesc,
        use_markup=False, alignment=pango.ALIGN_CENTER,
        fake_translucent_bg=False, drop_shadow=False,
        max_width=None, debug_frame=False, ellipsize=pango.ELLIPSIZE_NONE,icon=None, container=None):
        
        self.text=text
        self.bgcolor=bgcolor
        self.fgcolor=fgcolor
        self.fontdesc=fontdesc
        self.use_markup=use_markup
        self.alignment=alignment
        self.max_width=max_width
        self.debug_frame=debug_frame
        self.ellipsize=ellipsize
        self.drop_shadow=drop_shadow
        self.icon=icon
        self.cont=container
        self.mouse_state=0

        gtk.DrawingArea.__init__(self)
        self.set_size_request(int(DEFAULT_WIDTH), int(DEFAULT_HEIGHT)) # initial size
        self.connect('button-press-event', self.on_button_press_event)
        self.connect('button-release-event', self.on_button_press_event)
        self.connect('motion-notify-event', self.motion_notify_event)
        self.connect("expose_event", self.on_expose_event)
        self.connect('realize', self.on_realize)
        self.set_events(gtk.gdk.BUTTON_PRESS_MASK | gtk.gdk.POINTER_MOTION_MASK | gtk.gdk.BUTTON_RELEASE_MASK)
    
    def on_realize(self, sender):
        pass
        #print "realize"
        #self.chain(self, sender) # chain calls the overriden callback first
        #self.draw_pixbuf()
        #self.draw_layout()
        
    def on_expose_event(self, widget, event):
        self.draw_pixbuf()
        self.draw_layout()
        self.start_size()
        self.set_size_request(self.width,self.height)
        self.draw_pixmap()
        self.draw_bitmap()
        self.cont.show()
        self.window.set_back_pixmap(self.pixmap, False)
        self.cont.window.shape_combine_mask(self.bitmap, 0, 0)
        

    def draw_layout(self):
        
        if self.use_markup:
            self.layout = self.create_pango_layout('')
            self.layout.set_markup(self.text)
        else:

            self.layout = self.win.create_pango_layout(self.text)
           
        try:
            self.layout.set_ellipsize(self.ellipsize)

        except AttributeError:
            print "ellipsize attribute not supported, ignored"

        self.layout.set_font_description(self.fontdesc)

    def draw_pixbuf(self):
        """A new pixbuf from file, return self.pixmap and self.mask"""
        self.pixbuf = gtk.gdk.pixbuf_new_from_file(self.icon)
        self.iconpixmap, self.mask = self.pixbuf.render_pixmap_and_mask() 
    
    def start_size(self):
        """Set costants, it calls draw_pixbuf and draw_layout"""

        if self.max_width is None:
            MAX_WIDTH = gtk.gdk.screen_width() - 8
        else:
            MAX_WIDTH = self.max_width - 8



        self.l_width, self.l_height = self.layout.get_pixel_size()
        self.i_width, self.i_height = self.iconpixmap.get_size() 

        #if self.i_width > self.l_width:
        #    self.width=self.i_width
        #else:
        #    self.width=self.l_width
        self.width=self.i_width*2

        self.height=self.i_height+self.l_height

        self.off_x = BORDER_WIDTH*2
        self.off_y = BORDER_WIDTH*2
        self.width += BORDER_WIDTH*4
        self.height += BORDER_WIDTH*4

    def draw_pixmap(self):
        self.pixmap = gtk.gdk.Pixmap(self.window, self.width, self.height)
        self.pmap_fg_gc = gtk.gdk.GC(self.pixmap); self.pmap_fg_gc.copy(self.style.fg_gc[gtk.STATE_NORMAL])
        self.pmap_bg_gc = gtk.gdk.GC(self.pixmap); self.pmap_bg_gc.copy(self.style.fg_gc[gtk.STATE_NORMAL])
        self.pmap_fg_gc.set_foreground(self.get_colormap().alloc_color(self.fgcolor))
        self.pmap_bg_gc.set_background(self.get_colormap().alloc_color(self.bgcolor))
        self.pixmap.draw_rectangle(self.pmap_bg_gc, True, 0, 0, self.width, self.height)
        self.pixmap.draw_layout(self.pmap_fg_gc, self.off_x, self.off_y + self.i_height, self.layout)
        self.pixmap.draw_pixbuf(self.pmap_fg_gc, self.pixbuf, 
                                         0, 0,
                                         self.width/2 -self.i_width/2, 
                                         0, 
                                        width=-1, height=-1, dither=gtk.gdk.RGB_DITHER_NORMAL, x_dither=0, y_dither=0)   

        if self.debug_frame:
            self.pixmap.draw_rectangle(self.pmap_fg_gc, False, 0, 0, self.width - 1, self.height - 1)

    def draw_bitmap(self):
        self.bitmap = gtk.gdk.Pixmap(self.window, self.width, self.height, 1)
        #bitmap.set_colormap(darea.window.get_colormap())
        
        self.bmap_fg_gc = gtk.gdk.GC(self.bitmap)
        self.bmap_bg_gc = gtk.gdk.GC(self.bitmap)
        self.bmap_fg_gc.set_foreground(gtk.gdk.Color(pixel=-1))
        self.bmap_bg_gc.set_background(gtk.gdk.Color(pixel=0))


        self.bitmap.draw_rectangle( self.bmap_bg_gc, True, 0, 0, self.width, self.height)
        self.bitmap.draw_layout( self.bmap_fg_gc, self.off_x, self.off_y + self.i_height, self.layout)
        self.bitmap.draw_drawable(  self.bmap_fg_gc, self.mask, 
                                         0, 0,
                                         self.width/2 - self.i_width/2, 
                                         0, 
                                         width=48, height=48)

        if self.drop_shadow:
            self.bitmap.draw_layout( self.bmap_fg_gc, self.off_x + self.drop_shadow_distance,
                               self.off_y + self.drop_shadow_distance, self.layout)
        if self.debug_frame:
            self.bitmap.draw_rectangle( self.bmap_fg_gc, False, 0, 0, self.width - 1, self.height - 1)


    def on_button_press_event(self,widget, event):
        # which button was clicked?
        if event.button == 1:
            #from Nomed.utils.notification import NotificationDaemon
            #self.msg_render=NotificationDaemon()
            #self.msg_render.show_info("ciao","prova")
            #self.realize()
            #self.show()
            
            print "1"
        elif event.button == 2:
            print "middle click"
        elif event.button == 3:
            print "right click"
        # was it a multiple click?
        if event.type == gtk.gdk.BUTTON_PRESS:
            if event.button == 1:
                self.mouse_state=1
            self.debug_frame=True
            #self.realize()
            #self.show()
            self.cont.queue_draw()
            
            print "single click"
        elif event.type == gtk.gdk._2BUTTON_PRESS:
            print "double click"             
        elif event.type == gtk.gdk._3BUTTON_PRESS:
            print "triple click. ouch, you hurt your user."
        elif event.type == gtk.gdk.BUTTON_RELEASE:
            if event.button == 1:
                self.mouse_state=0
            self.debug_frame=False
            self.cont.queue_draw()
            print "realased"

    def motion_notify_event(self,widget, event):
 
        rootwin = widget.get_screen().get_root_window()
        x, y, mods = rootwin.get_pointer()
        x1,y1=self.cont.get_size()
        print "Mouse moved to", event.x, event.y
        print "Root window", x , y
        print "Window size",self.cont.get_size()
        if self.mouse_state==1:
            self.cont.move(x-x1/2,y-y1/2)


def main():
    gtk.main()
    return False
if __name__ == "__main__":
    
    window = gtk.Window(gtk.WINDOW_TOPLEVEL)
    window.set_default_size(1, 1)
    window.set_resizable(False)
    window.stick()
    window.set_keep_below(True)
    window.set_type_hint(gtk.gdk.WINDOW_TYPE_HINT_MENU)
    darea = GraphArea("<i>Hello</i><span size='larger' weight='bold'>Yuch</span><span foreground='red'>desktop icons</span>", 
            "#000000", "#FFFFFF",
            pango.FontDescription("sans serif 10"),
            max_width=300 ,
            use_markup=True, 
            drop_shadow=False, 
            ellipsize=pango.ELLIPSIZE_NONE,icon="images/camera-video.svg",container=window)
    window.add(darea)
    darea.show()
    darea.realize()
    window.connect("destroy", gtk.main_quit)
    window.set_title("DrawingArea example")
    window.set_decorated(False)
    #window.set_border_width(10)
    window.show()


    main()

        
        
            
