source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="file-5.46.tar.gz"
RESULT=1

build_unit_header "$ARCHIVE" 0

mkdir build || { echo_fail "Failed to create build directory." && exit 1; }
pushd build || { echo_fail "Failed to enter build directory." && exit 1; }
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib \
               || { echo_fail "Configure failed." && exit 1; }
  make || { echo_fail "Make failed." && exit 1; }
popd || { echo_fail "Failed to exit build directory." && exit 1; }

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess) || { echo_fail "Configure failed." && exit 1; }

make FILE_COMPILE=$(pwd)/build/src/file || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

rm -v $LFS/usr/lib/libmagic.la || { echo_fail "Failed to remove libmagic.la" && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
