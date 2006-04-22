#include <errno.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char *argv[])
{
	struct stat before, after;

	if (argc != 2) {
		fprintf(stderr, "%s filename\n", argv[0]);
		exit(1);
	}

	if (stat(argv[1], &before))
		perror("First Stat");
	if (rmdir(argv[1]))
		if (errno != ENOTEMPTY)
			perror("rmdir");
	if (stat(argv[1], &after))
		perror("Second stat");
	if (before.st_ino != after.st_ino)
		exit(1);
	exit(0);
}
