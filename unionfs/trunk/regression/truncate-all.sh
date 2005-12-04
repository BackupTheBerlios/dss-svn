#!/bin/sh

# TEST: Branches b0,b1 and b0,b1=ro
# TEST: truncate(F)
# TEST:  F on b1 to zero
# TEST:  F on b1 to a non-zero size less than the original
# TEST:  F on b1 to a larger size than the original
# TEST:  F on b0 and b1 to zero
# TEST: WHERE x = 0, 0 < x < size(f), and size(f) < x
# TEST: Using the following branch configurations
# TEST: Branches b0,b1 and b0,b1=ro
# TEST:  F on b0
# TEST:  F on b1
# TEST:  F on b2
# TEST:  F on b0,b1
# TEST: Branches b0,b1,b2
# TEST:  F on b0,b1,b2
# TEST:  F on b0,b1(immutable),b2
# TEST: Branches b0,b1=ro,b2
# TEST:  F on b0,b1,b2

cat <<TRUNCATE_C > truncate.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>


void usage(const char *argv) {
	fprintf(stderr, "%s -f file size\n", argv);
	exit(1);
}

int main(int argc, char *argv[]) {
	off_t size;
	char *end;

	if (argc < 3 || argc > 4) {
		usage(argv[0]);
	}
	if (argc == 4) {
		int fd;
		if (strcmp(argv[1], "-f")) {
			usage(argv[0]);
			fprintf(stderr, "%s -f file size\n", argv[0]);
			exit(1);
		}
		fd = open(argv[2], O_RDWR);
		if (fd == -1) {
			perror("open");
			exit(1);
		}
		size = strtoul(argv[3], &end, 0);
		if (*end) {
			usage(argv[0]);
		}
		
		if (ftruncate(fd, size) == -1) {
			perror("ftruncate");
			exit(1);
		}
		close(fd);
	} else {
		size = strtoul(argv[2], &end, 0);
		if (*end) {
			usage(argv[0]);
		}
		if (truncate(argv[1], size) == -1) {
			perror("truncate");
			exit(1);
		}
	}
	exit(0);
}
TRUNCATE_C
gcc -g -o ./truncate ./truncate.c

source scaffold

# initial directories
function directories {
cat <<FILES
d /n/lower
d /n/lower/b0
d /n/lower/b1
d /n/lower/b2
d /n/lower/b2/d1
d /n/lower/b2/d1/d2
d /n/lower/b2/d1/d2/d3
d /n/lower/b2/d1/d2/d3/d4
FILES
}


(directories) | create_hierarchy

dd if=/dev/zero of=/n/lower/b0/a bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=/n/lower/b0/b bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=/n/lower/b0/c bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=/n/lower/b0/d bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=/n/lower/b1/d bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=/n/lower/b2/d bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=/n/lower/b2/d1/d2/d3/d4/e bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=/n/lower/b2/d1/d2/d3/d4/f bs=4000 count=2 2>/dev/null
chattr +i /n/lower/b2/d1/d2/d3/d4/f

# mount unionfs
mount_union "setattr=all" /n/lower/b0 /n/lower/b1 /n/lower/b2

./truncate -f $MOUNTPOINT/a 0

./truncate -f $MOUNTPOINT/b 5000

./truncate -f $MOUNTPOINT/c 10000

./truncate -f $MOUNTPOINT/d 10000

./truncate -f $MOUNTPOINT/d1/d2/d3/d4/e 10000

shouldfail ./truncate -f $MOUNTPOINT/d1/d2/d3/d4/f 10000

unmount_union







#### do same tests with mix of ro branches

(directories) | create_hierarchy

dd if=/dev/zero of=/n/lower/b0/a bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=/n/lower/b0/b bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=/n/lower/b0/c bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=/n/lower/b0/d bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=/n/lower/b1/d bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=/n/lower/b2/d bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=/n/lower/b2/d1/d2/d3/d4/e bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=/n/lower/b2/d1/d2/d3/d4/f bs=4000 count=2 2>/dev/null
chattr +i /n/lower/b2/d1/d2/d3/d4/f





mount_union "setattr=all" /n/lower/b0 /n/lower/b1=ro /n/lower/b2=ro

./truncate -f $MOUNTPOINT/a 0

./truncate -f $MOUNTPOINT/b 5000

./truncate -f $MOUNTPOINT/c 10000

./truncate -f $MOUNTPOINT/d 10000

./truncate -f $MOUNTPOINT/d1/d2/d3/d4/e 10000

shouldfail ./truncate -f $MOUNTPOINT/d1/d2/d3/d4/f 10000

unmount_union


rm -f ./truncate ./truncate.c

echo "OK"
exit 0
