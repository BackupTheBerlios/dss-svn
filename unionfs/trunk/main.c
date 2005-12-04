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
 *  $Id: main.c,v 1.108 2005/07/18 15:03:17 cwright Exp $
 */

#include "fist.h"
#include "unionfs.h"
#include <linux/module.h>

/* sb we pass is unionfs's super_block */
int unionfs_interpose(struct dentry *dentry, struct super_block *sb, int flag)
{
	struct inode *hidden_inode;
	struct dentry *hidden_dentry;
	int err = 0;
	struct inode *inode;
	int is_negative_dentry = 1;
	int bindex, bstart, bend;

	print_entry("flag = %d", flag);

	fist_print_dentry("In unionfs_interpose: ", dentry);

	bstart = dbstart(dentry);
	bend = dbend(dentry);

	/* Make sure that we didn't get a negative dentry. */
	for (bindex = bstart; bindex <= bend; bindex++) {
		if (dtohd_index(dentry, bindex) &&
		    dtohd_index(dentry, bindex)->d_inode) {
			is_negative_dentry = 0;
			break;
		}
	}
	ASSERT(!is_negative_dentry);

	/* We allocate our new inode below, by calling iget.
	 * iget will call our read_inode which will initialize some
	 * of the new inode's fields
	 */

	/* On revalidate we've already got our own inode and just need
	 * to fix it up. */
	if (flag == INTERPOSE_REVAL) {
		inode = dentry->d_inode;
		PASSERT(inode);
		itopd(inode)->b_start = -1;
		itopd(inode)->b_end = -1;
		atomic_set(&itopd(inode)->uii_generation,
			   atomic_read(&stopd(sb)->usi_generation));

		if (sbmax(sb) > UNIONFS_INLINE_OBJECTS) {
			int size =
			    (sbmax(sb) -
			     UNIONFS_INLINE_OBJECTS) * sizeof(struct inode *);
			itohi_ptr(inode) = KMALLOC(size, GFP_UNIONFS);
			if (!itohi_ptr(inode)) {
				err = -ENOMEM;
				goto out;
			}
			memset(itohi_ptr(inode), 0, size);
		}
		memset(itohi_inline(inode), 0,
		       UNIONFS_INLINE_OBJECTS * sizeof(struct inode *));
	} else if (flag == INTERPOSE_LINK) {
		inode = dentry->d_inode;
	} else {
		/* get unique inode number for unionfs */
		if (stopd(sb)->usi_persistent)
			inode =
			    iget(sb,
				 get_uin(sb, bindex,
					 dtohd_index(dentry,
						     bindex)->d_inode->i_ino,
					 O_CREAT));
		else
			inode = iget(sb, iunique(sb, UNIONFS_ROOT_INO));
		if (!inode) {
			err = -EACCES;	/* should be impossible??? */
			goto out;
		}
	}

	/*
	 * interpose the inode if not already interposed
	 *   this is possible if the inode is being reused
	 */
	for (bindex = bstart; bindex <= bend; bindex++) {
		hidden_dentry = dtohd_index(dentry, bindex);
		if (!hidden_dentry) {
			set_itohi_index(inode, bindex, NULL);
			continue;
		}
		/* initialize the hidden inode to the new hidden inode */
		if (hidden_dentry->d_inode != NULL)
			set_itohi_index(inode, bindex,
					igrab(hidden_dentry->d_inode));
	}

	ibstart(inode) = dbstart(dentry);
	ibend(inode) = dbend(dentry);

	/* Use attributes from the first branch. */
	hidden_inode = itohi(inode);
	PASSERT(hidden_inode);

	/* Use different set of inode ops for symlinks & directories */
	if (S_ISLNK(hidden_inode->i_mode))
		inode->i_op = &unionfs_symlink_iops;
	else if (S_ISDIR(hidden_inode->i_mode))
		inode->i_op = &unionfs_dir_iops;

	/* Use different set of file ops for directories */
	if (S_ISDIR(hidden_inode->i_mode))
		inode->i_fop = &unionfs_dir_fops;

	/* properly initialize special inodes */
	if (S_ISBLK(hidden_inode->i_mode) || S_ISCHR(hidden_inode->i_mode) ||
	    S_ISFIFO(hidden_inode->i_mode) || S_ISSOCK(hidden_inode->i_mode))
		init_special_inode(inode, hidden_inode->i_mode,
				   hidden_inode->i_rdev);

	/* Fix our inode's address operations to that of the lower inode (Unionfs is FiST-Lite) */
	if (inode->i_mapping->a_ops != hidden_inode->i_mapping->a_ops) {
		fist_dprint(7, "fixing inode 0x%p a_ops (0x%p -> 0x%p)\n",
			    inode, inode->i_mapping->a_ops,
			    hidden_inode->i_mapping->a_ops);
		inode->i_mapping->a_ops = hidden_inode->i_mapping->a_ops;
	}

	/* all well, copy inode attributes */
	fist_copy_attr_all(inode, hidden_inode);

	/* only (our) lookup wants to do a d_add */
	switch (flag) {
	case INTERPOSE_DEFAULT:
	case INTERPOSE_LINK:
	case INTERPOSE_REVAL_NEG:
		d_instantiate(dentry, inode);
		break;
	case INTERPOSE_LOOKUP:
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,0)
		err = PTR_ERR(d_splice_alias(inode, dentry));
#else
		d_add(dentry, inode);
#endif
		break;
	case INTERPOSE_REVAL:
		/* Do nothing. */
		break;
	default:
		FISTBUG("Invalid interpose flag passed!");
	}

	PASSERT(dtopd(dentry));

	fist_print_dentry("Leaving unionfs_interpose: ", dentry);
	fist_print_inode("Leaving unionfs_interpose: ", inode);

      out:
	print_exit_status(err);
	return err;
}

void unionfs_reinterpose(struct dentry *dentry)
{
	struct dentry *hidden_dentry;
	struct inode *inode;
	int bindex, bstart, bend;

	print_entry_location();

	fist_print_dentry("IN: unionfs_reinterpose: ", dentry);

	/* do not allow files getting deleted to be reinterposed */
	ASSERT(!d_unhashed(dentry));

	/* This is pre-allocated inode */
	inode = dentry->d_inode;
	PASSERT(inode);

	bstart = dbstart(dentry);
	bend = dbend(dentry);
	for (bindex = bstart; bindex <= bend; bindex++) {
		hidden_dentry = dtohd_index(dentry, bindex);

		if (!hidden_dentry)
			continue;

		/* initialize the hidden inode to the new hidden inode */
		if (hidden_dentry->d_inode) {
			if (itohi_index(inode, bindex) == NULL) {
				set_itohi_index(inode, bindex,
						igrab(hidden_dentry->d_inode));
			}
		}
	}
	ibstart(inode) = dbstart(dentry);
	ibend(inode) = dbend(dentry);

	/* TODO : do we need to call, d_add/d_instantiate? */

	fist_print_dentry("OUT: unionfs_reinterpose: ", dentry);
	fist_print_inode("OUT: unionfs_reinterpose: ", inode);

	print_exit_location();
}

/*
 * Parse mount options:
 * Current mount command example =
 * mount -t unionfs -o dirs=b1=rw:b2=ro:b3=rw:b4=ro,delete=all,copyup=mounter,copyupuid=2,copyupgid=3,copyupmode=0777,
 * setattr=left,err=passup,,debug=N null /mnt/unionfs
 * any leading and/or trailing colons are ignored
 *
 * Returns the dentry object of the lower-level (hidden) directory;
 * We want to mount our stackable file system on top of that hidden directory.
 *
 * Sets default debugging level to N, if any.
 */
struct unionfs_dentry_info *unionfs_parse_options(struct super_block *sb,
						  char *options)
{
	struct unionfs_dentry_info *hidden_root_info;
	struct nameidata nd;
	char *name, *tmp, *tmp2, *end, *end2, *firstchar;
	int err = 0;
	int bindex = 0;
	int i;
	int branches = -1;

	print_entry_location();

	/* allocate private data area */
	hidden_root_info =
	    KMALLOC(sizeof(struct unionfs_dentry_info), GFP_UNIONFS);
	if (!hidden_root_info) {
		err = -ENOMEM;
		goto out_error;
	}
	memset(hidden_root_info, 0, sizeof(struct unionfs_dentry_info));
	hidden_root_info->udi_bstart = -1;
	hidden_root_info->udi_bend = -1;
	hidden_root_info->udi_bopaque = -1;

	firstchar = options;

	/* We don't want to go off the end of our arguments later on. */
	for (end = options; *end; end++) ;

	while (options < end) {
		tmp = options;

		while (*tmp && *tmp != ',') {
			tmp++;
		}
		*tmp = '\0';

		if (!strncmp("dirs=", options, (sizeof("dirs=") - 1))) {
			int pobjects = 0;
			options = options + (sizeof("dirs=") - 1);

			/* colon at the beginning */
			if (*options == ':') {
				options++;
			}

			/* We don't want to go off the end of our dir arguments later on. */
			for (end2 = options; *end2; end2++) ;

			/* colon at the end */
			if (*(end2 - 1) == ':') {
				end2--;
				*end2 = '\0';
			}

			if (options == end2) {
				err = -EINVAL;
				printk(KERN_WARNING
				       "unionfs: non-blank dirs option required\n");
				goto out_error;
			}

			/* We have to have at least one branch, and each ':' means we have one more. */
			branches = 1;
			for (tmp2 = options; *tmp2; tmp2++) {
				if (*tmp2 == ':') {
					branches++;
				}
			}

			/* allocate space for  underlying pointers to hidden dentry */
			if (branches > UNIONFS_INLINE_OBJECTS)
				pobjects = branches - UNIONFS_INLINE_OBJECTS;

			if (pobjects) {
				hidden_root_info->udi_dentry_p =
				    KMALLOC(sizeof(struct dentry *) * pobjects,
					    GFP_UNIONFS);
				if (IS_ERR(hidden_root_info->udi_dentry_p)) {
					goto out_error;
				}
				memset(hidden_root_info->udi_dentry_p, 0,
				       sizeof(struct dentry *) * pobjects);

				/* allocate space for underlying pointers to super block */
				stohs_ptr(sb) =
				    KMALLOC(sizeof(struct super_block *) *
					    pobjects, GFP_UNIONFS);
				if (IS_ERR(stohs_ptr(sb))) {
					err = -ENOMEM;
					goto out_error;
				}
				memset(stohs_ptr(sb), 0,
				       pobjects * sizeof(struct super_block *));

				/* Set all reference counts to zero. */
				stopd(sb)->usi_sbcount_p =
				    KMALLOC(sizeof(atomic_t) * pobjects,
					    GFP_UNIONFS);
				if (IS_ERR(stopd(sb)->usi_sbcount_p)) {
					err = -ENOMEM;
					goto out_error;
				}

				/* Set the permissions to none (we'll fix them up later). */
				stopd(sb)->usi_branchperms_p =
				    KMALLOC(sizeof(int) * pobjects,
					    GFP_UNIONFS);
				if (IS_ERR(stopd(sb)->usi_branchperms_p)) {
					err = -ENOMEM;
					goto out_error;
				}

				/* allocate space for array of pointers for underlying mount points */
				stohiddenmnt_ptr(sb) =
				    KMALLOC(sizeof(struct vfsmount *) *
					    pobjects, GFP_UNIONFS);
				if (IS_ERR(stohiddenmnt_ptr(sb))) {
					err = -ENOMEM;
					goto out_error;
				}
			}

			for (i = 0; i < branches; i++)
				set_branch_count(sb, i, 0);

			/* now parsing the string b1:b2=rw:b3=ro:b4 */
			while (options < end2) {
				int perms;

				int l;

				tmp2 = options;

				while (*tmp2 && *tmp2 != ':') {
					tmp2++;
				}
				*tmp2 = '\0';

				/* name contains individual dir */
				name = options;

				/* strip off =rw or =ro if it is specified. */
				l = strlen(name);
				if (!strcmp(name + l - 3, "=ro")) {
					perms = MAY_READ;
					name[l - 3] = '\0';
				} else if (!strcmp(name + l - 3, "=rw")) {
					perms = MAY_READ | MAY_WRITE;
					name[l - 3] = '\0';
				} else {
					perms = MAY_READ | MAY_WRITE;
				}

				fist_dprint(4,
					    "unionfs: using directory: %s (%c%c)\n",
					    name, perms & MAY_READ ? 'r' : '-',
					    perms & MAY_WRITE ? 'w' : '-');

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
				if (path_init(name, LOOKUP_FOLLOW, &nd)) {
					err = path_walk(name, &nd);
				}
#else
				err = path_lookup(name, LOOKUP_FOLLOW, &nd);
#endif
				if (err) {
					printk
					    ("unionfs: error accessing hidden directory '%s' (error %d)\n",
					     name, err);
					goto out_error;
				}

				if (bindex < UNIONFS_INLINE_OBJECTS)
					hidden_root_info->udi_dentry_i[bindex] =
					    nd.dentry;
				else
					hidden_root_info->udi_dentry_p[bindex -
								       UNIONFS_INLINE_OBJECTS]
					    = nd.dentry;

				set_stohiddenmnt_index(sb, bindex, nd.mnt);
				set_branchperms(sb, bindex, perms);

				if (hidden_root_info->udi_bstart < 0)
					hidden_root_info->udi_bstart = bindex;
				hidden_root_info->udi_bend = bindex;
				bindex++;

				options = tmp2 + 1;
			}
		} else if (!strncmp("imap=", options, (sizeof("imap=") - 1))) {
			options = options + (sizeof("imap=") - 1);
			err =
			    parse_imap_options(sb, hidden_root_info, &options);
			if (err) {
				goto out_error;
			}
		} else if (!strncmp("debug=", options, (sizeof("debug=") - 1))) {
			char *endptr;
			int debug;

			options = options + (sizeof("debug=") - 1);
			debug = simple_strtoul(options, &endptr, 0);

			if (*endptr) {
				printk(KERN_WARNING
				       "unionfs: invalid debug option '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
			fist_set_debug_value(debug);
		} else if (!strncmp("err=", options, (sizeof("err=") - 1))) {
			options = options + (sizeof("err=") - 1);

			if (!strcmp("tryleft", options)) {
				/* default */
			} else if (!strcmp("passup", options)) {
				MOUNT_FLAG(sb) |= GLOBAL_ERR_PASSUP;
			} else {
				printk(KERN_WARNING
				       "unionfs: could not parse err option value '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
		} else
		    if (!strncmp("delete=", options, (sizeof("delete=") - 1))) {
			options = options + (sizeof("delete=") - 1);

			if (!strcmp("all", options)) {
				/* default */
			} else if (!strcmp("first", options)) {
				MOUNT_FLAG(sb) |= DELETE_FIRST;
			} else if (!strcmp("whiteout", options)) {
				MOUNT_FLAG(sb) |= DELETE_WHITEOUT;
			} else {
				printk(KERN_WARNING
				       "unionfs: could not parse delete option value '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
		} else
		    if (!strncmp("setattr=", options, (sizeof("setattr=") - 1)))
		{
			options = options + (sizeof("setattr=") - 1);

			if (!strcmp("left", options)) {
				/* default */
			} else if (!strcmp("all", options)) {
				MOUNT_FLAG(sb) |= SETATTR_ALL;
			} else {
				printk(KERN_WARNING
				       "unionfs: could not parse setattr option value '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
		} else
		    if (!strncmp("copyup=", options, (sizeof("copyup=") - 1))) {
			char *tmp;
			char found = 0;

			options = options + (sizeof("copyup=") - 1);

			if (!strcmp("preserve", options)) {
				/* default */
			} else if (!strcmp("currentuser", options)) {
				MOUNT_FLAG(sb) |= COPYUP_CURRENT_USER;
			} else if (!strcmp("mounter", options)) {
				/* if mounter is specified then copyupuid, copyupgid and
				   copyupmode should be specified also. */
				for (tmp = firstchar; tmp < end; tmp++) {
					if (!strncmp
					    ("copyupuid", tmp,
					     (sizeof("copyupuid") - 1))) {
						found = 1;
						break;
					}
				}
				if (!found) {
					printk(KERN_WARNING
					       "unionfs: copyupuid option is not specified\n");
					err = -EINVAL;
					goto out_error;
				}
				found = 0;
				for (tmp = firstchar; tmp < end; tmp++) {
					if (!strncmp
					    ("copyupgid", tmp,
					     (sizeof("copyupgid") - 1))) {
						found = 1;
						break;
					}
				}
				if (!found) {
					printk(KERN_WARNING
					       "unionfs: copyupgid option is not specified\n");
					err = -EINVAL;
					goto out_error;
				}
				found = 0;
				for (tmp = firstchar; tmp < end; tmp++) {
					if (!strncmp
					    ("copyupmode", tmp,
					     (sizeof("copyupmode") - 1))) {
						found = 1;
						break;
					}
				}
				if (!found) {
					printk(KERN_WARNING
					       "unionfs: copyupmode option is not specified\n");
					err = -EINVAL;
					goto out_error;
				}

				MOUNT_FLAG(sb) |= COPYUP_FS_MOUNTER;

			} else {
				printk(KERN_WARNING
				       "unionfs: could not parse copyup option value '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
		} else
		    if (!strncmp
			("copyupuid=", options, (sizeof("copyupuid=") - 1))) {
			char *tmp, *endptr;
			char found = 0;

			options = options + (sizeof("copyupuid=") - 1);
			/* check for the presence of the string 'copyup=mounter' in the options string
			   firstchar points to the first character in the options string,
			   end points to the last */
			for (tmp = firstchar; tmp < end; tmp++) {
				if (!strncmp
				    ("copyup=mounter", tmp,
				     (sizeof("copyup=mounter") - 1))) {
					found = 1;
					break;
				}
			}
			if (!found) {
				printk(KERN_WARNING
				       "unionfs: copyup option is not set to mounter\n");
				err = -EINVAL;
				goto out_error;
			}

			stopd(sb)->copyupuid =
			    simple_strtoul(options, &endptr, 0);

			if (*endptr) {
				printk(KERN_WARNING
				       "unionfs: invalid copyupuid option '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
		} else
		    if (!strncmp
			("copyupgid=", options, (sizeof("copyupgid=") - 1))) {
			char *tmp, *endptr;
			char found = 0;

			options = options + (sizeof("copyupgid=") - 1);
			/* check for the presence of the string 'copyup=mounter' in the options string
			   firstchar points to the first character in the options string,
			   end points to the last */
			for (tmp = firstchar; tmp < end; tmp++) {
				if (!strncmp
				    ("copyup=mounter", tmp,
				     (sizeof("copyup=mounter") - 1))) {
					found = 1;
					break;
				}
			}
			if (!found) {
				printk(KERN_WARNING
				       "unionfs: copyup option is not set to mounter\n");
				err = -EINVAL;
				goto out_error;
			}

			stopd(sb)->copyupgid =
			    simple_strtoul(options, &endptr, 0);

			if (*endptr) {
				printk(KERN_WARNING
				       "unionfs: invalid copyupgid option '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
		} else
		    if (!strncmp
			("copyupmode=", options, (sizeof("copyupmode=") - 1))) {
			char *tmp, *endptr;
			char found = 0;

			options = options + (sizeof("copyupmode=") - 1);
			/* check for the presence of the string 'copyup=mounter' in the options string
			   firstchar points to the first character in the options string,
			   end points to the last */
			for (tmp = firstchar; tmp < end; tmp++) {
				if (!strncmp
				    ("copyup=mounter", tmp,
				     (sizeof("copyup=mounter") - 1))) {
					found = 1;
					break;
				}
			}
			if (!found) {
				printk(KERN_WARNING
				       "unionfs: copyup option is not set to mounter\n");
				err = -EINVAL;
				goto out_error;
			}

			stopd(sb)->copyupmode =
			    simple_strtoul(options, &endptr, 0);

			if (*endptr) {
				printk(KERN_WARNING
				       "unionfs: invalid copyupmode option '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
		} else
		    if (!strncmp
			("diropaque=", options, (sizeof("diropaque=") - 1))) {
			char *endptr;

			options = options + (sizeof("diropaque=") - 1);
			stopd(sb)->usi_diropaque =
			    simple_strtoul(options, &endptr, 0);

			if (*endptr) {
				printk(KERN_WARNING
				       "unionfs: invalid diropaque option '%s'\n",
				       options);
				err = -EINVAL;
				goto out_error;
			}
		} else {
			printk(KERN_WARNING
			       "unionfs: unrecognized option '%s'\n", options);
			err = -EINVAL;
			goto out_error;
		}
		options = tmp + 1;
	}
	if (branches == -1) {
		printk(KERN_WARNING "unionfs: dirs option required\n");
		err = -EINVAL;
		goto out_error;
	}
	ASSERT(branches == (hidden_root_info->udi_bend + 1));

	goto out;

      out_error:
	for (bindex = hidden_root_info->udi_bstart;
	     bindex >= 0 && bindex <= hidden_root_info->udi_bend; bindex++) {
		struct dentry *d;
		if (bindex < UNIONFS_INLINE_OBJECTS)
			d = hidden_root_info->udi_dentry_i[bindex];
		else
			d = hidden_root_info->udi_dentry_p[bindex -
							   UNIONFS_INLINE_OBJECTS];
		dput(d);
		if (stohiddenmnt_index(sb, bindex))
			mntput(stohiddenmnt_index(sb, bindex));
	}
	KFREE(hidden_root_info->udi_dentry_p);
	KFREE(hidden_root_info);
	KFREE(stohiddenmnt_ptr(sb));
	stohiddenmnt_ptr(sb) = NULL;
	KFREE(stopd(sb)->usi_sbcount_p);
	stopd(sb)->usi_sbcount_p = NULL;
	KFREE(stopd(sb)->usi_branchperms_p);
	stopd(sb)->usi_branchperms_p = NULL;
	KFREE(stohs_ptr(sb));
	stohs_ptr(sb) = NULL;

	hidden_root_info = ERR_PTR(err);
      out:
	print_exit_location();
	return hidden_root_info;
}

#ifdef FIST_MALLOC_DEBUG
/* for malloc debugging */
atomic_t unionfs_malloc_counter;
atomic_t unionfs_mallocs_outstanding;

atomic_t unionfs_dget_counter;
atomic_t unionfs_dgets_outstanding;

void *unionfs_kmalloc(size_t len, int flag, int line, const char *file)
{
	void *ptr = (void *)kmalloc(len, flag);
	if (ptr) {
		atomic_inc(&unionfs_malloc_counter);
		atomic_inc(&unionfs_mallocs_outstanding);
		printk("KM:%d:%d:%p:%d:%s\n",
		       atomic_read(&unionfs_malloc_counter),
		       atomic_read(&unionfs_mallocs_outstanding), ptr, line,
		       file);
	}
	return ptr;
}

void unionfs_kfree(void *ptr, int line, const char *file)
{
	atomic_inc(&unionfs_malloc_counter);
	if (ptr)
		atomic_dec(&unionfs_mallocs_outstanding);
	printk("KF:%d:%d:%p:%d:%s\n", atomic_read(&unionfs_malloc_counter),
	       atomic_read(&unionfs_mallocs_outstanding), ptr, line, file);
	kfree(ptr);
}

#endif				/* FIST_MALLOC_DEBUG */

/* for attach mode, we use a different ->read_super() in attach.c */

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
struct super_block *
#else
static int
#endif
unionfs_read_super(struct super_block *sb, void *raw_data, int silent)
{
	int err = 0;

	struct unionfs_dentry_info *hidden_root_info = NULL;
	int bindex, bstart, bend;
	unsigned long long maxbytes;

	print_entry_location();

#ifdef FIST_MALLOC_DEBUG
	atomic_set(&unionfs_malloc_counter, 0);	/* for malloc debugging */
#endif				/* FIST_MALLOC_DEBUG */

	if (!raw_data) {
		printk(KERN_WARNING
		       "unionfs_read_super: missing data argument\n");
		err = -EINVAL;
		goto out;
	}

	/*
	 * Allocate superblock private data
	 */
	stopd_lhs(sb) = KMALLOC(sizeof(struct unionfs_sb_info), GFP_UNIONFS);
	if (!stopd(sb)) {
		printk(KERN_WARNING "%s: out of memory\n", __FUNCTION__);
		err = -ENOMEM;
		goto out;
	}
	memset(stopd(sb), 0, sizeof(struct unionfs_sb_info));
	stopd(sb)->b_start = -1;
	stopd(sb)->b_end = -1;
	stopd(sb)->usi_diropaque = 1;
	atomic_set(&stopd(sb)->usi_generation, 1);

	hidden_root_info = unionfs_parse_options(sb, raw_data);

	if (IS_ERR(hidden_root_info)) {
		printk(KERN_WARNING
		       "unionfs_read_super: error while parsing options (err = %ld)\n",
		       PTR_ERR(hidden_root_info));
		err = PTR_ERR(hidden_root_info);
		hidden_root_info = NULL;
		goto out_free;
	}
	if (hidden_root_info->udi_bstart == -1) {
		err = -ENOENT;
		goto out_free;
	}

	/*
	 * Traverse the entire returned hidden_root_info structure
	 * to find if all inode exists
	 */
	bstart = hidden_root_info->udi_bstart;
	bend = hidden_root_info->udi_bend;
	for (bindex = bstart; bindex <= bend; bindex++) {
		struct dentry *d;

		if (bindex < UNIONFS_INLINE_OBJECTS)
			d = hidden_root_info->udi_dentry_i[bindex];
		else
			d = hidden_root_info->udi_dentry_p[bindex -
							   UNIONFS_INLINE_OBJECTS];

		if (!d->d_inode) {
			printk(KERN_WARNING
			       "unionfs_read_super: no directory to interpose on for branch %d\n",
			       bindex);
			err = -ENOENT;
			goto out_dput;
		}
	}

	/* set the hidden superblock field of upper superblock */
	sbstart(sb) = bstart;
	sbend(sb) = bend;
	for (bindex = bstart; bindex <= bend; bindex++) {
		struct dentry *d;

		if (bindex < UNIONFS_INLINE_OBJECTS)
			d = hidden_root_info->udi_dentry_i[bindex];
		else
			d = hidden_root_info->udi_dentry_p[bindex -
							   UNIONFS_INLINE_OBJECTS];

		set_stohs_index(sb, bindex, d->d_sb);
	}

	/* Unionfs: Max Bytes is the maximum bytes from among all the branches */
	maxbytes = -1;
	for (bindex = bstart; bindex <= bend; bindex++)
		if (maxbytes < stohs_index(sb, bindex)->s_maxbytes)
			maxbytes = stohs_index(sb, bindex)->s_maxbytes;
	sb->s_maxbytes = maxbytes;

	sb->s_op = &unionfs_sops;
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,0)
	sb->s_export_op = &unionfs_export_ops;
#endif

	/*
	 * we can't use d_alloc_root if we want to use
	 * our own interpose function unchanged,
	 * so we simply replicate *most* of the code in d_alloc_root here
	 */
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
	sb->s_root = d_alloc(NULL, &(const struct qstr) {
			     "/", 1, 0});
#else
	sb->s_root = d_alloc(NULL, &(const struct qstr) {
      hash: 0, name: "/", len:1});
#endif
	if (IS_ERR(sb->s_root)) {
		printk(KERN_WARNING "unionfs_read_super: d_alloc failed\n");
		err = PTR_ERR(sb->s_root);
		goto out_dput;
	}

	sb->s_root->d_op = &unionfs_dops;
	sb->s_root->d_sb = sb;
	sb->s_root->d_parent = sb->s_root;

	/* link the upper and lower dentries */
	dtopd_lhs(sb->s_root) = NULL;
	if ((err = new_dentry_private_data(sb->s_root)))
		goto out_freedpd;

	/* Set the hidden dentries for s_root */
	for (bindex = bstart; bindex <= bend; bindex++) {
		struct dentry *d;

		if (bindex < UNIONFS_INLINE_OBJECTS)
			d = hidden_root_info->udi_dentry_i[bindex];
		else
			d = hidden_root_info->udi_dentry_p[bindex -
							   UNIONFS_INLINE_OBJECTS];

		set_dtohd_index(sb->s_root, bindex, d);
	}
	set_dbstart(sb->s_root, bstart);
	set_dbend(sb->s_root, bend);

	/* Set the generation number to one, since this is for the mount. */
	atomic_set(&dtopd(sb->s_root)->udi_generation, 1);

	/* call interpose to create the upper level inode */
	if ((err = unionfs_interpose(sb->s_root, sb, 0)))
		goto out_freedpd;
	goto out;

      out_freedpd:
	if (dtopd(sb->s_root)) {
		KFREE(dtohd_ptr(sb->s_root));
		free_dentry_private_data(dtopd(sb->s_root));
	}
	dput(sb->s_root);
      out_dput:
	if (hidden_root_info && !IS_ERR(hidden_root_info)) {
		for (bindex = hidden_root_info->udi_bstart;
		     bindex <= hidden_root_info->udi_bend; bindex++) {
			struct dentry *d;

			if (bindex < UNIONFS_INLINE_OBJECTS)
				d = hidden_root_info->udi_dentry_i[bindex];
			else if (!hidden_root_info->udi_dentry_p)
				break;
			else
				d = hidden_root_info->udi_dentry_p[bindex -
								   UNIONFS_INLINE_OBJECTS];

			if (d)
				dput(d);

			if (stopd(sb) && stohiddenmnt_index(sb, bindex))
				mntput(stohiddenmnt_index(sb, bindex));
		}
		KFREE(hidden_root_info->udi_dentry_p);
		KFREE(hidden_root_info);
		hidden_root_info = NULL;
	}
      out_free:
	KFREE(stohiddenmnt_ptr(sb));
	KFREE(stopd(sb)->usi_sbcount_p);
	KFREE(stopd(sb)->usi_branchperms_p);
	KFREE(stohs_ptr(sb));
	if (stopd(sb)) {
		KFREE(stopd(sb));
		stopd_lhs(sb) = NULL;
	}
      out:
	if (hidden_root_info && !IS_ERR(hidden_root_info)) {
		KFREE(hidden_root_info->udi_dentry_p);
		KFREE(hidden_root_info);
	}
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
	if (err)
		sb = NULL;
	print_exit_pointer(sb);
	return sb;
#else
	print_exit_status(err);
	return err;
#endif
}

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
/*----*/
// this structure *must* be static!!! (or the memory for 'name' gets
// corrupted in 2.3...)
static DECLARE_FSTYPE(unionfs_fs_type, "unionfs", unionfs_read_super, 0);
#else
static struct super_block *unionfs_get_sb(struct file_system_type *fs_type,
					  int flags, const char *dev_name,
					  void *raw_data)
{
	return get_sb_nodev(fs_type, flags, raw_data, unionfs_read_super);
}

void unionfs_kill_block_super(struct super_block *sb)
{
	generic_shutdown_super(sb);
/*
 *	XXX: BUG: Halcrow: Things get unstable sometime after this point:
 *
 *	lib/rwsem-spinlock.c:127: spin_is_locked on uninitialized
 *	spinlock a1c953d8.
 *
 *	fs/fs-writeback.c:402: spin_lock(fs/super.c:a0381828) already
 *	locked by fs/fs-writeback.c/402
 *
 *	Apparently, someone's not releasing a lock on sb_lock...
*/
}

static struct file_system_type unionfs_fs_type = {
	.owner = THIS_MODULE,
	.name = "unionfs",
	.get_sb = unionfs_get_sb,
	.kill_sb = unionfs_kill_block_super,
	.fs_flags = 0,
};

#endif
static int __init init_unionfs_fs(void)
{
	int err;
	printk("Registering unionfs " UNIONFS_VERSION "\n");
	if ((err = init_filldir_cache()))
		goto out;
	if ((err = init_inode_cache()))
		goto out;
	if ((err = init_dentry_cache()))
		goto out;
	err = register_filesystem(&unionfs_fs_type);
      out:
	if (err) {
		destroy_filldir_cache();
		destroy_inode_cache();
		destroy_dentry_cache();
	}
	return err;
}
static void __exit exit_unionfs_fs(void)
{
	destroy_filldir_cache();
	destroy_inode_cache();
	destroy_dentry_cache();
	unregister_filesystem(&unionfs_fs_type);
	printk("Completed unionfs module unload.\n");
}

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
EXPORT_NO_SYMBOLS;
#endif
MODULE_AUTHOR("Erez Zadok <ezk@cs.columbia.edu>");
MODULE_DESCRIPTION("FiST-generated unionfs filesystem");
MODULE_LICENSE("GPL");

module_init(init_unionfs_fs)
    module_exit(exit_unionfs_fs)
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
