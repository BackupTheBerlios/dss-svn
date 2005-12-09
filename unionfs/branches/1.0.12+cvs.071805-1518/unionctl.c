/*
 * Copyright (c) 2003-2005 Erez Zadok
 * Copyright (c) 2003-2005 Charles P. Wright
 * Copyright (c) 2003-2005 Mohammad Nayyer Zubair
 * Copyright (c) 2003-2005 Puja Gupta
 * Copyright (c) 2003-2005 Harikesavan Krishnan
 * Copyright (c) 2003-2005 Stony Brook University
 * Copyright (c) 2003-2005 The Research Foundation of State University of New York
 *
 * For specific licensing information, see the COPYING file distributed with
 * this package.
 *
 * This Copyright notice must be kept intact and distributed with all sources.
 */
/*
 *  $Id: unionctl.c,v 1.22 2005/07/18 15:03:18 cwright Exp $
 */

#include <sys/ioctl.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>

#include "fist.h"
#include "unionfs.h"

#define MAY_READ 4
#define MAY_WRITE 2

extern int find_union(const char *path, char **options, char **actual_path,
		      int uniononly);
char **branches;
int *branchperms;
static const char *progname;

#define usage() __usage(__LINE__)

void __attribute__ ((__noreturn__)) __usage(int line)
{
#ifdef DEBUG
	fprintf(stderr, "Line: %d\n", line);
#endif
	fprintf(stderr,
		"unionctl version: $Id: unionctl.c,v 1.22 2005/07/18 15:03:18 cwright Exp $\n");
	fprintf(stderr, "Distributed with Unionfs " UNIONFS_VERSION "\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "unionctl UNION ACTION [arguments]\n");
	fprintf(stderr,
		"ACTION can be --add, --remove, --mode, --list, or --query.\nFurther arguments depend on ACTION.\n");
	fprintf(stderr,
		"\tunionctl UNION --add [ --before BRANCH | --after BRANCH ] [ --mode (rw|ro) ] DIRECTORY\n");
	fprintf(stderr, "\tunionctl UNION --remove BRANCH\n");
	fprintf(stderr, "\tunionctl UNION --mode BRANCH (rw|ro)\n");
	fprintf(stderr, "\tunionctl UNION --list\n");
	fprintf(stderr, "\tunionctl UNION --query FILENAME\n");
	fprintf(stderr,
		"The unionctl man page has a more detailed description of its usage.\n");
	exit(1);
}

char **parse_options(char *options)
{
	char **ret = NULL;
	int n = 0;

	char *p;
	char *q;
	char *r;
	char *s;
	int l;

	p = options;
	do {
		q = strchr(p, ',');
		if (q) {
			*q++ = '\0';
		}
		if (!strncmp(p, "dirs=", strlen("dirs="))) {
			r = p + strlen("dirs=");
			do {
				s = strchr(r, ':');
				if (s) {
					*s++ = '\0';
				}

				n++;
				ret = realloc(ret, sizeof(char *) * (n + 1));
				if (!ret) {
					perror("realloc()");
					exit(1);
				}
				branchperms =
				    realloc(branchperms, sizeof(int) * n);
				if (!branchperms) {
					perror("realloc()");
					exit(1);
				}

				l = strlen(r);
				if (((r[l - 1] == 'o') || (r[l - 1] == 'w'))
				    && (r[l - 2] == 'r') && (r[l - 3] == '=')) {
					r[l - 3] = '\0';
					branchperms[n - 1] = MAY_READ;
					if (r[l - 1] == 'w') {
						branchperms[n - 1] |= MAY_WRITE;
					}
				}
				ret[n - 1] = strdup(r);
				ret[n] = NULL;

				r = s;
			}
			while (r);
		}
		p = q;
	}
	while (p);

	branches = ret;
	return ret;
}

int get_branch(char *path)
{
	char *end;
	int ret;

	ret = strtol(path, &end, 0);
	if (!*end) {
		return ret;
	}

	ret = strlen(path);
	if (path[ret - 1] == '/') {
		path[ret - 1] = '\0';
	}

	ret = 0;
	while (branches[ret]) {
		if (!strcmp(branches[ret], path)) {
			return ret;
		}
		ret++;
	}

	return -1;
}

void dump_branches(const char *prefix)
{
	int n = 0;

	while (branches[n]) {
		char r, w;
		r = (branchperms[n] & MAY_READ) ? 'r' : '-';
		w = (branchperms[n] & MAY_WRITE) ? 'w' : '-';
		printf("%s%s (%c%c)\n", prefix, branches[n], r, w);
		n++;
	}
}

#define ADD 1
#define REMOVE 2
#define MODE 3
#define LIST 4
#define	QUERY 5

int main(int argc, char *argv[])
{
	struct unionfs_addbranch_args addargs;
	struct unionfs_rdwrbranch_args rdwrargs;
	struct unionfs_queryfile_args queryfile;
	struct stat st;

	int fd, ret, i;

	char *path;
	char *options = NULL, *actual_path = NULL;
	int action;

	char *branchpath;
	int branchnum;

	progname = argv[0];

	/* check that minimum number of args were specified */
	if (argc < 3)
		usage();

	path = argv[1];
	if (strcmp(path, "/") && (path[strlen(path) - 1] == '/')) {
		path[strlen(path) - 1] = '\0';
	}

	if (!strcmp(argv[2], "--add")) {
		action = ADD;
	} else if (!strcmp(argv[2], "--remove")) {
		action = REMOVE;
	} else if (!strcmp(argv[2], "--mode")) {
		action = MODE;
	} else if (!strcmp(argv[2], "--list")) {
		action = LIST;
	} else if (!strcmp(argv[2], "--query")) {
		action = QUERY;
	} else {
		usage();
	}

	if (stat(path, &st) == -1) {
		fprintf(stderr, "stat(%s): %s\n", path, strerror(errno));
		exit(1);
	}

	if (find_union(path, &options, &actual_path, 1) < 0) {
		fprintf(stderr, "%s is not a valid union.\n", path);
		exit(1);
	}
	branches = parse_options(options);
	if (!branches) {
		fprintf(stderr, "Could not parse options from /proc/mounts!\n");
		exit(1);
	}

	/* open file on which ioctl will operate (that is actually any file in the union) */
	fd = open(path, O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "open(%s): %s\n", path, strerror(errno));
		exit(1);
	}

	/* Parse the action's options into something usable, and do it. */
	switch (action) {
	case ADD:
		if (argc < 4) {
			usage();
		}

		/* Default values if the user leaves them unspecified. */
		branchnum = 0;
		addargs.ab_perms = MAY_READ | MAY_WRITE;
		branchpath = NULL;
		for (i = 3; i < argc; i++) {
			if (argv[i][0] == '-' && argv[i][1] == '-') {
				if (!strcmp(argv[i], "--before")) {
					i++;
					if (i == argc) {
						fprintf(stderr,
							"%s requires an argument!\n",
							argv[i - 1]);
						usage();
					}

					branchnum = get_branch(argv[i]);
					if (branchnum == -1) {
						fprintf(stderr,
							"%s is not a valid branch.\nThe current branch configuration is:\n",
							argv[i]);
						dump_branches("\t");
					}
				} else if (!strcmp(argv[i], "--after")) {
					i++;
					if (i == argc) {
						fprintf(stderr,
							"%s requires an argument!\n",
							argv[i - 1]);
						usage();
					}

					branchnum = get_branch(argv[i]);
					if (branchnum == -1) {
						fprintf(stderr,
							"%s is not a valid branch.\nThe current branch configuration is:\n",
							argv[i]);
						dump_branches("\t");
					}
					branchnum++;
				} else if (!strcmp(argv[i], "--mode")) {
					i++;
					if (i == argc) {
						fprintf(stderr,
							"%s requires an argument!\n",
							argv[i - 1]);
						usage();
					}

					if (!strcmp(argv[i], "ro")) {
						addargs.ab_perms = MAY_READ;
					} else if (!strcmp(argv[i], "rw")) {
						addargs.ab_perms =
						    MAY_READ | MAY_WRITE;
					} else {
						fprintf(stderr,
							"Valid modes are ro and rw you specified: \"%s\"\n",
							argv[i]);
						usage();
					}
				} else {
					fprintf(stderr, "Unknown option: %s\n",
						argv[i]);
					usage();
				}
			} else {
				/* The options must go before the path */
				if ((i + 1) != argc) {
					fprintf(stderr,
						"The path of the branch to add must go after all options.\n");
					usage();
				}
				branchpath = argv[i];
			}
		}
		if (!branchpath) {
			fprintf(stderr,
				"You must specify the path to add into the union!\n");
			usage();
		}

		addargs.ab_branch = branchnum;
		addargs.ab_path = branchpath;

		errno = 0;
		ret = ioctl(fd, UNIONFS_IOCTL_ADDBRANCH, &addargs);
		if (ret < 0) {
			switch (errno) {
			case E2BIG:
				fprintf(stderr,
					"Unionfs supports only %d branches.\n",
					FD_SETSIZE);
				break;
			}
			fprintf(stderr, "Failed to add %s into %s: %s",
				branchpath, path, strerror(errno));
			exit(1);
		}
		break;
	case MODE:
		if (argc != 5) {
			usage();
		}

		branchpath = argv[3];

		/* Set a branches writeable status. */
		rdwrargs.rwb_branch = get_branch(branchpath);
		if (rdwrargs.rwb_branch == -1) {
			fprintf(stderr,
				"%s is not a valid branch.\nThe current branch configuration is:\n",
				branchpath);
			dump_branches("\t");
			exit(1);
		}

		if (!strcmp(argv[4], "ro")) {
			rdwrargs.rwb_perms = MAY_READ;
		} else if (!strcmp(argv[4], "rw")) {
			rdwrargs.rwb_perms = MAY_READ | MAY_WRITE;
		} else {
			usage();
		}

		ret = ioctl(fd, UNIONFS_IOCTL_RDWRBRANCH, &rdwrargs);
		if (ret < 0) {
			fprintf(stderr,
				"Failed to set permissions for %s in %s: %s",
				branchpath, path, strerror(errno));
			exit(1);
		}

		goto out;
		break;
	case REMOVE:
		if (argc != 4) {
			usage();
		}
		branchpath = argv[3];

		branchnum = get_branch(branchpath);
		if (branchnum == -1) {
			fprintf(stderr,
				"%s is not a valid branch.\nThe current branch configuration is:\n",
				branchpath);
			dump_branches("\t");
			exit(1);
		}

		errno = 0;
		ret = ioctl(fd, UNIONFS_IOCTL_DELBRANCH, branchnum);
		if (ret < 0) {
			fprintf(stderr, "Failed to remove %s from %s: %s",
				branchpath, path, strerror(errno));
			if (errno == EBUSY) {
				fprintf(stderr,
					"Did you specify the union using its root directory?\n");
			}
			exit(1);
		}

		break;
	case LIST:
		dump_branches("\t");
		break;

	case QUERY:
		if (argc != 4) {
			usage();
		}
		queryfile.filename = argv[3];

		ret = ioctl(fd, UNIONFS_IOCTL_QUERYFILE, &queryfile);
		if (ret < 0) {
			fprintf(stderr,
				"Unable to retrieve list of branches for file %s : %s",
				queryfile.filename, strerror(errno));
			exit(1);
		}

		for (i = 0; i <= ret; i++)
			if (FD_ISSET(i, &queryfile.branchlist))
				printf("File [%s] found in branch [%d]\n",
				       queryfile.filename, i);
		break;
	}

      out:
	close(fd);
	exit(0);
}

/*
 *
 * vim:shiftwidth=8
 * vim:tabstop=8
 *
 * For Emacs:
 * Local variables:
 * c-basic-offset: 8
 * c-comment-only-line-offset: 0
 * c-offsets-alist: ((statement-block-intro . +) (knr-argdecl-intro . 0)
 *              (substatement-open . 0) (label . 0) (statement-cont . +))
 * indent-tabs-mode: t
 * tab-width: 8
 * End:
 */
