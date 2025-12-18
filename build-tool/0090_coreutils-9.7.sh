source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="coreutils-9.7.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 0

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime \
            || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

mv -v $LFS/usr/bin/chroot $LFS/usr/sbin || { echo_fail "Failed to move chroot to /usr/sbin" && exit 1; }
mkdir -pv $LFS/usr/share/man/man8 || { echo_fail "Failed to create man8 directory" && exit 1; }
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8 || { echo_fail "Failed to move chroot man page to man8" && exit 1; } 
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8 || { echo_fail "Failed to update chroot man page section number" && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
