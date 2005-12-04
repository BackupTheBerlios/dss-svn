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
 *  $Id: subr.c,v 1.107 2005/07/18 15:03:18 cwright Exp $
 */

#include "fist.h"
#include "unionfs.h"

/* Pass an unionfs dentry and an index.  It will try to create a whiteout
 * for the filename in dentry, and will try in branch 'index'.  On error,
 * it will proceed to a branch to the left.
 */
int create_whiteout(struct dentry *dentry, int start)
{
	int bstart, bend, bindex;
	struct dentry *hidden_dir_dentry;
	struct dentry *hidden_dentry;
	struct dentry *hidden_wh_dentry;
	char *name = NULL;
	int err = -EINVAL;

	print_entry_location();

	PASSERT(dentry);
	PASSERT(dentry->d_parent);

	fist_print_dentry("IN create_whiteout", dentry);
	bstart = dbstart(dentry);
	bend = dbend(dentry);

	/* create dentry's whiteout equivalent */
	name = KMALLOC(sizeof(char) * (dentry->d_name.len + 5), GFP_UNIONFS);
	if (!name) {
		err = -ENOMEM;
		goto out;
	}
	strcpy(name, ".wh.");
	strncat(name, dentry->d_name.name, dentry->d_name.len);
	name[dentry->d_name.len + 4] = '\0';

	/* create foo then rename it to .wh.foo, on error move to the left. */
	for (bindex = start; bindex >= 0; bindex--) {
		hidden_dentry = dtohd_index(dentry, bindex);

		if (!hidden_dentry) {
			/* if hidden dentry is not present, create the entire
			 * hidden dentry directory structure and go ahead.
			 * Since we want to just create whiteout, we only want
			 * the parent dentry, and hence get rid of this dentry.
			 */
			hidden_dentry = unionfs_create_dirs(dentry->d_inode,
							    dentry, bindex);
			if (!hidden_dentry || IS_ERR(hidden_dentry)) {
				fist_dprint(8,
					    "hidden dentry NULL for bindex = %d\n",
					    bindex);
				continue;
			}
		}
		hidden_wh_dentry =
		    lookup_one_len(name, hidden_dentry->d_parent,
				   dentry->d_name.len + 4);

		if (!hidden_wh_dentry || IS_ERR(hidden_wh_dentry))
			continue;
		ASSERT(!hidden_wh_dentry->d_inode);

		hidden_dir_dentry = lock_parent(hidden_wh_dentry);
		if (!(err = is_robranch_super(dentry->d_sb, bindex))) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
			err =
			    vfs_create(hidden_dir_dentry->d_inode,
				       hidden_wh_dentry,
				       ~current->fs->umask & S_IRWXUGO);
#else
			err =
			    vfs_create(hidden_dir_dentry->d_inode,
				       hidden_wh_dentry,
				       ~current->fs->umask & S_IRWXUGO, NULL);

#endif
		}
		unlock_dir(hidden_dir_dentry);
		dput(hidden_wh_dentry);

		if (!err)
			break;

		if (IS_SET(dentry->d_sb, GLOBAL_ERR_PASSUP))
			goto out;

		if (!IS_COPYUP_ERR(err))
			break;
	}

	/* set dbopaque  so that lookup will not proceed after this branch */
	if (!err)
		set_dbopaque(dentry->d_parent, bindex);

	fist_print_dentry("OUT create_whiteout", dentry);
      out:
	if (name) {
		KFREE(name);
	}
	print_exit_status(err);
	return err;
}

/* Create a whiteout for filename in parent starting in branch start. */
int create_whiteout_parent(struct dentry *parent_dentry, const char *filename,
			   int start)
{
	int bindex;
	int old_bstart, old_bend;
	struct dentry *hidden_dir_dentry;
	struct dentry *hidden_grand_parent_dentry;
	struct dentry *hidden_parent_dentry;
	struct dentry *hidden_wh_dentry;
	char *name = NULL;
	int err = -EINVAL;

	print_entry_location();

	PASSERT(parent_dentry);
	old_bstart = dbstart(parent_dentry);
	old_bend = dbend(parent_dentry);

	fist_print_dentry("IN create_whiteout_parent", parent_dentry);

	/* create dentry's whiteout equivalent */
	name = KMALLOC(sizeof(char) * (strlen(filename) + 5), GFP_UNIONFS);
	if (!name) {
		err = -ENOMEM;
		goto out;
	}
	strcpy(name, ".wh.");
	strncat(name, filename, strlen(filename));
	name[strlen(filename) + 4] = '\0';

	for (bindex = start; bindex >= 0; bindex--) {
		hidden_parent_dentry = dtohd_index(parent_dentry, bindex);

		if (!hidden_parent_dentry) {
			/* create the recursive directory structure and return
			 * the negative dentry for the parent where we want to
			 * create whiteout. */
			ASSERT(parent_dentry->d_inode != NULL);
			hidden_parent_dentry =
			    unionfs_create_dirs(parent_dentry->d_inode,
						parent_dentry, bindex);
			if (!hidden_parent_dentry
			    || IS_ERR(hidden_parent_dentry)) {
				fist_dprint(8,
					    "hidden dentry NULL for bindex = %d\n",
					    bindex);
				continue;
			}

			/* create directory of the hidden parent, 
			 * if it is negative.
			 * This is where whiteout is created
			 */
			hidden_grand_parent_dentry =
			    lock_parent(hidden_parent_dentry);
			PASSERT(hidden_grand_parent_dentry->d_inode);

			/* We shouldn't create things in a read-only branch. */
			if (!
			    (err =
			     is_robranch_super(parent_dentry->d_sb, bindex)))
				err =
				    vfs_mkdir(hidden_grand_parent_dentry->
					      d_inode, hidden_parent_dentry,
					      S_IRWXU);

			unlock_dir(hidden_grand_parent_dentry);
			if (err || !hidden_parent_dentry->d_inode) {
				dput(hidden_parent_dentry);
				/* if error, we need to revert back the old bstart and bend for this
				 * parent and return back
				 */
				set_dbstart(parent_dentry, old_bstart);
				set_dbend(parent_dentry, old_bend);
				set_dtohd_index(parent_dentry, bindex, NULL);

				if (IS_SET
				    (parent_dentry->d_sb, GLOBAL_ERR_PASSUP))
					goto out;
				/* break out of for loop if error returned was NOT -EROFS */
				if (!IS_COPYUP_ERR(err))
					break;
				continue;
			}
			set_itohi_index(parent_dentry->d_inode, bindex,
					igrab(hidden_parent_dentry->d_inode));
		}

		/* lookup for the whiteout dentry that we want to create */
		hidden_wh_dentry =
		    lookup_one_len(name, hidden_parent_dentry,
				   strlen(filename) + 4);
		if (!hidden_wh_dentry || IS_ERR(hidden_wh_dentry))
			continue;
		ASSERT(!hidden_wh_dentry->d_inode);

		/* hidden_dir_dentry and hidden_parent_dentry 
		 * are going to be the same */
		hidden_dir_dentry = lock_parent(hidden_wh_dentry);

		/* We shouldn't create things in a read-only branch. */
		if (!(err = is_robranch_super(parent_dentry->d_sb, bindex))) {
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
			err =
			    vfs_create(hidden_dir_dentry->d_inode,
				       hidden_wh_dentry,
				       ~current->fs->umask & S_IRWXUGO);
#else
			err =
			    vfs_create(hidden_dir_dentry->d_inode,
				       hidden_wh_dentry,
				       ~current->fs->umask & S_IRWXUGO, NULL);
#endif
		}

		unlock_dir(hidden_dir_dentry);
		dput(hidden_wh_dentry);

		if (!err)
			break;
		if (IS_SET(parent_dentry->d_sb, GLOBAL_ERR_PASSUP))
			goto out;
		if (!IS_COPYUP_ERR(err))
			break;
	}

	/* set dbopaque so that lookup will not proceed after this branch */
	if (!err)
		set_dbopaque(parent_dentry->d_parent, bindex);

      out:
	fist_print_dentry("OUT create_whiteout", parent_dentry);
	if (name) {
		KFREE(name);
	}
	print_exit_status(err);
	return err;
}

/* This is a helper function for rename, which ends up with hosed over dentries
 * when it needs to revert. */
int unionfs_refresh_hidden_dentry(struct dentry *dentry, int bindex)
{
	struct dentry *hidden_dentry;
	struct dentry *hidden_parent;
	int err = 0;

	print_entry(" bindex = %d", bindex);

	hidden_parent = dtohd_index(dentry->d_parent, bindex);

	PASSERT(hidden_parent);
	PASSERT(hidden_parent->d_inode);
	ASSERT(S_ISDIR(hidden_parent->d_inode->i_mode));

	hidden_dentry =
	    lookup_one_len(dentry->d_name.name, hidden_parent,
			   dentry->d_name.len);
	if (IS_ERR(hidden_dentry)) {
		err = PTR_ERR(hidden_dentry);
		goto out;
	}

	if (dtohd_index(dentry, bindex))
		dput(dtohd_index(dentry, bindex));
	if (itohi_index(dentry->d_inode, bindex)) {
		iput(itohi_index(dentry->d_inode, bindex));
		set_itohi_index(dentry->d_inode, bindex, NULL);
	}
	if (!hidden_dentry->d_inode) {
		dput(hidden_dentry);
		set_dtohd_index(dentry, bindex, NULL);
	} else {
		set_dtohd_index(dentry, bindex, hidden_dentry);
		set_itohi_index(dentry->d_inode, bindex,
				igrab(hidden_dentry->d_inode));
	}

      out:
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
