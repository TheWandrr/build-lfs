source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="binutils-2.45.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 1

pushd .. || { echo_fail "Failed to change directory to source root." && exit 1; }
sed '6031s/$add_dir//' -i ltmain.sh || { echo_fail "Failed to patch ltmain.sh" && exit 1; }
popd || { echo_fail "Failed to change directory to source root." && exit 1; }

../configure                           \
            --prefix=/usr              \
            --build=$(../config.guess) \
            --host=$LFS_TGT            \
            --disable-nls              \
            --enable-shared            \
            --enable-gprofng=no        \
            --disable-werror           \
            --enable-64-bit-bfd        \
            --enable-new-dtags         \
            --enable-default-hash-style=gnu \
            || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la} || { echo_fail "Failed to remove static libraries" && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
