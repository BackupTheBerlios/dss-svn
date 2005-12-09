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
 *  $Id: branchman.c,v 1.33 2005/07/18 15:47:05 cwright Exp $
 */

#include "fist.h"
#include "unionfs.h"
#include <linux/dcache.h>
#include <linux/poll.h>

int unionfs_ioctl_branchcount(struct file *file, unsigned int cmd, unsigned long arg)
{
	int err = 0;
	int bstart, bend;
	int i;
	struct super_block *sb = file->f_dentry->d_sb;

	print_entry_location();

	bstart = sbstart(sb);
	bend = sbend(sb);

	err = bend + 1;
	if (!arg) {
		goto out;
	}

	for (i = bstart; i <= bend; i++) {
		if (put_user(branch_count(sb, i), ((int *)arg) + i)) {
			err = -EFAULT;
			goto out;
		}
	}

      out:
	print_exit_status(err);
	return err;
}

int unionfs_ioctl_incgen(struct file *file, unsigned int cmd, unsigned long arg)
{
	int err = 0;
	struct super_block *sb;

	print_entry_location();

	sb = file->f_dentry->d_sb;

	lock_super(sb);

	atomic_inc(&stopd(sb)->usi_generation);
	err = atomic_read(&stopd(sb)->usi_generation);

	atomic_set(&dtopd(sb->s_root)->udi_generation, err);
	atomic_set(&itopd(sb->s_root->d_inode)->uii_generation, err);

	unlock_super(sb);

	print_exit_status(err);

	return err;
}

int unionfs_ioctl_addbranch(struct inode *inode, unsigned int cmd, unsigned long arg)
{
	int err = 0;
	struct unionfs_addbranch_args *addargs = NULL;
	struct nameidata nd;
	char *path = NULL;
	int gen;
	int i;
	int count;

	int pobjects;

	struct vfsmount **new_hidden_mnt = NULL;
	struct inode **new_uii_inode = NULL;
	struct dentry **new_udi_dentry = NULL;
	struct super_block **new_usi_sb = NULL;
	int *new_branchperms = NULL;
	atomic_t *new_counts = NULL;

	print_entry_location();

	lock_super(inode->i_sb);

	addargs = KMALLOC(sizeof(struct unionfs_addbranch_args), GFP_UNIONFS);
	if (!addargs) {
		err = -ENOMEM;
		goto out;
	}

	if (copy_from_user
	    (addargs, (void *)arg, sizeof(struct unionfs_addbranch_args))) {
		err = -EFAULT;
		goto out;
	}

	if (addargs->ab_perms & ~(MAY_READ | MAY_WRITE)) {
		err = -EINVAL;
		goto out;
	}
	if (!(addargs->ab_perms & MAY_READ)) {
		err = -EINVAL;
		goto out;
	}

	if (addargs->ab_branch < 0
	    || (addargs->ab_branch > (sbend(inode->i_sb) + 1))) {
		err = -EINVAL;
		goto out;
	}

	if (sbend(inode->i_sb) > FD_SETSIZE) {
		err = -E2BIG;
		goto out;
	}

	path = getname(addargs->ab_path);
	if (!path) {
		err = -ENOMEM;
		goto out;
	}
//DQ: 2.6 has a different way of doing this
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
	/* Look it up */
	if (path_init(path, LOOKUP_FOLLOW, &nd))
		err = path_walk(path, &nd);
#else
	err = path_lookup(path, LOOKUP_FOLLOW, &nd);
#endif
	if (err)
		goto out;
	if (!nd.dentry->d_inode) {
		path_release(&nd);
		err = -ENOENT;
		goto out;
	}
	if (!S_ISDIR(nd.dentry->d_inode->i_mode)) {
		path_release(&nd);
		err = -ENOTDIR;
		goto out;
	}

	stopd(inode->i_sb)->b_end++;
	dtopd(inode->i_sb->s_root)->udi_bcount++;
	set_dbend(inode->i_sb->s_root, dbend(inode->i_sb->s_root) + 1);
	itopd(inode->i_sb->s_root->d_inode)->b_end++;

	atomic_inc(&stopd(inode->i_sb)->usi_generation);
	gen = atomic_read(&stopd(inode->i_sb)->usi_generation);

	pobjects = (sbend(inode->i_sb) + 1) - UNIONFS_INLINE_OBJECTS;
	if (pobjects > 0) {
		/* Reallocate the dynamic structures. */
		new_hidden_mnt =
		    KMALLOC(sizeof(struct hidden_mnt *) * pobjects,
			    GFP_UNIONFS);
		new_udi_dentry =
		    KMALLOC(sizeof(struct dentry *) * pobjects, GFP_UNIONFS);
		new_uii_inode =
		    KMALLOC(sizeof(struct inode *) * pobjects, GFP_UNIONFS);
		new_usi_sb =
		    KMALLOC(sizeof(struct super_block *) * pobjects,
			    GFP_UNIONFS);
		new_counts = KMALLOC(sizeof(atomic_t) * pobjects, GFP_UNIONFS);
		new_branchperms = KMALLOC(sizeof(int) * pobjects, GFP_UNIONFS);
		if (!new_hidden_mnt || !new_udi_dentry || !new_uii_inode
		    || !new_counts || !new_usi_sb || !new_branchperms) {
			err = -ENOMEM;
			goto out;
		}
	}

	/* Copy the in-place values to our new structure. */
	for (i = UNIONFS_INLINE_OBJECTS; i < addargs->ab_branch; i++) {
		int j = i - UNIONFS_INLINE_OBJECTS;

		count = branch_count(inode->i_sb, i);
		atomic_set(&(new_counts[j]), count);

		new_branchperms[j] = branchperms(inode->i_sb, i);
		new_hidden_mnt[j] = stohiddenmnt_index(inode->i_sb, i);

		new_usi_sb[j] = stohs_index(inode->i_sb, i);
		new_udi_dentry[j] = dtohd_index(inode->i_sb->s_root, i);
		new_uii_inode[j] = itohi_index(inode->i_sb->s_root->d_inode, i);
	}

	/* Shift the ends to the right (only handle reallocated bits). */
	for (i = sbend(inode->i_sb) - 1; i >= (int)addargs->ab_branch; i--) {
		int j = i + 1;
		int perms;
		struct vfsmount *hm;
		struct super_block *hs;
		struct dentry *hd;
		struct inode *hi;

		count = branch_count(inode->i_sb, i);
		perms = branchperms(inode->i_sb, i);
		hm = stohiddenmnt_index(inode->i_sb, i);
		hs = stohs_index(inode->i_sb, i);
		hd = dtohd_index(inode->i_sb->s_root, i);
		hi = itohi_index(inode->i_sb->s_root->d_inode, i);

		if (j >= UNIONFS_INLINE_OBJECTS) {
			j -= UNIONFS_INLINE_OBJECTS;
			atomic_set(&(new_counts[j]), count);
			new_branchperms[j] = perms;
			new_hidden_mnt[j] = hm;
			new_usi_sb[j] = hs;
			new_udi_dentry[j] = hd;
			new_uii_inode[j] = hi;
		} else {
			set_branch_count(inode->i_sb, j, count);
			set_branchperms(inode->i_sb, j, perms);
			set_stohiddenmnt_index(inode->i_sb, j, hm);
			set_stohs_index(inode->i_sb, j, hs);
			set_dtohd_index(inode->i_sb->s_root, j, hd);
			set_itohi_index(inode->i_sb->s_root->d_inode, j, hi);
		}
	}

	/* Now we can free the old ones. */
	KFREE(dtopd(inode->i_sb->s_root)->udi_dentry_p);
	KFREE(itopd(inode->i_sb->s_root->d_inode)->uii_inode_p);
	KFREE(stopd(inode->i_sb)->usi_hidden_mnt_p);
	KFREE(stopd(inode->i_sb)->usi_sb_p);
	KFREE(stopd(inode->i_sb)->usi_branchperms_p);

	/* Update the real pointers. */
	dtohd_ptr(inode->i_sb->s_root) = new_udi_dentry;
	itohi_ptr(inode->i_sb->s_root->d_inode) = new_uii_inode;
	stohiddenmnt_ptr(inode->i_sb) = new_hidden_mnt;
	stohs_ptr(inode->i_sb) = new_usi_sb;
	stopd(inode->i_sb)->usi_sbcount_p = new_counts;
	stopd(inode->i_sb)->usi_branchperms_p = new_branchperms;

	/* Re-NULL the new ones so we don't try to free them. */
	new_hidden_mnt = NULL;
	new_udi_dentry = NULL;
	new_usi_sb = NULL;
	new_uii_inode = NULL;
	new_counts = NULL;
	new_branchperms = NULL;

	/* Put the new dentry information into it's slot. */
	set_dtohd_index(inode->i_sb->s_root, addargs->ab_branch, nd.dentry);
	set_itohi_index(inode->i_sb->s_root->d_inode, addargs->ab_branch,
			igrab(nd.dentry->d_inode));
	set_branchperms(inode->i_sb, addargs->ab_branch, addargs->ab_perms);
	set_branch_count(inode->i_sb, addargs->ab_branch, 0);
	set_stohiddenmnt_index(inode->i_sb, addargs->ab_branch, nd.mnt);
	set_stohs_index(inode->i_sb, addargs->ab_branch, nd.dentry->d_sb);

	atomic_set(&dtopd(inode->i_sb->s_root)->udi_generation, gen);
	atomic_set(&itopd(inode->i_sb->s_root->d_inode)->uii_generation, gen);

      out:
	unlock_super(inode->i_sb);

	KFREE(new_hidden_mnt);
	KFREE(new_udi_dentry);
	KFREE(new_uii_inode);
	KFREE(new_usi_sb);
	KFREE(new_counts);
	KFREE(new_branchperms);
	KFREE(addargs);
	if (path)
		putname(path);

	print_exit_status(err);

	return err;
}

int unionfs_ioctl_delbranch(struct inode *inode, unsigned int cmd, unsigned long arg)
{
	struct dentry *hidden_dentry;
	struct inode *hidden_inode;
	struct super_block *hidden_sb;
	struct vfsmount *hidden_mnt;
	struct dentry *root_dentry;
	struct inode *root_inode;
	int err = 0;
	int i;
	int gen;

	print_entry("branch = %lu ", arg);	/* Delete a branch. */

	lock_super(inode->i_sb);

	if (sbmax(inode->i_sb) == 1) {
		err = -EBUSY;
		goto out;
	}
	if (arg < 0 || arg > stopd(inode->i_sb)->b_end) {
		err = -EINVAL;
		goto out;
	}
	if (branch_count(inode->i_sb, arg)) {
		err = -EBUSY;
		goto out;
	}

	atomic_inc(&stopd(inode->i_sb)->usi_generation);
	gen = atomic_read(&stopd(inode->i_sb)->usi_generation);

	root_dentry = inode->i_sb->s_root;
	root_inode = inode->i_sb->s_root->d_inode;

	hidden_dentry = dtohd_index(root_dentry, arg);
	hidden_mnt = stohiddenmnt_index(inode->i_sb, arg);
	hidden_inode = itohi_index(root_inode, arg);
	hidden_sb = stohs_index(inode->i_sb, arg);

	dput(hidden_dentry);
	iput(hidden_inode);
	mntput(hidden_mnt);
	//XXX: Leak! put_super(hidden_sb);

	for (i = arg; i <= (sbend(inode->i_sb) - 1); i++) {
		set_branch_count(inode->i_sb, i,
				 branch_count(inode->i_sb, i + 1));
		set_stohiddenmnt_index(inode->i_sb, i,
				       stohiddenmnt_index(inode->i_sb, i + 1));
		set_stohs_index(inode->i_sb, i,
				stohs_index(inode->i_sb, i + 1));
		set_branchperms(inode->i_sb, i,
				branchperms(inode->i_sb, i + 1));
		set_dtohd_index(root_dentry, i,
				dtohd_index(root_dentry, i + 1));
		set_itohi_index(root_inode, i, itohi_index(root_inode, i + 1));
	}

	set_dtohd_index(root_dentry, sbend(inode->i_sb), NULL);
	set_itohi_index(root_inode, sbend(inode->i_sb), NULL);
	set_stohiddenmnt_index(inode->i_sb, sbend(inode->i_sb), NULL);
	set_stohs_index(inode->i_sb, sbend(inode->i_sb), NULL);

	stopd(inode->i_sb)->b_end--;
	set_dbend(root_dentry, dbend(root_dentry) - 1);
	dtopd(root_dentry)->udi_bcount--;
	itopd(root_inode)->b_end--;

	atomic_set(&dtopd(root_dentry)->udi_generation, gen);
	atomic_set(&itopd(root_inode)->uii_generation, gen);

      out:
	unlock_super(inode->i_sb);

	print_exit_status(err);

	return err;
}

int unionfs_ioctl_rdwrbranch(struct inode *inode, unsigned int cmd, unsigned long arg)
{
	int err = 0;
	struct unionfs_rdwrbranch_args *rdwrargs = NULL;
	int gen;

	print_entry_location();

	lock_super(inode->i_sb);

	rdwrargs = KMALLOC(sizeof(struct unionfs_rdwrbranch_args), GFP_UNIONFS);
	if (!rdwrargs) {
		err = -ENOMEM;
		goto out;
	}

	if (copy_from_user
	    (rdwrargs, (void *)arg, sizeof(struct unionfs_rdwrbranch_args))) {
		err = -EFAULT;
		goto out;
	}

	if (rdwrargs->rwb_branch < 0
	    || (rdwrargs->rwb_branch > (sbend(inode->i_sb) + 1))) {
		err = -EINVAL;
		goto out;
	}

	if (rdwrargs->rwb_perms & ~(MAY_READ | MAY_WRITE)) {
		err = -EINVAL;
		goto out;
	}
	if (!(rdwrargs->rwb_perms & MAY_READ)) {
		err = -EINVAL;
		goto out;
	}

	set_branchperms(inode->i_sb, rdwrargs->rwb_branch, rdwrargs->rwb_perms);

	atomic_inc(&stopd(inode->i_sb)->usi_generation);
	gen = atomic_read(&stopd(inode->i_sb)->usi_generation);
	atomic_set(&dtopd(inode->i_sb->s_root)->udi_generation, gen);
	atomic_set(&itopd(inode->i_sb->s_root->d_inode)->uii_generation, gen);

      out:
	unlock_super(inode->i_sb);
	if (rdwrargs) {
		KFREE(rdwrargs);
	}

	print_exit_status(err);

	return err;
}

/* This is a horribly broken interface! */
int unionfs_ioctl_queryfile(struct inode *inode, unsigned int cmd, unsigned long arg)
{
	int err = 0;
	struct unionfs_queryfile_args queryargs;
	int len = 0;
	char *filename = NULL;
	unsigned long k = 0;
	int size = 0;

	int bstart = 0, bend = 0, bindex = 0;
	struct dentry *dentry, *hidden_dentry;
	struct dentry *parent_dentry, *hidden_parent_dentry;

	unsigned long *fdout = NULL;
	char *bits = NULL;

	struct nameidata nd;

	print_entry_location();

	if (copy_from_user
	    (&queryargs, (void *)arg, sizeof(struct unionfs_queryfile_args))) {
		err = -EFAULT;
		goto out;
	}

	if (!queryargs.filename) {
		err = -EFAULT;
		goto out;
	}

	len = strlen_user(queryargs.filename);
	if (!len) {
		err = -EFAULT;
		goto out;
	}

	filename = KMALLOC(len + 1, GFP_UNIONFS);
	if (!filename) {
		err = -ENOMEM;
		goto out;
	}

	err = strncpy_from_user(filename, queryargs.filename, len);
	if (err < 0)
		goto out;

	size = FDS_BYTES(sbend(inode->i_sb) + 1);
	bits = KMALLOC(size, GFP_UNIONFS);
	if (!bits) {
		err = -ENOMEM;
		goto out;
	}

	if (err ==
	    get_fd_set(len + 1, &queryargs.branchlist, (unsigned long *)bits))
		goto out;

	lock_super(inode->i_sb);

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
	/* Look it up */
	if (path_init(filename, LOOKUP_FOLLOW, &nd))
		err = path_walk(filename, &nd);
#else
	err = path_lookup(filename, LOOKUP_FOLLOW, &nd);
#endif
	if (err)
		goto out;

	dentry = nd.dentry;
	parent_dentry = dentry->d_parent;
	bstart = dbstart(parent_dentry);
	bend = dbend(parent_dentry);

	fdout = (unsigned long *)bits;
	k = 0x00000001;
	*fdout = 0x00;
	for (bindex = bstart; bindex <= bend; bindex++) {
		hidden_parent_dentry = dtohd_index(parent_dentry, bindex);
		if (!hidden_parent_dentry || IS_ERR(hidden_parent_dentry)) {
			err = PTR_ERR(hidden_parent_dentry);
			goto out;
		}
		if (!hidden_parent_dentry->d_inode)
			continue;

		hidden_dentry =
		    lookup_one_len(dentry->d_name.name, hidden_parent_dentry,
				   dentry->d_name.len);
		if (!hidden_dentry || IS_ERR(hidden_dentry)) {
			err = PTR_ERR(hidden_dentry);
			goto out;
		}
		if (!hidden_dentry->d_inode) {
			k = k << 1;
			dput(hidden_dentry);
			continue;
		}

		if (k == 0) {
			k = 0x00000001;
			fdout++;
			*fdout = 0x00;
		}
		*fdout |= k;
		k = k << 1;
		dput(hidden_dentry);

	}

	dput(nd.dentry);
	mntput(nd.mnt);

	err =
	    copy_to_user(&((struct unionfs_queryfile_args *)arg)->branchlist,
			 bits, size);
	if (err) {
		err = -EFAULT;
		goto out;
	}

      out:
	unlock_super(inode->i_sb);
	KFREE(filename);
	KFREE(bits);

	err = err < 0 ? err : bend;
	print_exit_status(err);
	return (err);
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
