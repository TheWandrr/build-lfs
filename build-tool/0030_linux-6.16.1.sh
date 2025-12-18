source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="linux-6.16.1.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 0

make mrproper || { echo_fail "Make mrproper failed." && exit 1; }
make headers || { echo_fail "Make headers failed." && exit 1; }

find usr/include -type f ! -name '*.h' -delete || { echo_fail "Cleaning non-header files failed." && exit 1; }
cp -rv usr/include $LFS/usr || { echo_fail "Copying headers to \$LFS/usr/include failed." && exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
