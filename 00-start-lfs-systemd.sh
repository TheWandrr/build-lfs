#!/bin/bash

#STEP=1

# Check if LFS is set; if not, assign the default value
if [ -z "$LFS" ]; then
    echo "Setting LFS to default: '/mnt/lfs'"
    LFS='/mnt/lfs'
else
    echo "Using LFS root: \"$LFS\""
fi

source "$LFS/build-lfs/shared-lfs-utils.sh"

if [[ $EUID -ne 0 ]]; then
    echo_fail "Error: This script must be run as root."
    exit 1
fi

# Continue with the rest of the script
read -p "Continue? [Y]es to continue... " -n 1 -r
echo
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo_fail "Aborted"
    exit 1
fi

echo_fail "LAST CHANCE! MAKE SURE THIS IS CORRECT!"
read -p "[Y]es to continue... " -n 1 -r
echo
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo_fail "Aborted"
    exit 1
fi

exec_with_check "umask 022" "Error setting umask"
exec_with_check "chown root:root \"$LFS\"" "Error changing \$LFS ownership"
exec_with_check "chmod 755 \"$LFS\"" "Error changing \$LFS permissions"

exec_with_check "mkdir -p \"$LFS/sources\"" "Error creating \$LFS/sources"
exec_with_check "mkdir -p \"$LFS/$TOOL_DIR_1/flags\"" "Error creating tool flag directory"
exec_with_check "mkdir -p \"$LFS/$TOOL_DIR_2/flags\"" "Error creating tool flag directory"
exec_with_check "mkdir -p \"$LFS/$PACKAGE_DIR/flags\"" "Error creating package flag directory"

exec_with_check "chmod -v 755 \"$LFS/$TOOL_DIR_1\"" "Error changing \$LFS/build-lfs/build-tool permissions"
exec_with_check "chmod -v 755 \"$LFS/$TOOL_DIR_2\"" "Error changing \$LFS/build-lfs/build-tool permissions"
exec_with_check "chmod -v 755 \"$LFS/$PACKAGE_DIR\"" "Error changing \$LFS/build-lfs/build-package permissions"
exec_with_check "chmod -v 1777 \"$LFS/$TOOL_DIR_1/flags\"" "Error changing \$LFS/build-lfs/build-tool/flags permissions"
exec_with_check "chmod -v 1777 \"$LFS/$TOOL_DIR_2/flags\"" "Error changing \$LFS/build-lfs/build-tool/flags permissions"
exec_with_check "chmod -v 1777 \"$LFS/$PACKAGE_DIR/flags\"" "Error changing \$LFS/build-lfs/build-package/flags permissions"
exec_with_check "chmod -v 1777 \"$LFS/sources\"" "Error changing \$LFS/sources permissions"

# Ensure the group lfs exists
if ! getent group lfs > /dev/null; then
    exec_with_check "groupadd lfs" "Error creating group lfs"
else
    echo_pass "Group lfs already exists, skipping group creation."
fi

# Ensure the user lfs exists
if ! id -u lfs > /dev/null 2>&1; then
    exec_with_check "useradd -s /bin/bash -g lfs -m -k /dev/null lfs" "Error creating user lfs"

    # Create random password for user lfs
    USER_LFS_PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | head -c 12)

    # Set password only if the user exists
    if id -u lfs > /dev/null 2>&1; then
        echo "lfs:$USER_LFS_PASSWORD" | chpasswd || echo_fail "Error setting password for user lfs"
        echo_warn "Password for user lfs: $USER_LFS_PASSWORD"   
    else
        echo_warn "User lfs not found; cannot set password."
    fi

else
    echo_pass "User lfs already exists, skipping user creation."
fi

LFS_HOME=$(getent passwd lfs | cut -d: -f6)
echo_pass "User 'lfs' has been created. Home directory: $LFS_HOME"
step_pass

# Enter the specified sources directory
pushd $LFS/sources || { echo_fail "Error changing to \$LFS/sources directory" && exit 1; }

if [ ! -f "$WGET_LIST_FILE_NAME" ]; then
    exec_with_check "rm -f \"$WGET_LIST_FILE_NAME\"" "Error removing existing wget list file"
    if wget --quiet "$BASE_URL/$WGET_LIST_FILE_NAME"; then
        step_pass
    else
        step_fail "Failed to download list of sources"
    fi
else
    step_pass
fi

if [ ! -f "$MD5_SUMS_FILE_NAME" ]; then
    exec_with_check "rm -f \"$MD5_SUMS_FILE_NAME\"" "Error removing existing MD5 sums file"
    if wget --quiet "$BASE_URL/$MD5_SUMS_FILE_NAME"; then
        step_pass
    else
        step_fail "Failed to download MD5 sums file"
    fi
else
    step_pass
fi

echo_warn "Package list and checksums have been retrieved or reused.\nQuit now if you need to make changes, or proceed with the current list.\nExisting wget-list-systemd and md5sums are not overwritten.\nDelete these files to obtain fresh copies."
read -p "Continue? [Y]es to continue... " -n 1 -r
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
echo "Aborted"
    exit 1
fi

echo

downloads_failed=false

# Patch downloaded lists with updated versions from security advisories
sed -i "s|https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz|https://github.com/libexpat/libexpat/releases/download/R_2_7_3/expat-2.7.3.tar.gz|" wget-list-systemd \
    || step_fail "Failed to patch wget-list-systemd expat-2.7.1 --> expat-2.7.3"

sed -i "s|9f0c266ff4b9720beae0c6bd53ae4469[[:space:]]\+expat-2.7.1.tar.xz|afaadf14531cfa425e06c5513072633d  expat-2.7.3.tar.gz|" md5sums \
    || step_fail "Failed to patch md5sums expat-2.7.1 --> expat-2.7.3"

sed -i "s|https://github.com/openssl/openssl/releases/download/openssl-3.5.2/openssl-3.5.2.tar.gz|https://github.com/openssl/openssl/releases/download/openssl-3.6.0/openssl-3.6.0.tar.gz|" wget-list-systemd \
    || step_fail "Failed to patch wget-list-systemd openssl-3.5.2 --> openssl-3.6.0"

sed -i "s|890fc59f86fc21b5e4d1c031a698dbde[[:space:]]\+openssl-3.5.2.tar.gz|77ab78417082f22a2ce809898bd44da0  openssl-3.6.0.tar.gz|" md5sums \
    || step_fail "Failed to patch md5sums openssl-3.5.2 --> openssl-3.6.0"

# Read each URL from the wget list and process
while IFS= read -r source_url; do
    [[ "$source_url" == \#* ]] && continue # Skip comment lines
    [[ -z "$source_url" ]] && continue # Skip empty lines

    source_file=$(extract_filename_from_url "$source_url")

    # If file doesn't exist, try to download it
    if [ ! -f "$source_file" ]; then
        echo_warn "$source_file not found. Attempting to download $source_url."
        if ! wget --show-progress --directory-prefix="$LFS/sources" "$source_url"; then
            echo_fail "Failed while attempting to download $source_file"
            downloads_failed=true
            break
        else
            if md5sum -c <(grep "$source_file" "$MD5_SUMS_FILE_NAME") --status; then
                echo_pass "Successfully downloaded and verified $source_file"
            else
                echo_fail "MD5 checksum verification failed for $source_file"
                downloads_failed=true
                break
            fi
        fi
    else
        if md5sum -c <(grep "$source_file" "$MD5_SUMS_FILE_NAME") --status; then
            echo_pass "$source_file exists and passed MD5 checksum verification."
        else
            echo_warn "$source_file exists but failed MD5 checksum verification. Re-downloading."
            exec_with_check "rm -f \"$source_file\"" "Error removing existing file $source_file"
            if ! wget --show-progress --directory-prefix="$LFS/sources" "$source_url"; then
                echo_fail "Failed while attempting to re-download $source_file"
                downloads_failed=true
                break
            else
                if md5sum -c <(grep "$source_file" "$MD5_SUMS_FILE_NAME") --status; then
                    echo_pass "Successfully re-downloaded and verified $source_file"
                else
                    echo_fail "MD5 checksum verification failed again for $source_file"
                    downloads_failed=true
                    break
                fi
            fi
        fi
    fi

done < "$WGET_LIST_FILE_NAME"

if [ "$downloads_failed" = true ]; then
    step_fail "One or more source packages failed to download or verify."
else
    step_pass
fi

# 4.2. Creating a Limited Directory Layout in the LFS Filesystem

# Create necessary directories and change ownership
for dir in "$LFS/etc" "$LFS/var" "$LFS/usr/bin" "$LFS/usr/lib" "$LFS/usr/sbin" "$LFS/tools"; do
    if [ ! -d "$dir" ]; then
        exec_with_check "mkdir -pv \"$dir\"" "Error creating directory $dir"
    else
        echo_pass "Directory $dir already exists, skipping."
    fi
    
    # Change ownership to user lfs
    exec_with_check "chown -v lfs \"$dir\"" "Error changing ownership of $dir"
done

# Create symbolic links for bin, lib, and sbin
for i in bin lib sbin; do
    link="$LFS/$i"
    target="$LFS/usr/$i"
    if [ ! -L "$link" ]; then
        exec_with_check "ln -sv \"$target\" \"$link\"" "Error creating symbolic link for $i"
    else
        echo_pass "Symbolic link $link already exists, skipping."
    fi
done

# Create lib64 directory if architecture is x86_64
case $(uname -m) in
    x86_64) 
        if [ ! -d "$LFS/lib64" ]; then
            exec_with_check "mkdir -pv \"$LFS/lib64\"" "Error creating lib64 directory"
        else
            echo_pass "Directory $LFS/lib64 already exists, skipping."
        fi
        
        # Change ownership for lib64
        exec_with_check "chown -v lfs \"$LFS/lib64\"" "Error changing ownership of $LFS/lib64"
        ;;
esac

echo_pass "Limited directory layout created successfully"
step_pass

# Ensure the .bash_profile is created or overwritten as user lfs
cat > "$LFS_HOME/.bash_profile" << "EOF"
# Created by 00-start-lfs-systemd.sh
exec env -i HOME=$HOME TERM=$TERM PS1="\u:\w\$ " /bin/bash
EOF

# Ensure the .bashrc is created or overwritten as user lfs
NPROC_VALUE=$(nproc)  # Evaluate nproc here
cat > "$LFS_HOME/.bashrc" << EOF
# Created by 00-start-lfs-systemd.sh
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=\$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:\$PATH; fi
PATH=\$LFS/tools/bin:\$PATH
CONFIG_SITE=\$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j$NPROC_VALUE
EOF

# Set appropriate permissions for user lfs to access these files
chown lfs:lfs "$LFS_HOME/.bash_profile"
chown lfs:lfs "$LFS_HOME/.bashrc"

if [ -e /etc/bash.bashrc ]; then
    mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE || echo_fail "Error moving /etc/bash.bashrc"
else
    echo_pass "/etc/bash.bashrc does not exist. Skipped temporary renaming."
fi

#Restore the original /etc/bash.bashrc if it was moved
#if [ -e /etc/bash.bashrc.NOUSE ]; then
#    mv -v /etc/bash.bashrc.NOUSE /etc/bash.bashrc || echo_fail "Error restoring /etc/bash.bashrc"
#else
#    echo_pass "/etc/bash.bashrc.NOUSE does not exist, no need to restore."
#fi

popd || { echo_fail "Error returning to initial directory" && exit 1; }

exec_with_check "chown -R lfs:lfs \"$LFS\"" "Error changing \$LFS ownership to 'lfs'"

echo_warn "\n\n\nAll done! Switch to user 'lfs' with 'su - lfs' and run\nthe next script to build the cross-toolchain"
