source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="xz-5.8.1.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 0

# Temporarily grant write permission recursively for $LFS/usr/
sudo chmod -Rv 777 $LFS/usr > /dev/null 2>&1 || { echo_fail "Failed to change permissions for $LFS/usr" && exit 1; }

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.8.1 \
            || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

rm -v $LFS/usr/lib/liblzma.la || { echo_fail "Failed to remove liblzma.la" && exit 1; }

# Restore permissions recursively for $LFS/usr
sudo chmod -Rv 755 $LFS/usr > /dev/null 2>&1 || { echo_fail "Failed to restore permissions for $LFS/usr" && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
