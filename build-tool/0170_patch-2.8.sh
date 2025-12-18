source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="patch-2.8.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 0

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) \
           || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
