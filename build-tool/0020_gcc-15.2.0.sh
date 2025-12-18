source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="gcc-15.2.0.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 1

# Temporarily grant write permission recursively for $LFS/usr/
sudo chmod -Rv 777 $LFS/usr > /dev/null 2>&1 || { echo_fail "Failed to change permissions for $LFS/usr" && exit 1; }

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

popd || { echo_fail "Failed to return to build directory." && exit 1; }

../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.42 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++  \
    || { echo_fail "Configuration failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make install || { echo_fail "Make install failed." && exit 1; }

# Post installation tasks
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    "$(dirname "$($LFS_TGT-gcc -print-libgcc-file-name)")/include/limits.h" \
    || { echo_fail "Post installation tasks failed." && exit 1; }

# Restore permissions recursively for $LFS/usr
sudo chmod -Rv 755 $LFS/usr > /dev/null 2>&1 || { echo_fail "Failed to restore permissions for $LFS/usr" && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
