#!/usr/bin/env python

## On Screen Display
## (C) 2004 Gustavo J. A. M. Carneiro <gustavo@users.sf.net>

## This library is free software; you can redistribute it and/or
## modify it under the terms of the GNU Lesser General Public
## License as published by the Free Software Foundation; either
## version 2 of the License, or (at your option) any later version.
import gobject
import pango
import gtk
import gtk.gdk as gdk

BORDER_WIDTH=1

def osd(text, bgcolor, fgcolor, fontdesc,
        use_markup=False, alignment=pango.ALIGN_CENTER,
        fake_translucent_bg=False, drop_shadow=False,
        max_width=None, debug_frame=True, ellipsize=pango.ELLIPSIZE_NONE,icon=None):
    assert isinstance(fontdesc, pango.FontDescription)
    win = gtk.Window(gtk.WINDOW_TOPLEVEL)
    #win.add_events(gtk.gdk.POINTER_MOTION_MASK)
    darea = gtk.DrawingArea()
    win.add(darea)
    darea.show()

    #------------------------LAYOUT-------------------------#
    if use_markup:
        layout = win.create_pango_layout('')
        layout.set_markup(text)
    else:
        layout = win.create_pango_layout(text)
    try:
        layout.set_ellipsize(ellipsize)
    except AttributeError:
        print "ellipsize attribute not supported, ignored"
    #layout.set_justify(False)
    #layout.set_alignment(alignment)
    layout.set_font_description(fontdesc)
    if max_width is None:
        MAX_WIDTH = gdk.screen_width() - 8
    else:
        MAX_WIDTH = max_width - 8
    #layout.set_width(pango.SCALE*MAX_WIDTH)
    
    if ellipsize != pango.ELLIPSIZE_NONE:
        layout.set_wrap(pango.WRAP_WORD)
    
    #-------------------ICON-------------------------------#
    pixbuf = gtk.gdk.pixbuf_new_from_file(icon)
    #split it in pixmap and mask (gtk.gdk.Pixmap)
    pixmap, mask = pixbuf.render_pixmap_and_mask() 
    
    
    # set size
    i_width, i_height = pixmap.get_size() 
    l_width, l_height = layout.get_pixel_size()
    if i_width > l_width:
        width=i_width
    else:
        width=l_width

    height=i_height+l_height
    
    
    off_x = BORDER_WIDTH*2
    off_y = BORDER_WIDTH*2

    if alignment == pango.ALIGN_CENTER:
        #off_x -= MAX_WIDTH/2 - width/2
        off_x -= 0
    elif alignment == pango.ALIGN_RIGHT:
        off_x -= MAX_WIDTH - width
    
    width += BORDER_WIDTH*4
    height += BORDER_WIDTH*4

    # disbling drop shadow
    
    #if drop_shadow:
    #    drop_shadow_distance = max(2, int(fontdesc.get_size()/pango.SCALE*0.1))
    #    width += drop_shadow_distance
    #    height += drop_shadow_distance
    darea.set_size_request(width, height)
    darea.realize()
    pixmap = gtk.gdk.Pixmap(darea.window, width, height)
    #pixmap.set_colormap(darea.window.get_colormap())
    
    fg_gc = gdk.GC(pixmap); fg_gc.copy(darea.style.fg_gc[gtk.STATE_NORMAL])
    bg_gc = gdk.GC(pixmap); bg_gc.copy(darea.style.fg_gc[gtk.STATE_NORMAL])
    fg_gc.set_foreground(darea.get_colormap().alloc_color(fgcolor))
    bg_gc.set_background(darea.get_colormap().alloc_color(bgcolor))
    pixmap.draw_rectangle(bg_gc, True, 0, 0, width, height)
    pixmap.draw_layout(fg_gc, off_x, off_y + i_height, layout)
    pixmap.draw_pixbuf(fg_gc, pixbuf, 
                                     0, 0,
                                     width/2 -i_width/2, 
                                     0, 
                                    width=-1, height=-1, dither=gtk.gdk.RGB_DITHER_NORMAL, x_dither=0, y_dither=0)   

    if debug_frame:
        pixmap.draw_rectangle(fg_gc, False, 0, 0, width - 1, height - 1)

    bitmap = gtk.gdk.Pixmap(darea.window, width, height, 1)
    #bitmap.set_colormap(darea.window.get_colormap())
    
    fg_gc = gdk.GC(bitmap)
    bg_gc = gdk.GC(bitmap)
    fg_gc.set_foreground(gdk.Color(pixel=-1))
    bg_gc.set_background(gdk.Color(pixel=0))


    bitmap.draw_rectangle(bg_gc, True, 0, 0, width, height)
    bitmap.draw_layout(fg_gc, off_x, off_y + i_height, layout)
    bitmap.draw_drawable(fg_gc, mask, 
                                     0, 0,
                                     width/2 - i_width/2, 
                                     0, 
                                     width=48, height=48)
    #bitmap.draw_layout(fg_gc, off_x + BORDER_WIDTH, off_y, layout)
    #bitmap.draw_layout(fg_gc, off_x + BORDER_WIDTH, off_y + BORDER_WIDTH, layout)
    #bitmap.draw_layout(fg_gc, off_x, off_y + BORDER_WIDTH, layout)
    #bitmap.draw_layout(fg_gc, off_x - BORDER_WIDTH, off_y + BORDER_WIDTH, layout)
    #bitmap.draw_layout(fg_gc, off_x - BORDER_WIDTH, off_y, layout)
    #bitmap.draw_layout(fg_gc, off_x - BORDER_WIDTH, off_y - BORDER_WIDTH, layout)
    #bitmap.draw_layout(fg_gc, off_x, off_y - BORDER_WIDTH, layout)
    #bitmap.draw_layout(fg_gc, off_x + BORDER_WIDTH, off_y - BORDER_WIDTH, layout)

    if drop_shadow:
        bitmap.draw_layout(fg_gc, off_x + drop_shadow_distance,
                           off_y + drop_shadow_distance, layout)
    if debug_frame:
        bitmap.draw_rectangle(fg_gc, False, 0, 0, width - 1, height - 1)

    darea.window.set_back_pixmap(pixmap, False)
    #win.window.shape_combine_mask(bitmap, 0, 0)
    win.width = width
    win.height = height
    return win




if __name__ == '__main__':
    w = osd("Hallo Yuch\ndesktop icons",
            #"<i>Hello</i> <span size='larger' weight='bold'>World</span>"
            #"<span foreground='red'>!</span>", 
            "#000000", "#FFFFFF",
            pango.FontDescription("sans serif bold 12"),
            max_width=300 ,
            use_markup=False, 
            drop_shadow=False, 
            ellipsize=pango.ELLIPSIZE_NONE,
            icon="images/gnome-gimp.png")
    #w.move(gdk.screen_width()/2 - w.width/2, gdk.screen_height() - w.height - 10)
    w.show()
    gtk.main()

