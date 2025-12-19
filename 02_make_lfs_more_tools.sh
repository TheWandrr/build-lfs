#!/bin/bash

#STEP=100

# Check if LFS is set; if not, assign the default value
if [ -z "$LFS" ]; then
    echo "Setting LFS to default: '/mnt/lfs'"
    LFS='/mnt/lfs'
else
    echo "Using LFS root: \"$LFS\""
fi

source "$LFS/build-lfs/shared-lfs-utils.sh"

if [[ $EUID -ne 0 ]]; then
    echo_fail "Error: This script must be run as root."
    exit 1
fi

echo_warn "*************************************************"
echo_warn "*                                               *"
echo_warn "*   Do not run this script until the previous   *"
echo_warn "*   script has completed successfully!          *"
echo_warn "*                                               *"
echo_warn "*************************************************"

# Continue with the rest of the script
echo_fail "LAST CHANCE TO ABORT! MAKE SURE THIS IS CORRECT!"
read -p "[Y]es to continue... " -n 1 -r
echo
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo_fail "Aborted"
    exit 1
fi

# 7.2
chown --from lfs -R root:root $LFS/{usr,var,etc,tools} || { echo_fail "Failed to set directory ownership to user lfs"; && exit 1; }
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac || { echo_fail "Failed to set directory ownership to user lfs"; && exit 1; }

# 7.3
mkdir -pv $LFS/{dev,proc,sys,run} || { echo_fail "Failed to create virtual file system directories"; && exit 1; }

# 7.3.1
mount -v --bind /dev $LFS/dev || { echo_fail "Failed to create \$LFS/dev directory"; && exit 1; }

# 7.3.2
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts || { echo_fail "Failed mounting virtual /dev/pts"; && exit 1;}
mount -vt proc proc $LFS/proc || { echo_fail "Failed mounting virtual /proc"; && exit 1;}
mount -vt sysfs sysfs $LFS/sys || { echo_fail "Failed mounting virtual /sys"; && exit 1;}
mount -vt tmpfs tmpfs $LFS/run || { echo_fail "Failed mounting virtual /run"; && exit 1;}

if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm) || { echo_fail "Failed creating /run/shm"; && exit 1;}
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm || { echo_fail "Failed mounting temp /run/shm"; && exit 1;}
fi

echo_warn "\n\n\nAll done!"

echo_warn "Now entering chroot environment! Log in as root then run the next script in sequence."

# 7.4
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login
