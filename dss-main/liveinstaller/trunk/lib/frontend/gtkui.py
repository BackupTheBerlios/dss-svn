# -*- coding: utf-8 -*-
#
# «gtkui» - interfaz de usuario GTK
#
# Copyright (C) 2005 Junta de Andalucía
#
# Autores (Authors):
#
# - Javier Carranza <javier.carranza#interactors._coop>
# - Juan Jesús Ojeda Croissier <juanje#interactors._coop>
# - Antonio Olmo Titos <aolmo#emergya._info>
# - Gumer Coronel Pérez <gcoronel#emergya._info>
#
# Este fichero es parte del instalador en directo de Guadalinex 2005.
#
# El instalador en directo de Guadalinex 2005 es software libre. Puede
# redistribuirlo y/o modificarlo bajo los términos de la Licencia Pública
# General de GNU según es publicada por la Free Software Foundation, bien de la
# versión 2 de dicha Licencia o bien (según su elección) de cualquier versión
# posterior.
#
# El instalador en directo de Guadalinex 2005 se distribuye con la esperanza de
# que sea útil, pero SIN NINGUNA GARANTÍA, incluso sin la garantía MERCANTIL
# implícita o sin garantizar la CONVENIENCIA PARA UN PROPÓSITO PARTICULAR. Véase
# la Licencia Pública General de GNU para más detalles.
#
# Debería haber recibido una copia de la Licencia Pública General junto con el
# instalador en directo de Guadalinex 2005. Si no ha sido así, escriba a la Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
# USA.
#
# -------------------------------------------------------------------------
#
# This file is part of Guadalinex 2005 live installer.
#
# Guadalinex 2005 live installer is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the License, or
# at your option) any later version.
#
# Guadalinex 2005 live installer is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Guadalinex 2005 live installer; if not, write to the Free Software Foundation,
# Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
##################################################################################

""" U{pylint<http://logilab.org/projects/pylint>} mark: -28.40!!! (bad
    indentation and accesses to undefined members) """

from sys import stderr
import pygtk
pygtk.require('2.0')

import gtk.glade
import os
import time
import glob
import thread

from gettext import bindtextdomain, textdomain, install,gettext
from Queue import Queue

from ue.backend import *
from ue.validation import *
from ue.misc import *
from ue.backend.peez2 import *

# Define Ubuntu Express global path
#PATH = '/usr/share/ubuntu-express'
PATH = '/usr/share/liveinstaller'

# Define glade path
GLADEDIR = os.path.join(PATH, 'glade')

# Define locale path
LOCALEDIR = "/usr/share/locale"

_ = gettext

class Wizard:

  def __init__(self, distro):
    # declare attributes
    self.distro = distro
    self.hostname = ''
    self.fullname = ''
    self.name = ''
    self.gparted = True
    self.password = ''
    self.mountpoints = {}
    self.part_labels = {' ' : ' '}
    self.remainder = 0

    # Peez2 stuff initialization:
    self.__assistant = None

    # To get a "busy mouse":
    self.watch = gtk.gdk.Cursor(gtk.gdk.WATCH)

    # useful dicts to manage UI data
    self.entries = {
                    'hostname' : 0,
                    'fullname' : 0,
                    'username' : 0,
                    'password' : 0,
                    'verified_password' : 0
                    }

    # Start a timer to see how long the user runs this program
    self.start = time.time()

    # set custom language
    self.set_locales()

    # If automatic partitioning fails, it may be disabled toggling on this variable:
    self.discard_automatic_partitioning = False

    # load the interface
    self.glade = gtk.glade.XML('%s/dsslive.glade' % GLADEDIR)

    # get widgets
    for widget in self.glade.get_widget_prefix(""):
      setattr(self, widget.get_name(), widget)

    self.customize_installer()
    


  def run(self):
    """run the interface."""

    # show interface
    #self.show_browser()
    
    # Resizing labels according to screen resolution
    for widget in self.glade.get_widget_prefix(""):
      if widget.__class__ == gtk.Label and widget.get_name()[-6:-1] == 'label':
        msg = self.resize_text(widget, widget.get_name()[-1:])
        if msg != '':
          widget.set_markup(msg)
    #self.on_help_clicked(self.warning_info)

    # Declare SignalHandler
    self.glade.signal_autoconnect(self)

    # mouse
    #self.live_installer.window.set_cursor (None) 
    
    # Start the interface
    
    gtk.main()
    


  def customize_installer(self):
    """Customizing logo and images."""
    # images stuff
    import locale
    self.lang = locale.getdefaultlocale()[0].split('_')[0]
    messages_uri = os.path.join(PATH, 'htmldocs/', self.distro, self.lang, 'messages.txt') 
    if os.path.exists(messages_uri):
        pass
    else:
        messages_uri = os.path.join(PATH, 'htmldocs/', self.distro, 'en', 'messages.txt') 
    self.install_image = 0
    PIXMAPSDIR = os.path.join(GLADEDIR, 'pixmaps', self.distro)
    self.total_images   = glob.glob("%s/snapshot*.png" % PIXMAPSDIR)
    self.total_images.reverse()
    self.total_messages = open(messages_uri).readlines()
    SHOOTSDIR = os.path.join(PATH, 'htmldocs/', self.distro, self.lang) 
    if os.path.exists(SHOOTSDIR):
        pass
    else:
        SHOOTSDIR = os.path.join(PATH, 'htmldocs/', self.distro, 'en') 
    print SHOOTSDIR
    # set pixmaps
    if ( gtk.gdk.get_default_root_window().get_screen().get_width() > 1024 ):
      self.photo0.set_from_file(os.path.join(PIXMAPSDIR, "photo_1280.png"))
      self.logo_image0.set_from_file(os.path.join(PIXMAPSDIR, "logo_1280.jpg"))
      self.logo_image1.set_from_file(os.path.join(PIXMAPSDIR, "logo_1280.jpg"))
      self.photo1.set_from_file(os.path.join(PIXMAPSDIR, "photo_1280.jpg"))
      self.logo_image21.set_from_file(os.path.join(PIXMAPSDIR, "logo_1280.jpg"))
      self.logo_image22.set_from_file(os.path.join(PIXMAPSDIR, "logo_1280.jpg"))
      self.logo_image23.set_from_file(os.path.join(PIXMAPSDIR, "logo_1280.jpg"))
      self.logo_image3.set_from_file(os.path.join(PIXMAPSDIR, "logo_1280.jpg"))
      #self.photo2.set_from_file(os.path.join(PIXMAPSDIR, "photo_1280.jpg"))
      self.logo_image4.set_from_file(os.path.join(PIXMAPSDIR, "logo_1280.jpg"))
    else:
      self.photo0.set_from_file(os.path.join(PIXMAPSDIR, "photo_1024.png"))
      self.logo_image0.set_from_file(os.path.join(PIXMAPSDIR, "logo_1024.jpg"))
      self.logo_image1.set_from_file(os.path.join(PIXMAPSDIR, "logo_1024.jpg"))
      self.photo1.set_from_file(os.path.join(PIXMAPSDIR, "photo_1024.jpg"))
      self.logo_image21.set_from_file(os.path.join(PIXMAPSDIR, "logo_1024.jpg"))
      self.logo_image22.set_from_file(os.path.join(PIXMAPSDIR, "logo_1024.jpg"))
      self.logo_image23.set_from_file(os.path.join(PIXMAPSDIR, "logo_1024.jpg"))
      self.logo_image3.set_from_file(os.path.join(PIXMAPSDIR, "logo_1024.jpg"))
      #self.photo2.set_from_file(os.path.join(PIXMAPSDIR, "photo_1024.jpg"))
      self.logo_image4.set_from_file(os.path.join(PIXMAPSDIR, "logo_1024.jpg"))

    self.installing_image.set_from_file(os.path.join(PIXMAPSDIR, "snapshot1.png"))
    # set shoots 
    self.snapshoot1.set_from_file(os.path.join(SHOOTSDIR, "snapshot1.png"))
    self.snapshoot2.set_from_file(os.path.join(SHOOTSDIR, "snapshot2.png"))
    self.snapshoot3a.set_from_file(os.path.join(SHOOTSDIR, "snapshot3a.png"))
    self.snapshoot3b.set_from_file(os.path.join(SHOOTSDIR, "snapshot3b.png"))
    self.snapshoot3c.set_from_file(os.path.join(SHOOTSDIR, "snapshot3c.png"))
    self.snapshoot4.set_from_file(os.path.join(SHOOTSDIR, "snapshot4.png"))
    self.snapshoot5.set_from_file(os.path.join(SHOOTSDIR, "snapshot5.png"))

    # set fullscreen mode
    self.live_installer.fullscreen()
    self.live_installer.set_keep_above(True)
    self.live_installer.show()
    #self.live_installer.window.set_cursor(self.watch)

    # set initial bottom bar status
    self.back.hide()
    self.help.show()
    #self.help.connect('clicked', self.on_show_browser)
    self.next.set_label('gtk-go-forward')
    color=gtk.gdk.color_parse('#ffffff')
    self.eventbox1.modify_bg(gtk.STATE_NORMAL,color)
    self.eventbox2.modify_bg(gtk.STATE_NORMAL,color)
    self.eventbox3.modify_bg(gtk.STATE_NORMAL,color)

  def set_locales(self):
    """internationalization config. Use only once."""

    domain = self.distro + '-installer'
    bindtextdomain(domain, LOCALEDIR)
    gtk.glade.bindtextdomain(domain, LOCALEDIR )
    gtk.glade.textdomain(domain)
    textdomain(domain)
    install(domain, LOCALEDIR, unicode=1)
    

    

  def show_browser1(self):
    """Embed Mozilla widget into a vbox."""

    import gtkmozembed
    
    
    widget = gtkmozembed.MozEmbed()
    index = 'index.' + self.lang + '.html'
    local_uri = os.path.join(PATH, 'htmldocs/', self.distro, index) 
    if os.path.exists(local_uri):
        pass
    else:
        local_uri = os.path.join(PATH, 'htmldocs/', self.distro, 'index.html') 
    # Loading branding if htmldocs/ brand exists. In other hand Ubuntu Project
    #   website is loaded
    try:
      widget.load_url("file://" + local_uri)
    except:
      widget.load_url("http://www.ubuntulinux.org/")
    widget.get_location()
    self.browser_vbox.add(widget)
    widget.show()

    # Setting Normal mouse cursor
    #self.live_installer.window.set_cursor(None)


  def resize_text (self, widget, type):
    """set different text sizes from screen resolution."""

    if widget.__class__ == str :
      msg = widget
    elif isinstance (widget, list):
      msg = '\n'.join (widget)
    else:
      msg = widget.get_text()

    if ( gtk.gdk.get_default_root_window().get_screen().get_width() > 1024 ):
      if ( type in  ['1', '4'] ):
        msg = '<big>' + msg + '</big>'
      elif ( type == '2' ):
        msg = '<big><b>' + msg + '</b></big>'
      elif ( type == '3' ):
        msg = '<span font_desc="22">' + msg + '</span>'
    else:
      if type != '4':
        msg = ''
    return msg

  # Methods

  def gparted_loop(self):
    """call gparted and embed it into glade interface."""

    pre_log('info', 'gparted_loop()')
    # Save pid to kill gparted when install process starts
    #self.gparted_pid = part.call_gparted(self.embedded)
    self.gparted_pid = part.call_gparted(self.gparted_embedded)
    # gparted must be launched once only
    self.gparted = False


  def get_sizes(self):
    """return a dictionary with skeleton { partition : size }
    from /proc/partitions ."""

    # parsing /proc/partitions and getting size data
    temp = open('/proc/partitions').readlines()
    size = {}
    for line in temp:
      try:
        size[line.split()[3]] = int(line.split()[2])
      except:
        continue
    return size


  def set_size_msg(self, widget):
    """return a string message with size value about
    the partition target by widget argument."""

    # widget is studied in a different manner depending on object type
    if widget.__class__ == str :
      size = float(self.size[widget.split('/')[2]])
    else:
      size = float(self.size[self.part_labels.keys()[self.part_labels.values().index(widget.get_active_text())].split('/')[2]])

    # building size_msg
    if ( size > 1048576 ):
      msg = '%.0f Gb' % (size/1024/1024)
    elif ( size > 1024 and size < 1048576 ):
      msg = '%.0f Mb' % (size/1024)
    else:
      msg = '%.0f Kb' % size
    return msg


  def get_default_partition_selection(self, size):
    """return a dictionary with a skeleton { mountpoint : device }
    as a default partition selection. The first partition with max size
    and ext3 fs will be root, the second partition with max size and ext3
    fs will be selected as /home, and the first partition it finds as swap
    will be marked as the swap selection."""

    # ordering a list from size dict ( { device : size } ), from higher to lower
    size_ordered, selection = [], {}
    for value in size.values():
      if not size_ordered.count(value):
        size_ordered.append(value)
    size_ordered.sort()
    size_ordered.reverse()

    # getting filesystem dict ( { device : fs } )
    device_list = get_filesystems()

    # building an initial mountpoint preselection dict. Assigning only preferred
    #   partitions for each mountpoint (highest ext3 partition to '/', the
    #   second highest ext3 partition to '/home' and the first swap partition to
    #   swap).
    if ( len(device_list.items()) != 0 ):
      root, swap, home = 0, 0, 0
      for size_selected in size_ordered:
        partition = size.keys()[size.values().index(size_selected)]
        try:
          fs = device_list['/dev/%s' % partition]
        except:
          continue
        if ( swap == 1 and root == 1 and home == 1 ):
          break
        elif ( fs == 'ext3' and size_selected > 1024):
          if ( root == 1 and home == 0 ):
            selection['/home'] = '/dev/%s' % partition
            home = 1
          elif ( root == 0 ):
            selection['/'] = '/dev/%s' % partition
            root = 1
        elif ( fs == 'swap' ):
          selection['swap'] = '/dev/%s' % partition
          swap = 1
        else:
          continue
    return selection


  def show_partitions(self, widget):
    """write all values in this widget (GtkComboBox) from local
    partitions values."""

    from ue import misc
    import gobject

    # setting GtkComboBox partition values from get_partition return.
    self.partitions = []
    partition_list = get_partitions()
    treelist = gtk.ListStore(gobject.TYPE_STRING)

    # the first element is empty to allow deselect a preselected device
    treelist.append([' '])
    for index in partition_list:
      index = '/dev/' + index
      self.part_labels[index] = misc.part_label(index)
      treelist.append([self.part_labels[index]])
      self.partitions.append(index)
    widget.set_model(treelist)


  def progress_loop(self):
    """prepare, format, copy and config the system in the
    core install process."""

    pre_log('info', 'progress_loop()')

    self.next.set_sensitive(False)

    # saving UI input data to vars file
    self.set_vars_file()

    # first image iteration
    self.images_loop()
    # Setting Normal cursor
    #self.live_installer.window.set_cursor(None)

    path = '/usr/lib/python2.4/site-packages/ue/backend/'

    def wait_thread(queue):
      """wait thread for format process."""

      mountpoints = get_var()['mountpoints']
      ft = format.Format(mountpoints)
      ft.format_target(queue)
      queue.put('101')

    # Starting format process
    queue = Queue()
    thread.start_new_thread(wait_thread, (queue,))

    # setting progress bar status while format process is running
    while True:
      msg = str (queue.get ())
      # format process is ended when '101' is pushed
      if msg.startswith('101'):
        break
      self.set_progress(msg)
      # refreshing UI
      while gtk.events_pending():
        gtk.main_iteration()
      time.sleep(0.5)

    def wait_thread(queue):
      """wait thread for copy process."""

      mountpoints = get_var()['mountpoints']
      cp = copy.Copy(mountpoints)
      cp.run(queue)
      queue.put('101')

    # Starting copy process
    queue = Queue()
    thread.start_new_thread(wait_thread, (queue,))

    # setting progress bar status while copy process is running
    while True:
      msg = str(queue.get())
      # copy process is ended when '101' is pushed
      if msg.startswith('101'):
        break
      self.set_progress(msg)
      # refreshing UI
      while gtk.events_pending():
        gtk.main_iteration()

    def wait_thread(queue):
      """wait thread for config process."""

      vars = get_var()
      cf = config.Config(vars)
      cf.run(queue)
      queue.put('101')

    # Starting config process
    queue = Queue()
    thread.start_new_thread(wait_thread, (queue,))

    # setting progress bar status while config process is running
    while True:
      msg = str(queue.get())
      # config process is ended when '101' is pushed
      if msg.startswith('101'):
        break
      self.set_progress(msg)
      # refreshing UI
      while gtk.events_pending():
        gtk.main_iteration()

    # umounting self.mountpoints (mounpoints user selection)
    umount = copy.Copy(self.mountpoints)
    umount.umount_target()

    # setting new button labels and status from bottom bar
    self.next.set_label(_("Reboot"))
    self.next.connect('clicked', self.__reboot)
    #self.back.set_label(_("Salir"))
    self.back.set_use_stock(True) 
    self.back.set_label("gtk-quit") 
    self.back.connect('clicked', gtk.main_quit)
    self.next.set_sensitive(True)
    self.back.show()
    self.cancel.hide()
    self.steps.next_page()


  def __reboot(self, *args):
    """reboot the system after installing process."""

    os.system("reboot")
    self.quit()


  def set_progress(self, msg):
    """set values on progress bar widget."""

    num , text = get_progress(msg)
    if ( num % (100/len(self.total_images)) < self.remainder ):
      self.images_loop()
    self.remainder = num % (100/len(self.total_images))
    self.progressbar.set_fraction (num / 100.0)
    self.progressbar.set_text(text)


  def set_vars_file(self):
    """writing vars crypted file to get theses vars accessible from
    Format, Copy and Config classes."""

    from ue import misc
    vars = {}
    attribs = ['hostname','fullname','username','password']
    try:
      for name in attribs:
        var = getattr(self, name)
        vars[name] = var.get_text()
      vars['mountpoints'] = self.mountpoints
    except:
      pre_log('error', 'Missed attrib to write to /tmp/vars')
      self.quit()
    else:
      misc.set_var(vars)


  #def show_error(self, msg):
  def show_error(self): 
    """show warning message on Identification screen where validation
    doesn't work properly."""

    #self.warning_info.set_markup(msg)
    #self.help.show()
    self.error_box.show()


  def quit(self):
    """quit installer cleanly."""

    # Tell the user how much time they used
    pre_log('info', 'You wasted %.2f seconds with this installation' %
                      (time.time()-self.start))
    # exiting from application
    gtk.main_quit()


  # Callbacks
  def on_cancel_clicked(self, widget):
    self.warning_dialog.show()


  def on_cancelbutton_clicked(self, widget):
    self.warning_dialog.hide()


  def on_exitbutton_clicked(self, widget):
    self.quit()


  def on_warning_dialog_close(self, widget):
    self.warning_dialog.hide()


  def on_list_changed(self, widget):
    """check if partition/mountpoint par is filled and show the next par
    on mountpoint screen. Also size label associated to partition combobox
    is changed dinamically to shows the size partition."""

    list_partitions, list_mountpoints, list_sizes, list_partitions_labels, list_mountpoints_labels, list_sizes_labels = [], [], [], [], [], []

    # building widget and name_widget lists to query and modify the original widget status
    for widget_it in self.glade.get_widget('vbox_partitions').get_children()[1:]:
      list_partitions.append(widget_it)
      list_partitions_labels.append(widget_it.get_name())
    for widget_it in self.glade.get_widget('vbox_mountpoints').get_children()[1:]:
      list_mountpoints.append(widget_it)
      list_mountpoints_labels.append(widget_it.get_name())
    for widget_it in self.glade.get_widget('vbox_sizes').get_children()[1:]:
      list_sizes.append(widget_it)
      list_sizes_labels.append(widget_it.get_name())

    # showing new partition and mountpoint widgets if they are needed. Assigning
    #   a new value to gtklabel size.
    if ( widget.get_active_text() not in ['', None] ):
      if ( widget.__class__ == gtk.ComboBox ):
        index = list_partitions_labels.index(widget.get_name())
      elif ( widget.__class__ == gtk.ComboBoxEntry ):
        index = list_mountpoints_labels.index(widget.get_name())

      if ( list_partitions[index].get_active_text() != None and
           list_mountpoints[index].get_active_text() != "" and
           len(get_partitions()) >= index+1 ):
        list_partitions[index+1].show()
        list_mountpoints[index+1].show()
        list_sizes[index+1].show()
      if ( list_partitions[index].get_active_text() == ' ' ):
        list_sizes[index].set_text('')
      elif ( list_partitions[index].get_active_text() != None ):
        list_sizes[index].set_text(self.set_size_msg(list_partitions[index]))


  def on_key_press (self, widget, event):
    """capture return key on live installer to go to next
    screen only if Next button has the focus."""

    # mapping enter key to get more usability
    if ( event.keyval == gtk.gdk.keyval_from_name('Return') ) :
      if ( not self.help.get_property('has-focus')
        and not self.back.get_property('has-focus')
        and not self.cancel.get_property('has-focus') ):
        self.next.clicked()


  def info_loop(self, widget):
    """check if all entries from Identification screen are filled. Callback
    defined in glade file."""

    # each entry is saved as 1 when it's filled and as 0 when it's empty. This
    #   callback is launched when these widgets are modified.
    counter = 0
    if ( widget.get_text() is not '' ):
      self.entries[widget.get_name()] = 1
    else:
      self.entries[widget.get_name()] = 0

    # Counting how many entries are filled.
    for k, v in self.entries.items():
      if ( v == 1 ):
        counter+=1
    if (counter == 5 ):
      self.next.set_sensitive(True)

  def read_stdout(self, source, condition):
    """read msgs from queues to set progress on progress bar label.
    '101' message finishes this process returning False."""

    msg = source.readline()
    if msg.startswith('101'):
      print "read_stdout finished"
      return False
    self.set_progress(msg)
    return True
    color=gtk.gdk.color_parse('#234fdb')
    self.hbox33.modify_bg(gtk.STATE_NORMAL, color)
    self.hbox33.show()


  def images_loop(self):
    """looping images and text on installing screen about the install process."""

    self.install_image+=1
    step = self.install_image % len(self.total_images) -1
    self.installing_image.set_from_file(self.total_images[step])
    self.installing_text.set_markup(self.resize_text(self.total_messages[step], '4'))
    return True


  def on_help_clicked(self, widget):
    """show help message when help button is clicked."""

    if  self.steps.get_current_page() == 0:
     # text = _("<span>Es necesario que introduzca su <b>nombre de usuario</b> para el sistema, su <b>nombre completo</b> para generar una ficha de usuario, así como el <b>nombre de máquina</b> con el que quiera bautizar su equipo. Deberá teclear la contraseña de usuario en dos ocasiones.</span>")
      #self.warning_info.set_markup(self.resize_text(text, '4'))
      
      #print self.steps.get_current_page()
      self.help.hide()
      self.next.hide()
      self.cancel.hide()
      self.vbox41.hide()
      self.browser_vbox.show()
      self.back.show()




  def on_next_clicked(self, widget):
    """Callback to control the installation process between steps."""
    
    #widget.set_cursor(self.watch)
    # setting actual step
    step = self.steps.get_current_page()
    pre_log('info', 'Step_before = %d' % step)
    self.live_installer.window.set_cursor(self.watch)
    # From Welcome to Info
    if step == 0:
      self.help.hide()
      self.back.show()
      self.next.set_label('gtk-go-forward')
      self.next.set_sensitive(False)
      self.steps.next_page()
      #self.live_installer.window.set_cursor(None)
    # From Info to Peez
    elif step == 1: 
      self.info_to_peez()
    # From Peez to {Gparted, Progress}
    elif step == 2:
      self.peez2()
    # From Gparted to Mountpoints
    elif step == 3:
      self.gparted_to_mountpoints()
    # From Mountpoints to Progress
    elif step == 4:
      self.mountpoints_to_progress()
    
    step = self.steps.get_current_page()
    pre_log('info', 'Step_after = %d' % step)
    self.live_installer.window.set_cursor(None)

  def info_to_peez (self):
    """Processing info to peez step tasks."""
    from ue import validation
    #error_msg = ['\n']
    error = 0

    # Validation stuff

    # checking username entry
    for result in validation.check_username(self.username.get_property('text')):
      if ( result == 1 ):
        #error_msg.append(_("· El <b>nombre de usuario</b> contiene carácteres incorrectos (sólo letras y números están permitidos).\n"))
        self.user_err_1.show()
        error = 1
      elif ( result == 2 ):
        #error_msg.append(_("· El <b>nombre de usuario</b> contiene mayúsculas (no están permitidas).\n"))
        self.user_err_2.show() 
        error = 1
      elif ( result == 3 ):
        #error_msg.append(_("· El <b>nombre de usuario</b> tiene tamaño incorrecto (permitido entre 3 y 24 caracteres).\n"))
        self.user_err_3.show()
        error = 1
      elif ( result == 4 ):
        #error_msg.append(_("· El <b>nombre de usuario</b> contiene espacios en blanco (no están permitidos).\n"))
        self.user_err_4.show()
        error = 1
      elif ( result in [5, 6] ):
        #error_msg.append(_("· El <b>nombre de usuario</b> ya está en uso o está prohibido.\n"))
        self.user_err_5.show()
        error = 1
    # checking password entry
    for result in validation.check_password(self.password.get_property('text'), self.verified_password.get_property('text')):
      if ( result in [1,2] ):
        #error_msg.append(_("· La <b>contraseña</b> tiene tamaño incorrecto (permitido entre 4 y 16 caracteres).\n"))
        self.passwd_err_1.show()
        error = 1
      elif ( result == 3 ):
        #error_msg.append(_("· Las <b>contraseñas</b> no coinciden.\n"))
        self.passwd_err_2.show()    
        error = 1
    # checking hostname entry
    for result in validation.check_hostname(self.hostname.get_property('text')):
      if ( result == 1 ):
        #error_msg.append(_("· El <b>nombre del equipo</b> tiene tamaño incorrecto (permitido entre 3 y 18 caracteres).\n"))
        self.host_err_1.show()
        error = 1
      elif ( result == 2 ):
        #error_msg.append(_("· El <b>nombre del equipo</b> contiene espacios en blanco (no están permitidos).\n"))
        self.host_err_2.show() 
        error = 1
      elif ( result == 3 ):
        #error_msg.append(_("· El <b>nombre del equipo</b> contiene carácteres incorrectos (sólo letras y números están permitidos).\n"))
        self.host_err_3.show()
        error = 1

    # showing warning message is error is set
    #if ( len(error_msg) > 1 ):
    #  self.show_error(self.resize_text(''.join(error_msg), '4'))
    if error != 0 :
        self.show_error()
    else:
      # showing next step and destroying mozembed widget to release memory
      self.browser_vbox.destroy()
      self.back.show()
      self.help.hide()
      self.steps.next_page()
      #self.live_installer.window.set_cursor(None) 
      # To disable peez2 utility, you must comment the line above
      # this one and uncoment the three below lines.
      # if self.gparted:
      #   self.gparted_loop()
      # self.steps.set_current_page(3)


  def peez2(self):
    """Processing peez to {gparted, progress} step tasks."""

    while gtk.events_pending ():
      gtk.main_iteration ()

    self.freespace.set_active (False)
    self.recycle.set_active (False)
    self.manually.set_active (False)
    model = self.drives.get_model ()

    if len (model) > 0:
      current = self.drives.get_active ()

      if -1 != current:
        selected_drive = self.__assistant.get_drives () [current]

    if self.freespace.get_active ():
      self.partition_bar.show ()

      if -1 != current:
        progress = Queue ()
        thread.start_new_thread (launch_autoparted, (self, self.__assistant, selected_drive, progress))
        msg = str (progress.get ())

        while msg is not '':
          field = msg.split ('|')
          self.partition_bar.set_fraction (float (field [0]))
          self.partition_bar.set_text (str (field [1]))
          msg = str (progress.get ())

          while gtk.events_pending ():
            gtk.main_iteration ()

          time.sleep (0.5)

        self.mountpoints = progress.get ()
        self.partition_bar.set_text ('')

        if self.mountpoints is 'STOPPED':
          self.mountpoints = None
          self.partition_bar.set_fraction (0.0)
          self.discard_automatic_partitioning = True
          self.freespace.set_sensitive (False)
          self.on_drives_changed (None)
          self.abort_dialog.show ()
#          self.steps.set_current_page(2)
        else:
          self.partition_bar.set_fraction (1.0)
          self.steps.set_current_page(5)

          while gtk.events_pending():
            gtk.main_iteration()

          self.back.hide()
          self.progress_loop()

    elif self.recycle.get_active ():

      if -1 != current:
        self.mountpoints = selected_drive ['linux_before']
        stderr.write ('\n\n' + str (self.mountpoints) + '\n\n')
        self.steps.set_current_page(5)

        while gtk.events_pending():
          gtk.main_iteration()

        self.back.hide()
        self.progress_loop()
    else:

      if self.gparted:
        self.gparted_loop()
      self.steps.next_page()


  def gparted_to_mountpoints(self):
    """Processing gparted to mountpoints step tasks."""

    # Setting items into partition Comboboxes
    for widget in self.glade.get_widget('vbox_partitions').get_children()[1:]:
      self.show_partitions(widget)
    self.size = self.get_sizes()

    # building mountpoints preselection
    self.default_partition_selection = self.get_default_partition_selection(self.size)

    # Setting a default partition preselection
    if len(self.default_partition_selection.items()) == 0:
      self.next.set_sensitive(False)
    else:
      count = 0
      mp = { 'swap' : 0, '/' : 1, '/home' : 2 }

      # Setting default preselection values into ComboBox widgets and setting
      #   size values. In addition, next row is showed if they're validated.
      for j, k in self.default_partition_selection.items():
        if ( count == 0 ):
          self.partition1.set_active(self.partitions.index(k)+1)
          self.mountpoint1.set_active(mp[j])
          self.size1.set_text(self.set_size_msg(k))
          if ( len(get_partitions()) > 1 ):
            self.partition2.show()
            self.mountpoint2.show()
          count += 1
        elif ( count == 1 ):
          self.partition2.set_active(self.partitions.index(k)+1)
          self.mountpoint2.set_active(mp[j])
          self.size2.set_text(self.set_size_msg(k))
          if ( len(get_partitions()) > 2 ):
            self.partition3.show()
            self.mountpoint3.show()
          count += 1
        elif ( count == 2 ):
          self.partition3.set_active(self.partitions.index(k)+1)
          self.mountpoint3.set_active(mp[j])
          self.size3.set_text(self.set_size_msg(k))
          if ( len(get_partitions()) > 3 ):
            self.partition4.show()
            self.mountpoint4.show()

    self.steps.next_page()


  def mountpoints_to_progress(self):
    """Processing mountpoints to progress step tasks."""

    # Validating self.mountpoints
    error_msg = ['\n']

    # creating self.mountpoints list only if the pairs { device : mountpoint } are
    #   selected.
    list = []
    list_partitions = []
    list_mountpoints = []

    # building widget lists to build dev_mnt dict ( { device : mountpoint } )
    for widget in self.glade.get_widget('vbox_partitions').get_children()[1:]:
      if widget.get_active_text() not in [None, ' ']:
        list_partitions.append(widget)
    for widget in self.glade.get_widget('vbox_mountpoints').get_children()[1:]:
      if widget.get_active_text() != "":
        list_mountpoints.append(widget)
    # Only if partitions cout or mountpoints count selected are the same,
    #   dev_mnt is built.
    if ( len(list_partitions) == len(list_mountpoints) ):
      dev_mnt = dict( [ (list_partitions[i], list_mountpoints[i]) for i in range(0,len(list_partitions)) ] )

      for dev, mnt in dev_mnt.items():
        if ( dev.get_active_text() != None and mnt.get_active_text() != "" ):
          self.mountpoints[self.part_labels.keys()[self.part_labels.values().index(dev.get_active_text())]] = mnt.get_active_text()

    # Processing validation stuff
    elif ( len(list_partitions) > len(list_mountpoints) ):
      error_msg.append(_("· Punto de montaje vacío.\n\n"))
    elif ( len(list_partitions) < len(list_mountpoints) ):
      error_msg.append(_("· Partición sin seleccionar.\n\n"))

    # Checking duplicated devices
    for widget in self.glade.get_widget('vbox_partitions').get_children()[1:]:
      if ( widget.get_active_text() != None ):
        list.append(widget.get_active_text())

    for check in list:
      if ( list.count(check) > 1 ):
        error_msg.append(_("· Dispositivos duplicados.\n\n"))
        break

    # Processing more validation stuff
    if ( len(self.mountpoints) > 0 ):
      for check in check_mountpoint(self.mountpoints, self.size):
        if ( check == 1 ):
          error_msg.append(_("· No se encuentra punto de montaje '/'.\n\n"))
        elif ( check == 2 ):
          error_msg.append(_("· Puntos de montaje duplicados.\n\n"))
        elif ( check == 3 ):
          try:
            swap = self.mountpoints.values().index('swap')
            error_msg.append(_("· Tamaño insuficiente para la partición '/' (Tamaño mínimo: %d Mb).\n\) " )% MINIMAL_PARTITION_SCHEME['root'])
          except:
            error_msg.append(_("· Tamaño insuficiente para la partición '/' (Tamaño mínimo: %d Mb).\n\n) " ) % (MINIMAL_PARTITION_SCHEME['root'] + MINIMAL_PARTITION_SCHEME['swap']*1024))
        elif ( check == 4 ):
          error_msg.append(_("· Carácteres incorrectos para el punto de montaje.\n\n"))

    # showing warning messages
    if ( len(error_msg) > 1 ):
      self.msg_error2.set_text(self.resize_text(''.join(error_msg), '4'))
      self.msg_error2.show()
      self.img_error2.show()
    else:
      self.back.hide()
      self.steps.next_page()
      # setting busy mouse cursor
      #self.live_installer.window.set_cursor(self.watch)

      # refreshing UI
      while gtk.events_pending():
        gtk.main_iteration()

      # Destroy gparted tree widgets
      self.embedded.destroy()
      self.next.set_sensitive(False)

      # killing gparted to release mem
      try:
        os.kill(self.gparted_pid, 9)
      except Exception, e:
        print e

      # Starting installation core process
      self.progress_loop()


  def on_back_clicked(self, widget):
    """Callback to set previous screen."""

    # Enabling next button
    self.next.set_sensitive(True)
    # Setting actual step
    step = self.steps.get_current_page()
    if step == 0:
      self.browser_vbox.hide()
      self.back.hide()
      self.back.hide()
      self.help.show()
      self.next.show()
      self.cancel.show()
      self.vbox41.show()

    if step == 1:
      self.back.hide()
      self.help.show()
    if step == 2:
      self.back.hide()

    if step is not 6:
      self.steps.prev_page()

  # Public method "on_drives_changed" ________________________________________
  def on_drives_changed (self, foo):

    """ When a different drive is selected, it is necessary to update the
        chekboxes to reflect the set of permited operations on the new
        drive. """

    model = self.drives.get_model ()

    if len (model) > 0:
      current = self.drives.get_active ()

      if -1 != current:
        selected_drive = self.__assistant.get_drives () [current]

        if not selected_drive ['large_enough']:
          self.freespace.set_sensitive (False)
          self.recycle.set_sensitive (False)
          self.manually.set_sensitive (False)
          self.partition_message.set_markup (self.resize_text(_("<span>La unidad que ha seleccionado es <b>demasiado pequeña</b> para instalar el sistema en él.\n\nPor favor seleccione un disco duro de más capacidad.</span>"), '4'))
        else:
          self.manually.set_sensitive (True)

          if not self.__assistant.only_manually ():

            if not self.discard_automatic_partitioning:

##               if selected_drive.has_key (''):

              self.freespace.set_sensitive (True)

            if selected_drive.has_key ('linux_before'):

              if selected_drive ['linux_before'] is not None:
                self.recycle.set_sensitive (True)

        # All options are disabled:
        self.freespace.set_active (False)
        self.recycle.set_active (False)
        self.manually.set_active (False)

        # "Next" button is sensitive:
        self.next.set_sensitive (True)

        # Only the first possible option (if any) is enabled:
        if self.freespace.get_property ('sensitive'):
          self.freespace.set_active (True)
        elif self.recycle.get_property ('sensitive'):
          self.recycle.set_active (True)
        elif self.manually.get_property ('sensitive'):
          self.manually.set_active (True)
        else:
          # If no option is possible, "Next" button should not be sensitive:
          self.next.set_sensitive (False)

        # Next lines for debugging purposes only:
##         message = str (selected_drive ['info'])
##         self.partition_message.set_text (message)

    if selected_drive ['large_enough']:
      self.on_freespace_toggled (self.freespace)
      self.on_recycle_toggled (self.recycle)
      self.on_manually_toggled (self.manually)


  # Public method "on_steps_switch_page" _____________________________________
  def on_steps_switch_page (self, foo, bar, current):

    """ Only to populate the drives combo box the first time that page #2 is
        shown. """

    if 2 == current and None == self.__assistant:

      # To set a "busy mouse":
      #self.live_installer.window.set_cursor (self.watch)

##       while gtk.events_pending ():
##         gtk.main_iteration ()

      self.__assistant = Peez2 () # debug = False)

      # To set a normal mouse again:
      #self.live_installer.window.set_cursor (None)

      for i in self.__assistant.get_drives ():
        self.drives.append_text ('%s' % i ['label'])

      model = self.drives.get_model ()

      if len (model) > 0:
        self.drives.set_active (0)


  # Public method "on_freespace_toggled" _____________________________________
  def on_freespace_toggled (self, widget):

    """ Update help message when this radio button is selected. """
    

    if self.freespace.get_active ():
      self.confirmation_table.show ()
      self.partition_message_recycle.hide() 
      self.partition_message_manually.hide()
      self.partition_message.hide()
      self.partion_message_part.hide()
      self.confirmation_checkbutton.set_active (False)
      self.next.set_sensitive (False)
      self.partition_message_freespace.show()
     # self.partition_message.set_markup (self.resize_text(_("<span><b>Este método de particionado es EXPERIMENTAL.</b>\n\n Se crearán 3 particiones <b>nuevas</b> en su disco duro y se instalará ahí el sistema. En la mayoría de los casos, los datos que haya ya en el disco duro no se destruirán.\n\nNota: en algunos casos, <b>es posible que se produzca una pérdida de datos</b> si es necesario cambiar el tamaño de las particiones existentes para conseguir espacio para las nuevas.</span>"), '4'))
       

  # Public method "on_recycle_toggled" _______________________________________
  def on_recycle_toggled (self, widget):

    """ Update help message when this radio button is selected. """
    
    if self.recycle.get_active ():
     
      self.confirmation_table.show ()
      self.partition_message_freespace.hide()
      self.partition_message_manually.hide()
      self.partition_message.hide()
      self.partion_message_part.hide()
      self.partition_message_recycle.show()
      self.confirmation_checkbutton.set_active (False)
      self.next.set_sensitive (False)
      model = self.drives.get_model ()
        
      if len (model) > 0:
        current = self.drives.get_active ()

        if -1 != current:
          selected_drive = self.__assistant.get_drives () [current]
          associations = selected_drive ['linux_before']
          where = _('<span foreground="#800000"><b>\n')

          for i in associations.keys ():

            if i in self.part_labels:
              where = where + '\n· ' + self.part_labels [i] +\
                      '  <tt>' + associations [i] + '</tt>'
            else:
              where = where + '\n<tt>' + i + '</tt>  <tt>' + \
                      associations [i] + '</tt>'

          where = where + '</b></span>'
      else:
        where = ''
        
    
      
      #
      self.partition_message.set_markup(self.resize_text(_(" %s " ) % where, '4'))
      self.partion_message_part.show()
      self.partition_message.show()


  # Public method "on_manually_toggled" ______________________________________
  def on_manually_toggled (self, widget):

    """ Update help message when this radio button is selected. """

    if self.manually.get_active ():
      self.confirmation_table.hide ()
      self.partition_message_recycle.hide()
      self.partition_message_freespace.hide()
      self.partition_message.hide()
      self.partion_message_part.hide()
      self.confirmation_checkbutton.set_active (False)
      self.next.set_sensitive (True)
      self.partition_message_manually.show()
      #self.partition_message.set_markup (self.resize_text(_("<span>Use este método de particionado si desea total libertad para decidir dónde instalar cada componente del sistema. Podrá crear, destruir y redimensionar cualquier partición para que cada parte ocupe el espacio que quiera.\n\n<b>Atención:</b> las operaciones que haga con el disco duro pueden suponer la <b>pérdida de todos los datos</b>, así que continúe por aquí únicamente si ya tiene experiencia particionando de forma manual.</span>"), '4'))


  # Public method "on_confirmation_checkbutton_toggled" ______________________
  def on_confirmation_checkbutton_toggled (self, widget):

    """ Change "active" property of "next" button when this check box is
        changed. """

    if self.confirmation_checkbutton.get_active ():
      self.next.set_sensitive (True)
    else:
      self.next.set_sensitive (False)

##   # Public method "on_abort_dialog_close" ____________________________________
##   def on_abort_dialog_close (self, widget):

##     """ Disable automatic partitioning and reset partitioning method step. """

##     stderr.write ('\non_abort_dialog_close.\n\n')

##     self.discard_automatic_partitioning = True
##     self.on_drives_changed (None)

  # Public method "on_abort_ok_button_clicked" _______________________________
  def on_abort_ok_button_clicked (self, widget):

    """ Close this dialog. """

    self.abort_dialog.hide ()

# Function "launch_autoparted" _______________________________________________
def launch_autoparted (wizard, assistant, drive, progress):

  """ Start auto-partitioning process in a separate thread. """

  result = None

  # To set a "busy mouse":
  #wizard.live_installer.window.set_cursor (wizard.watch)

  result = part.call_autoparted (assistant, drive, progress)
  progress.put ('')
  progress.put (result)

  # To set normal mouse again:
  #wizard.live_installer.window.set_cursor (None)

if __name__ == '__main__':
  w = Wizard('dsslive')
  w.run()

