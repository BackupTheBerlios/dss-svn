#!/usr/bin/env python

from distutils.core import setup
import glob
import os
import re

# look/set what version we have
changelog = "debian/changelog"
if os.path.exists(changelog):
    head=open(changelog).readline()
    match = re.compile(".*\((.*)\).*").match(head)
    if match:
        version = match.group(1)
        f=open("Nomed/utils/version.py","w")
        f.write("VERSION=\"%s\"\n" % version)
        f.close()



    
setup(name='nomed',
        author='Daniele Favara',
        author_email='danjele@gmail.com',
        url='http://dsslive.org',
        download_url='svn://svn.berlios.de/dss/dss-main/nomed',
        description=('daemon to auto-mount and manage media devices with notifications '),
        version=version,
        packages=['Nomed','Nomed/utils'],
        scripts=['nomed-launch'],
        data_files=[('share/nomed/',
                   ["examples/lshal.py",
                   "examples/notify.py",
                   "examples/mountpoint.py",
                   "sounds/arrive.wav",
                   "sounds/leave.wav"]),
                  ('../etc/nomed',
                   ["xml/config.xml","xml/voice.xml","xml/rules.xml"])]
                  )
