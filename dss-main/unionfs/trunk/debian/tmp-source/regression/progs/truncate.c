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
