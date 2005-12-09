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
 *  $Id: dirhelper.c,v 1.12 2005/07/18 15:03:17 cwright Exp $
 */

#include "fist.h"
#include "unionfs.h"

/* Delete all of the whiteouts in a given directory for rmdir. */
int delete_whiteouts(struct dentry *dentry, int bindex,
		     struct unionfs_dir_state *namelist)
{
	int err = 0;
	struct dentry *hidden_dir_dentry = NULL;
	struct dentry *hidden_dentry;
	struct super_block *sb;
	char *name = NULL;

	int i;
	struct list_head *pos;
	struct filldir_node *cursor;

	print_entry_location();

	sb = dentry->d_sb;

	ASSERT(S_ISDIR(dentry->d_inode->i_mode));

	/* First we need to make sure all of the hidden_dentries are filled in. */
	err = unionfs_partial_lookup(dentry);
	if (err) {
		goto out;
	}

	ASSERT(bindex >= dbstart(dentry));
	ASSERT(bindex <= dbend(dentry));

	/* Find out hidden parent dentry */
	hidden_dir_dentry = dtohd_index(dentry, bindex);
	PASSERT(hidden_dir_dentry);
	PASSERT(hidden_dir_dentry->d_inode);
	ASSERT(S_ISDIR(hidden_dir_dentry->d_inode->i_mode));

	name = (char *)__get_free_page(GFP_UNIONFS);
	if (!name) {
		err = -ENOMEM;
		goto out;
	}

	for (i = 0; i < namelist->uds_size; i++) {
		list_for_each(pos, &namelist->uds_list[i]) {
			cursor =
			    list_entry(pos, struct filldir_node, file_list);
			/* Only operate on whiteouts in this branch. */
			if (cursor->bindex != bindex)
				continue;
			if (!cursor->whiteout)
				continue;

			strcpy(name, ".wh.");
			strncpy(name + 4, cursor->name, PAGE_SIZE - 4);

			hidden_dentry =
			    lookup_one_len(name, hidden_dir_dentry,
					   cursor->namelen + 4);
			if (IS_ERR(hidden_dentry)) {
				err = PTR_ERR(hidden_dentry);
				goto out;
			}
			if (!hidden_dentry->d_inode) {
				dput(hidden_dentry);
				continue;
			}

			down(&hidden_dir_dentry->d_inode->i_sem);
			err =
			    vfs_unlink(hidden_dir_dentry->d_inode,
				       hidden_dentry);
			up(&hidden_dir_dentry->d_inode->i_sem);
			dput(hidden_dentry);

			if (!err) {
				d_delete(hidden_dentry);
			} else if (!IS_COPYUP_ERR(err)) {
				goto out;
			}
		}
	}

      out:
	/* After all of the removals, we should copy the attributes once. */
	fist_copy_attr_times(dentry->d_inode, hidden_dir_dentry->d_inode);
	dentry->d_inode->i_nlink = get_nlinks(dentry->d_inode);

	if (name) {
		free_page((unsigned long)name);
	}
	print_exit_status(err);
	return err;
}

#define RD_NONE 0
#define RD_CHECK_EMPTY 1
/* The callback structure for check_empty. */
struct unionfs_rdutil_callback {
	int err;
	int filldir_called;
	struct unionfs_dir_state *rdstate;
	int mode;
};

/* This is a filldir function that makes sure only whiteouts exist within a directory. */
static int readdir_util_callback(void *dirent, const char *name, int namelen,
				 loff_t offset, ino_t ino, unsigned int d_type)
{
	int err = 0;
	struct unionfs_rdutil_callback *buf =
	    (struct unionfs_rdutil_callback *)dirent;
	int whiteout = 0;
	struct filldir_node *found;

	print_entry_location();

	buf->filldir_called = 1;

	if (name[0] == '.'
	    && (namelen == 1 || (name[1] == '.' && namelen == 2))) {
		goto out;
	}

	if ((namelen > 4) && !strncmp(name, ".wh.", 4)) {
		namelen -= 4;
		name += 4;
		whiteout = 1;
	}

	found = find_filldir_node(buf->rdstate, name, namelen);
	/* If it was found in the table there was a previous whiteout. */
	if (found) {
		goto out;
	}

	/* If it wasn't found, and it isn't a whiteout the directory is not actually empty. */
	if ((buf->mode == RD_CHECK_EMPTY) && !whiteout) {
		err = -ENOTEMPTY;
		goto out;
	}

	err =
	    add_filldir_node(buf->rdstate, name, namelen,
			     buf->rdstate->uds_bindex, whiteout);

      out:
	buf->err = err;
	print_exit_status(err);
	return err;
}

/* Is a directory logically empty? */
int check_empty(struct dentry *dentry, struct unionfs_dir_state **namelist)
{
	int err = 0;
	struct dentry *hidden_dentry = NULL;
	struct super_block *sb;
	struct file *hidden_file;
	struct unionfs_rdutil_callback *buf = NULL;
	int bindex, bstart, bend;

	print_entry_location();

	sb = dentry->d_sb;

	ASSERT(S_ISDIR(dentry->d_inode->i_mode));

	/* First we need to make sure all of the hidden_dentries are filled in. */
	err = unionfs_partial_lookup(dentry);
	if (err) {
		goto out;
	}

	bstart = dbstart(dentry);
	bend = dbend(dentry);

	buf = KMALLOC(sizeof(struct unionfs_rdutil_callback), GFP_UNIONFS);
	if (!buf) {
		err = -ENOMEM;
		goto out;
	}
	buf->err = 0;
	buf->mode = RD_CHECK_EMPTY;
	buf->rdstate = alloc_rdstate(dentry->d_inode, bstart);
	if (!buf->rdstate) {
		err = -ENOMEM;
		goto out;
	}

	/* Open all of the hidden_dentries and use the rdutil_callback function as a filldir. */
	for (bindex = bstart; bindex <= bend; bindex++) {
		/* Find out hidden parent dentry */
		hidden_dentry = dtohd_index(dentry, bindex);

		/* continue if the hidden_dentry doesn't exist */
		if (!hidden_dentry) {
			continue;
		}

		/* If it is a positive dentry. */
		if (hidden_dentry->d_inode
		    && S_ISDIR(hidden_dentry->d_inode->i_mode)) {
			dget(hidden_dentry);
			mntget(stohiddenmnt_index(sb, bindex));
			branchget(sb, bindex);
			hidden_file =
			    dentry_open(hidden_dentry,
					stohiddenmnt_index(sb, bindex),
					O_RDONLY);
			if (IS_ERR(hidden_file)) {
				err = PTR_ERR(hidden_file);
				dput(hidden_dentry);
				branchput(sb, bindex);
				goto out;
			}

			do {
				buf->filldir_called = 0;
				buf->rdstate->uds_bindex = bindex;
				err =
				    vfs_readdir(hidden_file,
						readdir_util_callback, buf);
				if (buf->err) {
					err = buf->err;
				}
			} while ((err >= 0) && buf->filldir_called);

			/* fput calls dput for hidden_dentry */
			fput(hidden_file);
			branchput(sb, bindex);

			if (err < 0)
				goto out;
		}
	}

      out:
	if (buf) {
		if (namelist && !err) {
			*namelist = buf->rdstate;
		} else if (buf->rdstate) {
			free_rdstate(buf->rdstate);
		}
		KFREE(buf);
	}

	print_exit_status(err);
	return err;
}

/*
 * Creates a whiteout for the files existing in a directory
 *  dentry is the unionfs dentry
 *  cur_index is the directory where we will create the whiteouts
 */
int create_dir_whs(struct dentry *dentry, int cur_index)
{
	int err = 0;
	int bindex = 0;
	struct dentry *hidden_dentry = NULL;
	struct dentry *hidden_parent_dentry;
	struct super_block *sb;
	struct file *hidden_file;
	struct unionfs_rdutil_callback buf;
	struct dentry *hidden_dir_dentry;
	char *name = NULL;
	int i;

	print_entry_location();
	fist_print_dentry("IN create_dir_whs: ", dentry);

	hidden_dir_dentry = dtohd(dentry);
	PASSERT(hidden_dir_dentry);

	sb = dentry->d_sb;

	buf.rdstate = alloc_rdstate(dentry->d_inode, cur_index);
	if (!buf.rdstate) {
		err = -ENOMEM;
		goto out;
	}

	/* open all dentries to the right of branch 'cur_index' and do vfs_readdir on them.
	   In the create_dir_whs_filldir() function, for each entry create a whiteout in branch 'cur_index'  */
	for (bindex = cur_index + 1; bindex <= sbend(sb); bindex++) {
		/* Find out hidden parent dentry */
		hidden_parent_dentry = dtohd_index(dentry->d_parent, bindex);

		/* continue if hidden parent doesn't exist */
		if (!hidden_parent_dentry) {
			continue;
		}

		/* lookup underlying file system */
		hidden_dentry =
		    lookup_one_len(dentry->d_name.name, hidden_parent_dentry,
				   dentry->d_name.len);
		if (IS_ERR(hidden_dentry)) {
			err = PTR_ERR(hidden_dentry);
			goto out;
		}

		if (hidden_dentry->d_inode
		    && S_ISDIR(hidden_dentry->d_inode->i_mode)) {
			mntget(stohiddenmnt_index(sb, bindex));
			branchget(sb, bindex);
			hidden_file =
			    dentry_open(hidden_dentry,
					stohiddenmnt_index(sb, bindex),
					O_RDONLY);
			if (IS_ERR(hidden_file)) {
				err = PTR_ERR(hidden_file);
				branchput(sb, bindex);
				goto out;
			}
			/* prepare callback buffer */
			do {
				buf.filldir_called = 0;
				buf.err = 0;
				buf.rdstate->uds_bindex = bindex;
				err =
				    vfs_readdir(hidden_file,
						readdir_util_callback, &buf);
				if (buf.err) {
					err = buf.err;
				}
			} while ((err >= 0) && buf.filldir_called);

			/* fput calls dput for internally */
			fput(hidden_file);
			branchput(sb, bindex);
		} else {
			/* dput the unnecessary negative dentry */
			dput(hidden_dentry);
		}
	}

	/* Now we have assembled a list, so we can go through it. */
	name = (char *)__get_free_page(GFP_UNIONFS);
	if (!name) {
		err = -ENOMEM;
		goto out;
	}

	for (i = 0; i < buf.rdstate->uds_size; i++) {
		struct list_head *pos;
		struct filldir_node *cursor;

		list_for_each(pos, &buf.rdstate->uds_list[i]) {
			cursor =
			    list_entry(pos, struct filldir_node, file_list);
			if (cursor->whiteout)
				continue;

			strcpy(name, ".wh.");
			strncpy(name + 4, cursor->name, PAGE_SIZE - 4);

			hidden_dentry =
			    lookup_one_len(name, hidden_dir_dentry,
					   cursor->namelen + 4);
			if (IS_ERR(hidden_dentry)) {
				err = PTR_ERR(hidden_dentry);
				goto out;
			}

			down(&hidden_dir_dentry->d_inode->i_sem);
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
			err =
			    vfs_create(hidden_dir_dentry->d_inode,
				       hidden_dentry, 0600);
#else
			err =
			    vfs_create(hidden_dir_dentry->d_inode,
				       hidden_dentry, 0600, NULL);
#endif
			up(&hidden_dir_dentry->d_inode->i_sem);
			dput(hidden_dentry);

			if (!err) {
				d_delete(hidden_dentry);
			} else if (!IS_COPYUP_ERR(err)) {
				goto out;
			}
		}
	}
	/* After all of the creations, we should copy the attributes once. */
	fist_copy_attr_times(dentry->d_inode, hidden_dir_dentry->d_inode);

      out:
	if (name) {
		free_page((unsigned long)name);
	}
	if (buf.rdstate) {
		free_rdstate(buf.rdstate);
	}
	fist_print_dentry("OUT create_dir_whs :", dentry);
	print_exit_status(err);
	return err;
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
