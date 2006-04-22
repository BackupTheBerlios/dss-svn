#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/fcntl.h>

int main(int argc, char *argv[]) {
	const char *s = "I am the very model of a modern major general.\n";
	int fd;

	if (argc != 2) {
		fprintf(stderr, "%s file\n", argv[0]);
		exit(1);
	}

	fd = open(argv[1], O_RDWR);
	if (fd == -1) {
		perror("open");
		exit(1);
	}

	if (write(fd, s, strlen(s)) != strlen(s)) {
		perror("write");
		exit(1);
	}

	if (fsync(fd) != 0) {
		perror("fsync");
		exit(1);
	}

	exit(0);
}
