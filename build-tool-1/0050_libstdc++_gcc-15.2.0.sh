source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="gcc-15.2.0.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 1

../libstdc++-v3/configure      \
    --host=$LFS_TGT            \
    --build=$(../config.guess) \
    --prefix=/usr              \
    --disable-multilib         \
    --disable-nls              \
    --disable-libstdcxx-pch    \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/15.2.0 \
    || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la || { echo_fail "Failed to remove .la files." && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
