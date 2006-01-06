/* This is a testcase for BUG 299. */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/fcntl.h>
#include <sys/stat.h>
#include <assert.h>
#include <errno.h>
#include <string.h>

#define ERROR(cond, s) if (cond) { \
	fprintf(stderr, "%s:%d: %s: %s\n", __FILE__, __LINE__, s, strerror(errno)); \
	assert(0); \
	exit(1); \
}

int main(int argc, char *argv[]) {
	int fd, fd2;
	int ret;
	char *filename;
	char bufsize;
	char *buf;
	char *buf2;
	struct stat st;
	char *judygarland = "Somewhere over the rainbow way up high, there's a land that I heard of Once in a lullaby.";
	char *judygarland2 = "Somewhere over the rainbow skies are blue, and the dreams that you dare to dream really do come true.";
	int l;

	if (argc != 2) {
		fprintf(stderr, "%s file\n", argv[0]);
		exit(1);
	}

	filename = argv[1];

	fd = open(filename, O_RDWR);
	ERROR(fd == -1, "open");
	ERROR(fstat(fd, &st) == -1, "fstat");
	ERROR(st.st_size <= 0, "Original file too small");
	bufsize = st.st_size;
	ERROR((buf = malloc(bufsize + 1)) == NULL, "malloc(buf)");
	ERROR((buf2 = malloc(bufsize + 1)) == NULL, "malloc(buf2)");
	ERROR(read(fd, buf, bufsize + 1) != bufsize, "Original read");

	ERROR(unlink(filename) != 0, "Unlink");

	/* This fails if we can't read after the unlink. */
	ERROR(lseek(fd, 0, SEEK_SET) != 0, "Second read seek");
	ERROR(read(fd, buf2, bufsize + 1) != bufsize, "Second read");
	ERROR(memcmp(buf, buf2, bufsize) != 0, "Second bad data");

	fd2 = open(filename, O_RDWR|O_CREAT|O_EXCL, 0644);
	ERROR(fd2 == -1, "Second open");

	/* This fails if we can't read after recreation. */
	ERROR(lseek(fd, 0, SEEK_SET) != 0, "Third read seek");
	ERROR(read(fd, buf2, bufsize + 1) != bufsize, "Third read");
	ERROR(memcmp(buf, buf2, bufsize) != 0, "Third bad data");

	l = strlen(judygarland);
	ERROR(write(fd2, judygarland, l) != l, "Rewrite.");
	ERROR(close(fd2) != 0, "close of new fd");

	/* This fails if we can't read after rewrite. */
	ERROR(lseek(fd, 0, SEEK_SET) != 0, "Fourth read");
	ERROR(read(fd, buf2, bufsize + 1) != bufsize, "Fourth read");
	ERROR(memcmp(buf, buf2, bufsize) != 0, "Fourth bad data");

	/* This fails if we can't copyup. */
	ERROR(fstat(fd, &st) == -1, "fstat");
	ERROR(st.st_size != bufsize, "File size changed.");

	l = strlen(judygarland2);
	if (bufsize < l) {
		free(buf);
		free(buf2);
		buf = strdup(judygarland2);
		ERROR(buf == NULL, "Reallocate buf.");
		bufsize = strlen(buf);
		buf2 = malloc(bufsize);
		ERROR(buf2 == NULL, "Reallocate buf2.");
	} else {
		memcpy(buf, judygarland2, l);
	}

	/* Rewrite of the file using our own fd (provoking copyup). */
	ERROR(lseek(fd, 0, SEEK_SET) != 0, "Second rewrite seek.");
	ERROR(write(fd, judygarland2, l) != l, "Second rewrite");
	ERROR(fstat(fd, &st) == -1, "fstat");
	ERROR(st.st_size != bufsize, "File size not bufsize.");

	/* This fails if we our rewrite didn't work. */
	ERROR(lseek(fd, 0, SEEK_SET) != 0, "Fifth read seek");
	ERROR((ret = read(fd, buf2, bufsize + 1)) != bufsize, "Fifth read");
	ERROR(memcmp(buf, buf2, bufsize) != 0, "Fifth bad data");

	ERROR(close(fd) != 0, "close of original fd");

	/* Now to make sure we didn't clobber the first verse. */
	fd2 = open(filename, O_RDWR);
	ERROR(fd2 == -1, "Third open");
	l = strlen(judygarland);
	if (bufsize < l + 1) {
		free(buf2);
		bufsize = l;
		buf2 = malloc(bufsize + 1);
		ERROR(buf2 == NULL, "Reallocate buf2.");
	}
	ERROR(read(fd, buf2, l + 1) != l, "Sixth read");
	ERROR(memcmp(judygarland, buf2, l) != 0, "Sixth bad data");
	ERROR(close(fd2) != 0, "Second close of new fd");

	unlink(filename);

	exit(0);
}
