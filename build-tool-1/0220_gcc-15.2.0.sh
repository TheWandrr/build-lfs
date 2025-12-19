source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="gcc-15.2.0.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 1

pushd .. || { echo_fail "Failed to return to parent directory." && exit 1; }

exec_with_check "tar -xf ../mpfr-4.2.2.tar.xz" "Failed to extract mpfr-4.2.2.tar.xz"
exec_with_check "mv -v mpfr-4.2.2 mpfr" "Failed to rename mpfr-4.2.2 to mpfr"

exec_with_check "tar -xf ../gmp-6.3.0.tar.xz" "Failed to extract gmp-6.3.0.tar.xz"
exec_with_check "mv -v gmp-6.3.0 gmp" "Failed to rename gmp-6.3.0 to gmp"

exec_with_check "tar -xf ../mpc-1.3.1.tar.gz" "Failed to extract mpc-1.3.1.tar.gz"
exec_with_check "mv -v mpc-1.3.1 mpc" "Failed to rename mpc-1.3.1 to mpc"

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 \
    || { echo_fail "Sed modification failed." && exit 1; }
 ;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in \
    || { echo_fail "Sed modification failed." && exit 1; }
    
popd || { echo_fail "Failed to return to build directory." && exit 1; }

../configure                   \
        --build=$(../config.guess) \
        --host=$LFS_TGT            \
        --target=$LFS_TGT          \
        --prefix=/usr              \
        --with-build-sysroot=$LFS  \
        --enable-default-pie       \
        --enable-default-ssp       \
        --disable-nls              \
        --disable-multilib         \
        --disable-libatomic        \
        --disable-libgomp          \
        --disable-libquadmath      \
        --disable-libsanitizer     \
        --disable-libssp           \
        --disable-libvtv           \
        --enable-languages=c,c++   \
        LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
        || { echo_fail "Configuration failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

# Post installation tasks
ln -sv gcc $LFS/usr/bin/cc || { echo_fail "Failed to create gcc symlink." && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
