source "$LFS/build-lfs/shared-lfs-utils.sh"

ARCHIVE="glibc-2.42.tar.xz"
RESULT=1

build_unit_header "$ARCHIVE" 1

pushd .. || { echo_fail "Failed to return to parent directory." && exit 1; }

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3 || { echo_fail "Creating ld-lsb.so.3 symlink failed." ; exit 1; }
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64 || { echo_fail "Creating lib64 directory failed." ; exit 1; }
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3 || { echo_fail "Creating ld-lsb-x86-64.so.3 symlink failed." ; exit 1; }
    ;;
esac

exec_with_check "patch -Np1 -i ../glibc-2.42-fhs-1.patch" "Applying glibc FHS patch failed."

popd || { echo_fail "Failed to return to build directory." && exit 1; }

echo "rootsbindir=/usr/sbin" > configparms || { echo_fail "Creating configparms failed." ; exit 1; }

../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib           \
      --enable-kernel=5.40               \
      || { echo_fail "Configuring glibc failed." ; exit 1; }

make -j1 || { echo_fail "Make failed." ; exit 1; }

make DESTDIR=$LFS install || { echo_fail "Make install failed." ; exit 1; }

# Post installation tasks
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd || { echo_fail "Modifying ldd failed." ; exit 1; }

# SANITY CHECK 1 -----------------------

actual_output=$(echo 'int main(){}' | $LFS_TGT-gcc -x c - -v -Wl,--verbose &> dummy.log && readelf -l a.out | grep ': /lib')
actual_output=$(echo "$actual_output" | awk '{$1=$1}; 1')

# Expected output
expected_output="[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]"

# Check if the output matches
if [[ "$actual_output" == "$expected_output" ]]; then
    echo_pass "Sanity check #1 passed: Output matches expected result."
else
    echo_fail "Sanity check #1 failed: Output does not match."
    echo_fail "Expected:"
    echo_fail "$expected_output"
    echo_fail "Actual:"
    echo_fail "$actual_output"
    exit 1
fi

# SANITY CHECK 2 -----------------------

actual_output=$(grep -E -o "$LFS/lib.*/S?crt[1in].*succeeded" dummy.log)

# Expected output
expected_output="$(cat <<EOF
/mnt/lfs/lib/../lib/Scrt1.o succeeded
/mnt/lfs/lib/../lib/crti.o succeeded
/mnt/lfs/lib/../lib/crtn.o succeeded
EOF
)"

# Check if the output matches
if [[ "$actual_output" == "$expected_output" ]]; then
    echo_pass "Sanity check #2 passed: Output matches expected result."
else
    echo_fail "Sanity check #2 failed: Output does not match."
    echo_fail "Expected:"
    echo_fail "$expected_output"
    echo_fail "Actual:"
    echo_fail "$actual_output"
    exit 1
fi

# SANITY CHECK 3 -----------------------

actual_output=$(grep -B3 "^ $LFS/usr/include" dummy.log)

# Expected output
expected_output="$(cat <<EOF
#include <...> search starts here:
 /mnt/lfs/tools/lib/gcc/x86_64-lfs-linux-gnu/15.2.0/include
 /mnt/lfs/tools/lib/gcc/x86_64-lfs-linux-gnu/15.2.0/include-fixed
 /mnt/lfs/usr/include
EOF
)"

# Check if the output matches
if [[ "$actual_output" == "$expected_output" ]]; then
    echo_pass "Sanity check #3 passed: Output matches expected result."
else
    echo_fail "Sanity check #3 failed: Output does not match."
    echo_fail "Expected:"
    echo_fail "$expected_output"
    echo_fail "Actual:"
    echo_fail "$actual_output"
    exit 1
fi

# SANITY CHECK 4 -----------------------

actual_output=$(grep 'SEARCH.*/usr/lib' dummy.log | sed 's|; |\n|g')

# Expected output containing all lines
expected_output="$(cat <<EOF
SEARCH_DIR("=/mnt/lfs/tools/x86_64-lfs-linux-gnu/lib64")
SEARCH_DIR("=/usr/local/lib64")
SEARCH_DIR("=/lib64")
SEARCH_DIR("=/usr/lib64")
SEARCH_DIR("=/mnt/lfs/tools/x86_64-lfs-linux-gnu/lib")
SEARCH_DIR("=/usr/local/lib")
SEARCH_DIR("=/lib")
SEARCH_DIR("=/usr/lib");
EOF
)"

# Check if the output matches
if [[ "$actual_output" == "$expected_output" ]]; then
    echo_pass "Sanity check #4 passed: Output matches expected result."
else
    echo_fail "Sanity check #4 failed: Output does not match."
    echo_fail "Expected:"
    echo_fail "$expected_output"
    echo_fail "Actual:"
    echo_fail "$actual_output"
    exit 1
fi

# SANITY CHECK 5 -----------------------

actual_output=$(grep '/lib.*/libc.so.6 ' dummy.log)

# Expected output
expected_output="attempt to open /mnt/lfs/usr/lib/libc.so.6 succeeded"

# Check if the output matches
if [[ "$actual_output" == "$expected_output" ]]; then
    echo_pass "Sanity check #5 passed: Output matches expected result."
else
    echo_fail "Sanity check #5 failed: Output does not match."
    echo_fail "Expected:"
    echo_fail "$expected_output"
    echo_fail "Actual:"
    echo_fail "$actual_output"
    exit 1
fi

# SANITY CHECK 6 -----------------------

actual_output=$(grep 'found' dummy.log)

# Expected output
expected_output="found ld-linux-x86-64.so.2 at /mnt/lfs/usr/lib/ld-linux-x86-64.so.2"

# Check if the output matches
if [[ "$actual_output" == "$expected_output" ]]; then
    echo_pass "Sanity check #6 passed: Output matches expected result."
else
    echo_fail "Sanity check #6 failed: Output does not match."
    echo_fail "Expected:"
    echo_fail "$expected_output"
    echo_fail "Actual:"
    echo_fail "$actual_output"
    exit 1
fi

# END SANITY CHECKS --------------------

rm -v a.out dummy.log || { echo "Cleanup failed." ; exit 1; }

build_unit_footer "$ARCHIVE"

# If we haven't already exited, everything worked
exit 0
