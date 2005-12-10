#!/usr/bin/python
# -*- coding: utf8 -*-
import sys, time

class MountPoint:
    def __init__(self):
        if len(sys.argv) != 2:
            sys.stderr.write("usage: %s [device]\n" % sys.argv[0])
            sys.exit(1)

        end = time.time() + 10

        while time.time() < end:
            mounts = open("/proc/mounts").read()
            mounts = map(lambda m: m.split(" "), mounts.splitlines())
            mounts = filter(lambda m: m[0] == sys.argv[1], mounts)

            if len(mounts) > 0:
                break

            time.sleep(0.1) 

        if len(mounts) > 0:
            print mounts[0][1]
            self=mounts[0][1]
        else:
            sys.stderr.write("%s: %s not mounted after 10 seconds.\n" % \
                    (sys.argv[0], sys.argv[1]))
            sys.exit(1)
def main():
    mounts = MountPoint()
if __name__ == "__main__":
    main()

