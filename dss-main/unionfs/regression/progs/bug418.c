#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char *argv[])
{
        int fd;
        char string[] = "XXXXXXXXXXXXXXX";

	if (argc != 2) {
		fprintf(stderr, "%s filename\n", argv[0]);
		exit(1);
	}

        fd = open(argv[1], O_RDWR);
        if (fd < 0) {
                perror("open");
                exit(1);
        }

        sleep(7);

        if (write(fd, string, strlen(string)) != strlen(string)) {
		perror("write");
		exit(1);
	}

	exit(0);
}
