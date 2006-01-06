#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/fcntl.h>

int main(int argc, char *argv[]) {
	int fd;
	struct flock lock;

	if (argc != 2) {
		fprintf(stderr, "%s file\n", argv[0]);
		exit(1);
	}

	fd = open(argv[1], O_RDWR);
	if (fd == -1) {
		perror("open");
		exit(1);
	}

	lock.l_type = F_WRLCK;
	lock.l_whence = SEEK_SET;
	lock.l_start = 0;
	lock.l_len = 0;

	if (fcntl(fd, F_SETLK, &lock) == -1) {
		perror("fcntl");
		exit(1);
	}

	exit(0);
}
