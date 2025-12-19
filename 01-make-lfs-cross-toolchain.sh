#!/bin/bash

# Check if LFS is set; if not, assign the default value
if [ -z "$LFS" ]; then
    echo "Setting LFS to default: '/mnt/lfs'"
    LFS='/mnt/lfs'
else
    echo "Using LFS root: \"$LFS\""
fi

source "$LFS/build-lfs/shared-lfs-utils.sh"

if [ "$(id -un)" != "lfs" ]; then
    echo_fail "Error: This script must be run as user 'lfs'."
    echo_fail "Run 'su - lfs' to switch to the 'lfs' user then re-run this script."
    exit 1
fi

echo_warn "*************************************************"
echo_warn "*                                               *"
echo_warn "*   Do not run this script until the previous   *"
echo_warn "*   script has completed successfully!          *"
echo_warn "*                                               *"
echo_warn "*************************************************"

# Continue with the rest of the script
echo_fail "LAST CHANCE TO ABORT! MAKE SURE THIS IS CORRECT!"
read -p "[Y]es to continue... " -n 1 -r
echo
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo_fail "Aborted"
    exit 1
fi

build_packages "$TOOL_DIR_1"

echo_warn "\n\n\nAll done!"
