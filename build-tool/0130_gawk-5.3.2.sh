source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="gawk-5.3.2.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 0

sed -i 's/extras//' Makefile.in || { echo_fail "Sed command failed." && exit 1; }

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) \
            || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
