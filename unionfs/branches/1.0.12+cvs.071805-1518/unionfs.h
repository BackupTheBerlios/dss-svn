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
 *  $Id: unionfs.h,v 1.131 2005/07/18 15:47:05 cwright Exp $
 */

#ifndef __UNIONFS_H_
#define __UNIONFS_H_

#ifdef __KERNEL__

#if (!defined(UNIONFS_UNSUPPORTED)) &&(LINUX_VERSION_CODE < KERNEL_VERSION(2,4,20)) || (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,0) && LINUX_VERSION_CODE < KERNEL_VERSION(2,6,9))
#warning You are compiling Unionfs on an unsupported kernel version.
#warning To compile Unionfs, you will need to define UNIONFS_UNSUPPORTED.
#warning Try adding: EXTRACFLAGS=-DUNIONFS_UNSUPPORTED to fistdev.mk
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,0)
#include <linux/spinlock.h>
#define wq_write_lock_irqsave(lock,flags) spin_lock_irqsave(lock,flags)
#define wq_write_unlock(lock) spin_unlock(lock)
#define wq_write_lock_irq(lock) spin_lock_irq(lock)
#define wq_write_unlock_irqrestore(lock,flags) spin_unlock_irqrestore(lock,flags)
#endif

/* number of characters while generating unique temporary file names */
#define	UNIONFS_TMPNAM_LEN	12

/* fist file systems superblock magic */
#define UNIONFS_SUPER_MAGIC 0xf15f083d

/* unionfs root inode number */
#define UNIONFS_ROOT_INO     1

/* Mount time flags */
#define MOUNT_FLAG(sb)     (stopd(sb)->usi_mount_flag)

/* What type of flags to use for kmalloc, etc. */
#define GFP_UNIONFS GFP_KERNEL

/*UUID typedef needed later*/
typedef uint8_t uuid_t[16];

/* A lock structure that a single task can lock N times and then unlock N times. */
struct multilock {
	spinlock_t ml_protect;
	struct task_struct *ml_locker;
	int ml_depth;
	wait_queue_head_t ml_sleepers;
};

static inline void multilock_init(struct multilock *ml)
{
#ifdef MULTILOCK_TRACK
	printk("MLI:%p\n", ml);
#endif
	ml->ml_protect = SPIN_LOCK_UNLOCKED;
	ml->ml_locker = NULL;
	ml->ml_depth = 0;
	init_waitqueue_head(&ml->ml_sleepers);
}

#define multilock_lock(ml) __multilock_lock((ml), __FILE__, __FUNCTION__, __LINE__)
static inline void __multilock_lock(struct multilock *ml, const char *file,
				    const char *function, int line)
{

#ifdef MULTILOCK_TRACK
	printk("ILK:%d:%p:%d (%s:%d)\n", current->pid, ml, ml->ml_depth,
	       function, line);
#endif

      retry:
	spin_lock(&ml->ml_protect);
	if (ml->ml_locker == NULL) {
		ml->ml_locker = current;
		ml->ml_depth = 1;
	} else if (ml->ml_locker == current) {
		ml->ml_depth++;
	} else {
		/* SLEEP_ON_VAR */
		wait_queue_t wait;
		unsigned long flags;
		init_waitqueue_entry(&wait, current);

		/* We want to go to sleep */
		current->state = TASK_UNINTERRUPTIBLE;

		/* SLEEP_ON_HEAD */
		wq_write_lock_irqsave(&ml->ml_sleepers.lock, flags);
		__add_wait_queue(&ml->ml_sleepers, &wait);
		wq_write_unlock(&ml->ml_sleepers.lock);

		/* This line is why we can't use sleep_on, because we need to save our queue. */
		spin_unlock(&ml->ml_protect);

		schedule();

		/* SLEEP_ON_TAIL */
		wq_write_lock_irq(&ml->ml_sleepers.lock);
		__remove_wait_queue(&ml->ml_sleepers, &wait);
		wq_write_unlock_irqrestore(&ml->ml_sleepers.lock, flags);
		goto retry;
	}
	spin_unlock(&ml->ml_protect);

#ifdef MULTILOCK_TRACK
	printk("OLK:%d:%p:%d\n", current->pid, ml, ml->ml_depth);
#endif
}

#define multilock_unlock(ml) __multilock_unlock((ml), __FILE__, __FUNCTION__, __LINE__)
static inline void __multilock_unlock(struct multilock *ml, const char *file,
				      const char *function, int line)
{
#ifdef MULTILOCK_TRACK
	printk("IUL:%d:%p:%d (%s:%d)\n", current->pid, ml, ml->ml_depth,
	       function, line);
#endif
	spin_lock(&ml->ml_protect);
	ASSERT2(ml->ml_depth > 0);
	ASSERT2(ml->ml_locker == current);
	ml->ml_depth--;
	if (ml->ml_depth == 0) {
		ml->ml_locker = NULL;
		wake_up(&ml->ml_sleepers);
	}
	spin_unlock(&ml->ml_protect);
#ifdef MULTILOCK_TRACK
	printk("OUL:%d:%p:%d\n", current->pid, ml, ml->ml_depth);
#endif
}

/* Operations vectors defined in specific files. */
extern struct file_operations unionfs_main_fops;
extern struct file_operations unionfs_dir_fops;
extern struct inode_operations unionfs_main_iops;
extern struct inode_operations unionfs_dir_iops;
extern struct inode_operations unionfs_symlink_iops;
extern struct super_operations unionfs_sops;
extern struct dentry_operations unionfs_dops;
extern struct export_operations unionfs_export_ops;

/* How many dentries, inodes, and other things should be stuck directly int our
 * unionfs structures without an intervening KMALLOC? */
#ifndef UNIONFS_INLINE_OBJECTS
#define UNIONFS_INLINE_OBJECTS 0
#endif

/* How long should an entry be allowed to persist */
#define RDCACHE_JIFFIES 5*HZ
/* unionfs inode data in memory */
struct unionfs_inode_info {
	int b_start;
	int b_end;
	atomic_t uii_generation;
	int uii_stale;
	/* Stuff for readdir over NFS. */
	spinlock_t uii_rdlock;
	struct list_head uii_readdircache;
	int uii_rdcount;
	int uii_hashsize;
	int uii_cookie;
	/* The hidden inodes */
	struct inode *uii_inode_i[UNIONFS_INLINE_OBJECTS];
	struct inode **uii_inode_p;
	/* to keep track of reads/writes for unlinks before closes */
	atomic_t uii_totalopens;
	atomic_t uii_writeopens;
};
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,0)
struct unionfs_inode_container {
	struct unionfs_inode_info info;
	struct inode vfs_inode;
};
#endif

/* unionfs dentry data in memory */
struct unionfs_dentry_info {
	struct multilock udi_lock;
	int udi_bstart;
	int udi_bend;
	int udi_bopaque;
	int udi_bcount;
	atomic_t udi_generation;
	struct dentry *udi_dentry_i[UNIONFS_INLINE_OBJECTS];
	struct dentry **udi_dentry_p;
};

/* unionfs super-block data in memory */
struct unionfs_sb_info {
	int b_start;
	int b_end;

	uid_t copyupuid;
	gid_t copyupgid;
	umode_t copyupmode;

	atomic_t usi_generation;
	unsigned long usi_mount_flag;

	int usi_diropaque;
	int usi_persistent;

	/* These will need a lock. */
	uint64_t usi_next_avail;
	uint8_t usi_num_bmapents;
	uuid_t *usi_bmap;
	struct file *usi_forwardmap;
	struct file **usi_reversemaps;
	struct file **usi_map_table;
	int *usi_fsnum_table;	//This is a table of fsnums to branches.
	int *usi_bnum_table;	//This is a table of branches to fsnums.
	struct super_block *usi_sb_i[UNIONFS_INLINE_OBJECTS];
	atomic_t usi_sbcount_i[UNIONFS_INLINE_OBJECTS];
	struct vfsmount *usi_hidden_mnt_i[UNIONFS_INLINE_OBJECTS];
	int usi_branchperms_i[UNIONFS_INLINE_OBJECTS];

	struct super_block **usi_sb_p;
	atomic_t *usi_sbcount_p;
	struct vfsmount **usi_hidden_mnt_p;
	int *usi_branchperms_p;
};

/*
 * structure for making the linked list of entries by readdir on left branch
 * to compare with entries on right branch
 */
struct filldir_node {
	struct list_head file_list;	// list for directory entries
	char *name;		// name entry
	int hash;		// name hash
	int namelen;		// name len since name is not 0 terminated
	int bindex;		// we can check for duplicate whiteouts and files in the same branch in order to return -EIO.
	int whiteout;		// is this a whiteout entry?
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
#define DNAME_INLINE_LEN_MIN DNAME_INLINE_LEN
#endif
	char iname[DNAME_INLINE_LEN_MIN];	// Inline name, so we don't need to separately kmalloc small ones
};

/* Cache creation/deletion routines. */
void destroy_filldir_cache(void);
int init_filldir_cache(void);
int init_inode_cache(void);
void destroy_inode_cache(void);
int init_dentry_cache(void);
void destroy_dentry_cache(void);

/* Initialize and free readdir-specific  state. */
int init_rdstate(struct file *file);
struct unionfs_dir_state *alloc_rdstate(struct inode *inode, int bindex);
struct unionfs_dir_state *find_rdstate(struct inode *inode, loff_t fpos);
void free_rdstate(struct unionfs_dir_state *state);
int add_filldir_node(struct unionfs_dir_state *rdstate, const char *name,
		     int namelen, int bindex, int whiteout);
struct filldir_node *find_filldir_node(struct unionfs_dir_state *rdstate,
				       const char *name, int namelen);

/* Directory hash table. */
struct unionfs_dir_state {
	unsigned int uds_cookie;	/* The cookie, which is based off of uii_rdversion */
	unsigned int uds_offset;	/* The entry we have returned. */
	int uds_bindex;
	loff_t uds_dirpos;	/* The offset within the lower level directory. */
	int uds_size;		/* How big is the hash table? */
	int uds_hashentries;	/* How many entries have been inserted? */
	unsigned long uds_access;
	/* This cache list is used when the inode keeps us around. */
	struct list_head uds_cache;
	struct list_head uds_list[0];
};
/* We can only use 32-bits of offset for rdstate --- blech! */
#define DIREOF (0xfffff)
#define RDOFFBITS 20		/* This is the number of bits in DIREOF. */
#define MAXRDCOOKIE (0xfff)
/* Turn an rdstate into an offset. */
static inline off_t rdstate2offset(struct unionfs_dir_state *buf)
{
	off_t tmp;
	tmp =
	    ((buf->uds_cookie & MAXRDCOOKIE) << RDOFFBITS) | (buf->
							      uds_offset &
							      DIREOF);
	return tmp;
}

/* file private data. */
struct unionfs_file_info {
	int b_start;
	int b_end;
	atomic_t ufi_generation;

	struct unionfs_dir_state *rdstate;
	struct file *ufi_file_i[UNIONFS_INLINE_OBJECTS];
	struct file **ufi_file_p;
};

/* File to private Data */
#define ftopd(file) ((struct unionfs_file_info *)((file)->private_data))
#define ftopd_lhs(file) ((file)->private_data)
#define ftohf_ptr(file)  (ftopd(file)->ufi_file_p)
#define ftohf_inline(file)  (ftopd(file)->ufi_file_i)
#define fbstart(file) (ftopd(file)->b_start)
#define fbend(file) (ftopd(file)->b_end)

/* Inode to private data */
#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,6,0)
#define itopd(ino) ((struct unionfs_inode_info *)(ino)->u.generic_ip)
#define itopd_lhs(ino) ((ino)->u.generic_ip)
#else
static inline struct unionfs_inode_info *itopd(const struct inode *inode)
{
	return
	    &(container_of(inode, struct unionfs_inode_container, vfs_inode)->
	      info);
}
#endif
#define itohi_ptr(ino) (itopd(ino)->uii_inode_p)
#define itohi_inline(ino) (itopd(ino)->uii_inode_i)
#define ibstart(ino) (itopd(ino)->b_start)
#define ibend(ino) (itopd(ino)->b_end)

/* Superblock to private data */
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
#define stopd(super) ((struct unionfs_sb_info *)(super)->u.generic_sbp)
#define stopd_lhs(super) ((super)->u.generic_sbp)
#else
#define stopd(super) ((struct unionfs_sb_info *)(super)->s_fs_info)
#define stopd_lhs(super) ((super)->s_fs_info)
#endif
#define sbstart(sb) stopd(sb)->b_start
#define sbend(sb) stopd(sb)->b_end
#define sbmax(sb) (stopd(sb)->b_end + 1)
#define stohs_ptr(super) (stopd(super)->usi_sb_p)
#define stohs_inline(super) (stopd(super)->usi_sb_i)
#define stohiddenmnt_ptr(super) (stopd(super)->usi_hidden_mnt_p)
#define stohiddenmnt_inline(super) (stopd(super)->usi_hidden_mnt_i)

/* Macros for locking a dentry. */
#define lock_dpd(dentry) multilock_lock(&dtopd(dentry)->udi_lock)
#define unlock_dpd(dentry) multilock_unlock(&dtopd(dentry)->udi_lock)
#define lock_dpd2(dentry) __multilock_lock(&dtopd(dentry)->udi_lock, file, function, line)
#define unlock_dpd2(dentry) __multilock_unlock(&dtopd(dentry)->udi_lock, file, function, line)

/* The NODEBUG versions are defines, the debug versions are inline functions
 * with extra checks. */
#ifdef NODEBUG
#include "unionfs_macros.h"
#else
#include "unionfs_debugmacros.h"
#endif

extern int new_dentry_private_data(struct dentry *dentry);
void free_dentry_private_data(struct unionfs_dentry_info *udi);
#define sbt(sb) ((sb)->s_type->name)

/*
 * EXTERNALS:
 */
/* replicates the directory structure upto given dentry in given branch */
extern struct dentry *unionfs_create_dirs(struct inode *dir,
					  struct dentry *dentry, int bindex);
struct dentry *unionfs_create_named_dirs(struct inode *dir,
					 struct dentry *dentry, char *name,
					 int namelen, int bindex);

/* partial lookup */
extern int unionfs_partial_lookup(struct dentry *dentry);

/* Pass an unionfs dentry and an index and it will try to create a whiteout in branch 'index'.
   On error, it will proceed to a branch to the left */
extern int create_whiteout(struct dentry *dentry, int start);
extern int create_whiteout_parent(struct dentry *parent_dentry,
				  const char *filename, int start);
/* copies a file from dbstart to newbindex branch */
extern int unionfs_copyup_file(struct inode *dir, struct file *file, int bstart,
			       int newbindex, int size);
extern int unionfs_copyup_named_file(struct inode *dir, struct file *file,
				     char *name, int namelen, int bstart,
				     int new_bindex, int len);

/* copies a dentry from dbstart to newbindex branch */
extern int unionfs_copyup_dentry_len(struct inode *dir, struct dentry *dentry,
				     int bstart, int new_bindex,
				     struct file **copyup_file, int len);
extern int unionfs_copyup_named_dentry_len(struct inode *dir,
					   struct dentry *dentry, int bstart,
					   int new_bindex, char *name,
					   int namelen,
					   struct file **copyup_file, int len);

extern int create_dir_whs(struct dentry *dentry, int cur_index);

extern int remove_whiteouts(struct dentry *dentry, struct dentry *hidden_dentry,
			    int bindex);

/* Is this directory empty: 0 if it is empty, -ENOTEMPTY if not. */
extern int check_empty(struct dentry *dentry,
		       struct unionfs_dir_state **namelist);
/* Delete whiteouts from this directory in branch bindex. */
extern int delete_whiteouts(struct dentry *dentry, int bindex,
			    struct unionfs_dir_state *namelist);

/* Re-lookup a hidden dentry. */
extern int unionfs_refresh_hidden_dentry(struct dentry *dentry, int bindex);

extern void unionfs_reinterpose(struct dentry *this_dentry);
extern struct super_block *unionfs_duplicate_super(struct super_block *sb);

/* Locking functions. */
extern int unionfs_setlk(struct file *file, int cmd, struct file_lock *fl);
extern int unionfs_getlk(struct file *file, struct file_lock *fl);

/* Common file operations. */
extern int unionfs_file_revalidate(struct file *file, int willwrite);
extern int unionfs_open(struct inode *inode, struct file *file);
extern int unionfs_file_release(struct inode *inode, struct file *file);
extern int unionfs_flush(struct file *file);
extern long unionfs_ioctl(struct file *file, unsigned int cmd, unsigned long arg);

/* Inode operations */
extern int unionfs_rename(struct inode *old_dir, struct dentry *old_dentry,
			  struct inode *new_dir, struct dentry *new_dentry);
int unionfs_unlink(struct inode *dir, struct dentry *dentry);
int unionfs_rmdir(struct inode *dir, struct dentry *dentry);

/* The values for unionfs_interpose's flag. */
#define INTERPOSE_DEFAULT	0
#define INTERPOSE_LOOKUP	1
#define INTERPOSE_REVAL		2
#define INTERPOSE_REVAL_NEG	3
#define INTERPOSE_LINK		4
#define INTERPOSE_PARTIAL	5
#define INTERPOSE_PARTIAL_NEG	6

extern int unionfs_interpose(struct dentry *this_dentry, struct super_block *sb,
			     int flag);

/* Branch management ioctls. */
int unionfs_ioctl_branchcount(struct file *file, unsigned int cmd, unsigned long arg);
int unionfs_ioctl_incgen(struct file *file, unsigned int cmd, unsigned long arg);
int unionfs_ioctl_addbranch(struct inode *inode, unsigned int cmd, unsigned long arg);
int unionfs_ioctl_delbranch(struct inode *inode, unsigned int cmd, unsigned long arg);
int unionfs_ioctl_rdwrbranch(struct inode *inode, unsigned int cmd, unsigned long arg);
int unionfs_ioctl_queryfile(struct inode *inode, unsigned int cmd, unsigned long arg);

#if defined(UNIONFS_XATTR) && LINUX_VERSION_CODE >= KERNEL_VERSION(2,4,20)
/* Extended attribute functions. */
extern void *xattr_alloc(size_t size, size_t limit);
extern void xattr_free(void *ptr, size_t size);

extern int unionfs_getxattr(struct dentry *dentry, const char *name,
			    void *value, size_t size);
extern int unionfs_removexattr(struct dentry *dentry, const char *name);
extern int unionfs_listxattr(struct dentry *dentry, char *list, size_t size);

#if defined(FIST_SETXATTR_CONSTVOID) || (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,0))
int unionfs_setxattr(struct dentry *dentry, const char *name, const void *value,
		     size_t size, int flags);
#else
int unionfs_setxattr(struct dentry *dentry, const char *name, void *value,
		     size_t size, int flags);
#endif

#endif				/* LINUX_VERSION_CODE >= KERNEL_VERSION(2,4,20) */

#define copy_inode_size(dst, src) \
    dst->i_size = src->i_size; \
    dst->i_blocks = src->i_blocks;

/* returns the sum of the n_link values of all the underlying inodes of the passed inode */
static inline int get_nlinks(struct inode *inode)
{
	int sum_nlinks = 2, bindex;
	struct inode *hidden_inode;

	PASSERT(inode);
	if (!S_ISDIR(inode->i_mode)) {
		return itohi(inode)->i_nlink;
	}

	for (bindex = ibstart(inode); bindex <= ibend(inode); bindex++) {
		hidden_inode = itohi_index(inode, bindex);
		if (!hidden_inode || !S_ISDIR(hidden_inode->i_mode)) {
			continue;
		}
		sum_nlinks += (hidden_inode->i_nlink - 2);
	}
	return sum_nlinks;
}

static inline void fist_copy_attr_atime(struct inode *dest,
					const struct inode *src)
{
	PASSERT(dest);
	PASSERT(src);
	dest->i_atime = src->i_atime;
}
static inline void fist_copy_attr_times(struct inode *dest,
					const struct inode *src)
{
	PASSERT(dest);
	PASSERT(src);
	dest->i_atime = src->i_atime;
	dest->i_mtime = src->i_mtime;
	dest->i_ctime = src->i_ctime;
}
static inline void fist_copy_attr_timesizes(struct inode *dest,
					    const struct inode *src)
{
	PASSERT(dest);
	PASSERT(src);
	dest->i_atime = src->i_atime;
	dest->i_mtime = src->i_mtime;
	dest->i_ctime = src->i_ctime;
	copy_inode_size(dest, src);
}
static inline void fist_copy_attr_all(struct inode *dest,
				      const struct inode *src)
{

	print_entry_location();
	PASSERT(dest);
	PASSERT(src);
	dest->i_mode = src->i_mode;
	/* we do not need to copy if the file is a deleted file */
	if (dest->i_nlink > 0)
		dest->i_nlink = get_nlinks(dest);
	dest->i_uid = src->i_uid;
	dest->i_gid = src->i_gid;
	dest->i_rdev = src->i_rdev;
	dest->i_atime = src->i_atime;
	dest->i_mtime = src->i_mtime;
	dest->i_ctime = src->i_ctime;
	dest->i_blksize = src->i_blksize;
	dest->i_blkbits = src->i_blkbits;
	copy_inode_size(dest, src);

	//DQ: This was a change I noticed in the templates. In 2.6 they removedi_attr_flags.
	//Which makes me think they rolled it into flags.
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
	dest->i_attr_flags = src->i_attr_flags;
#else
	dest->i_flags = src->i_flags;
#endif

	print_exit_location();
}

struct dentry *unionfs_lookup_backend(struct dentry *dentry, int lookupmode);
int is_stale_inode(struct inode *inode);
void make_stale_inode(struct inode *inode);

#define IS_SET(sb, check_flag) (check_flag & MOUNT_FLAG(sb))

/* unionfs_permission, check if we should bypass error to facilitate copyup */
#define IS_COPYUP_ERR(err) (err == -EROFS)

/* unionfs_open, check if we need to copyup the file */
#define OPEN_WRITE_FLAGS (O_WRONLY | O_RDWR | O_APPEND)
#define IS_WRITE_FLAG(flag) (flag & (OPEN_WRITE_FLAGS))

static inline int branchperms(struct super_block *sb, int index)
{
	int perms;

	ASSERT(index >= 0);
	PASSERT(sb);
	PASSERT(stopd(sb));

	if (index >= UNIONFS_INLINE_OBJECTS)
		PASSERT(stopd(sb)->usi_branchperms_p);

	if (index < UNIONFS_INLINE_OBJECTS)
		perms = stopd(sb)->usi_branchperms_i[index];
	else
		perms =
		    stopd(sb)->usi_branchperms_p[index -
						 UNIONFS_INLINE_OBJECTS];

	return perms;
}
static inline int set_branchperms(struct super_block *sb, int index, int perms)
{
	ASSERT(index >= 0);
	PASSERT(sb);
	PASSERT(stopd(sb));

	if (index >= UNIONFS_INLINE_OBJECTS)
		PASSERT(stopd(sb)->usi_branchperms_p);

	if (index < UNIONFS_INLINE_OBJECTS)
		stopd(sb)->usi_branchperms_i[index] = perms;
	else
		stopd(sb)->usi_branchperms_p[index - UNIONFS_INLINE_OBJECTS] =
		    perms;

	return perms;
}

/* Is this file on a read-only branch? */
static inline int __is_robranch_super(struct super_block *sb, int index,
				      char *file, const char *function,
				      int line)
{
	int err = 0;

	print_util_entry_location();

	if (!(branchperms(sb, index) & MAY_WRITE)) {
		err = -EROFS;
	}

	print_util_exit_status(err);
	return err;
}

/* Is this file on a read-only branch? */
static inline int __is_robranch_index(struct dentry *dentry, int index,
				      char *file, const char *function,
				      int line)
{
	int err = 0;
	int perms;

	print_util_entry_location();

	PASSERT2(dentry);
	ASSERT2(index >= 0);
	PASSERT2(dtohd_index(dentry, index));
	PASSERT2(dtohd_index(dentry, index)->d_inode);
	if (index >= UNIONFS_INLINE_OBJECTS)
		PASSERT(stopd(dentry->d_sb)->usi_branchperms_p);

	if (index < UNIONFS_INLINE_OBJECTS)
		perms = stopd(dentry->d_sb)->usi_branchperms_i[index];
	else
		perms =
		    stopd(dentry->d_sb)->usi_branchperms_p[index -
							   UNIONFS_INLINE_OBJECTS];

	if (!(perms & MAY_WRITE)) {
		err = -EROFS;
	} else if (IS_RDONLY(dtohd_index(dentry, index)->d_inode)) {
		err = -EROFS;
	}

	print_util_exit_status(err);

	return err;
}
static inline int __is_robranch(struct dentry *dentry, char *file,
				const char *function, int line)
{
	int index;
	int err;

	print_util_entry_location();

	PASSERT2(dentry);
	PASSERT2(dtopd(dentry));
	index = dtopd(dentry)->udi_bstart;
	ASSERT2(index >= 0);

	err = __is_robranch_index(dentry, index, file, function, line);

	print_util_exit_status(err);

	return err;
}

#define is_robranch(d) __is_robranch(d, __FILE__, __FUNCTION__, __LINE__)
#define is_robranch_super(s, n) __is_robranch_super(s, n, __FILE__, __FUNCTION__, __LINE__)

/* If a directory contains this file, then it is opaque.  We start with the
 * .wh. flag so that it is blocked by loomkup.
 */
#define UNIONFS_DIR_OPAQUE_NAME "__dir_opaque"
#define UNIONFS_DIR_OPAQUE ".wh." UNIONFS_DIR_OPAQUE_NAME

;
/*
* Defines,structs,and functions for persistant used by kenrel and user
*/
#define MAX_MAPS 256
#define UUID_LEN 16
#define FORWARDMAP_MAGIC 0x4b1cb38f
#define REVERSEMAP_MAGIC 0Xfcafad71
#define FORWARDMAP_VERSION 0x01
#define REVERSEMAP_VERSION 0x01

struct fmaphdr {
	uint32_t magic;
	uint32_t version;
	uint8_t usedbranches;
	uint8_t uuid[UUID_LEN];
};

struct rmaphdr {
	uint32_t magic;
	uint32_t version;
	uint8_t fwduuid[UUID_LEN];
	uint8_t revuuid[UUID_LEN];
	fsid_t fsid;
};

struct fmapent {
	uint8_t fsnum;
	uint64_t inode;
};

/* Persistant Inode functions */
extern ino_t get_uin(struct super_block *sb, uint8_t branchnum,
		     ino_t inode_number, int flag);
extern int get_lin(struct super_block *sb, ino_t inode_number,
		   struct fmapent *entry);
extern int parse_imap_options(struct super_block *sb,
			      struct unionfs_dentry_info *hidden_root_info,
			      char **options);

#endif				/* __KERNEL__ */

/*
 * Definitions for user and kernel code
 */

/* Definitions for various ways to handle errors.
   Each flag's value is its bit position */

/* 1 = on error, passup,  0 = try to recover */
#define GLOBAL_ERR_PASSUP 	0

/* 1 = delete first file/directory, 0 = delete all */
#define DELETE_FIRST      	2

/* 1 = delete whiteout, 0 = check for DELETE_FIRST */
#define DELETE_WHITEOUT   	4

/* 1 = use current user's permissions, 0 = use original owner's permissions */
#define COPYUP_CURRENT_USER     8

/* 1 = f/s mounter permission, 0 = check for COPYUP_OWNER */
#define COPYUP_FS_MOUNTER	16

/* 1 = set attributes for all underlying files, 0 = leftmost file */
#define SETATTR_ALL             32

#define VALID_MOUNT_FLAGS (GLOBAL_ERR_PASSUP | DELETE_FIRST | DELETE_WHITEOUT | COPYUP_OWNER | COPYUP_FS_MOUNTER | SETATTR_ALL)

#endif				/* not __UNIONFS_H_ */
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
