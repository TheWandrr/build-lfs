source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="xz-5.8.1.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 0

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.8.1 \
            || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

rm -v $LFS/usr/lib/liblzma.la || { echo_fail "Failed to remove liblzma.la" && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
