source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="ncurses-6.5-20250809.tgz"
RESULT=1

build_unit_header "$ARCHIVE" 0

# Build and install tic first
mkdir build || { echo_fail "Failed to create build directory." && exit 1; }
pushd build || { echo_fail "Failed to enter build directory." && exit 1; }
../configure --prefix=$LFS/tools AWK=gawk || { echo_fail "Configure tic failed." && exit 1; }
make -C include || { echo_fail "Make include failed." && exit 1; }
make -C progs tic || { echo_fail "Make tic failed." && exit 1; }
install progs/tic $LFS/tools/bin || { echo_fail "Install tic failed." && exit 1; }
popd || { echo_fail "Failed to exit build directory." && exit 1; }

./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk \
            || { echo_fail "Configure failed." && exit 1; }

make || { echo_fail "Make failed." && exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." && exit 1; }

ln -sv libncursesw.so $LFS/usr/lib/libncurses.so || { echo_fail "Creating libncurses.so symlink failed." && exit 1; }

sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $LFS/usr/include/curses.h || { echo_fail "Patching curses.h failed." && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
