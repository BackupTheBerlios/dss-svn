CFLAGS=-g -Wall -Werror # -lefence
MOUNTPOINT=.
BINS=open-unlink flock-copyup fsync truncate bug418 rmdircheckinode

all: $(BINS)

check: all
	echo "I am the very model of a Modern major general." > $(MOUNTPOINT)/a
	./open-unlink $(MOUNTPOINT)/a

clean:
	rm -f $(BINS) core *~
