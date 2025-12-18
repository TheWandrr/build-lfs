source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="binutils-2.45.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 1

../configure --prefix="$LFS/tools" \
             --with-sysroot="$LFS" \
             --target="$LFS_TGT"   \
             --disable-nls       \
             --enable-gprofng=no  \
             --disable-werror     \
             --enable-new-dtags   \
             --enable-default-hash-style=gnu \
              || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make install || { echo_fail "Make install failed." && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
