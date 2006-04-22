#!/usr/bin/perl -w
# a perl script to help debug dentry refcount leaks.
# Erez Zadok <ezk@cs.sunysb.edu>, September 2003
# Charles Wright <cwright@cs.sunysb.edu>, August 2005
#
# How to use:

# 0. change all yuor code so it uses the DGET(), DPUT(), LOOKUP_ONE_LEN macros!
#
# 1. compile your f/s with FIST_MALLOC_DEBUG.
#
# 2. run it without debugging, so you only see the memdebug printk's
#
# 3. when you're done with your test of the file system, unmount it and
#    unload the module: this will flush out a few more things which will
#    result in more kfree's to be called
#
# 4. Collect your log info from a serial console (using /var/log is unreliable)
#
# 5. run this perl script on the log file: ./match-malloc.pl foo.log

# 6. Investigate each line of output from the script to see if it's really a
#    memory leak, then fix it.
#
# 7. Repeat this procedure until there are no memory leaks.
#

use Data::Dumper;
use strict;
use Getopt::Long;

my $ret = 0;
my $verb = 0;
my $debug = 0;
my $counter = 0;

my %bufs = ();
my %leaks = ();

die if (!GetOptions("d+" => \$debug, "v+" => \$verb));

while (my $line = <>) {
    chop $line;
    $line =~ s///g;
    printf(STDERR "LINE %s\n", $line) if $debug;
    if ($line =~ /D([LGPOSD]):(\d+):(\-?\d+):(\d+):([^:]+):/) {
	my ($type,$count,$outstanding,$thiscount,$addr) = ($1,$2,$3,$4,$5);
	if ($counter + 1 != $count) {
	    printf(STDERR "COUNTER ORDER: counter is %d: line is %s\n", $counter, $line);
	    $ret++;
	}
	$counter = $count;

	if ($outstanding < 0) {
		printf(STDERR "We have less than zero outstanding dgets: $line\n");
	}
	if (($addr ne "00000000") && ($type ne "D") && ($thiscount < 1)) {
		printf(STDERR "We have less than one reference: $line\n");
	}

	if ($type eq "L" || $type eq "G") {
		printf(STDERR "DGET ADDR %s\n", $addr) if $debug;
		if (defined($bufs{$addr})) {
			$bufs{$addr}++;
			push(@{$leaks{$addr}}, $line);
		} else {
			$bufs{$addr} = 1;
			$leaks{$addr} = [$line];
		}
	} elsif ($type eq "P" || $type eq "O") {
		printf(STDERR "DPUT ADDR %s\n", $addr) if $debug;
		if ($addr eq "00000000") {
			die "NULL OPEN: $line" if ($type eq "O");
			print STDERR "dput(NULL)" if $debug;
		} elsif (!defined($bufs{$addr})) {
			printf(STDOUT "unallocated dput: %s\n", $line);
			if (defined($leaks{$addr})) {
				foreach (@{$leaks{$addr}}) {
					print "\t$_\n";
				}
			}
			$ret++;
		} else {
			if (--$bufs{$addr} == 0) {
				$bufs{$addr} = undef;
				$leaks{$addr} = undef if (!$verb);
				printf(STDERR "BALANCE RESTORED TO THE FORCE FOR $addr\n") if ($debug);
			} else {
				push(@{$leaks{$addr}}, $line);
			}
		}
	} elsif ($type eq "S" || $type eq "D") {
		if (defined($bufs{$addr})) {
			push(@{$leaks{$addr}}, $line);
		}
	} else {
		die "Invalid line type: $line";
	}
	next;
    }
    printf(STDERR "SKIP %s\n", $line) if $debug > 1;
}
foreach my $buf (keys %bufs) {
    next unless defined($bufs{$buf});
    printf(STDOUT "leaked: $buf, count=%d\n", $bufs{$buf});
    foreach (@{$leaks{$buf}}) {
	print "\t$_\n";
    }
    $ret++;
}

exit($ret > 126 ? 126 : $ret);
