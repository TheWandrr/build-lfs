#!/bin/bash

STEP=6

#SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
#source "$SCRIPT_DIR/shared-lfs-utils.sh"
source "$LFS/build-lfs/shared-lfs-utils.sh"

if [ "$(id -un)" != "lfs" ]; then
    echo_fail "Error: This script must be run as user 'lfs'."
    echo_fail "Run 'su - lfs' to switch to the 'lfs' user then re-run this script."
    exit 1
fi

# Check if LFS is set; if not, assign the default value
if [ -z "$LFS" ]; then
    echo "Setting LFS to default: '/mnt/lfs'"
    LFS='/mnt/lfs'
else
    echo_warn "Using LFS root: \"$LFS\""
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

FLAG_DIR="$LFS/$TOOL_DIR/flags"

# Clean up stale flags for scripts that no longer exist
for flag_file in "$FLAG_DIR"/*; do
    script_name=$(basename "$flag_file" ".success")
    if [[ ! -f "$LFS/$TOOL_DIR/$script_name" ]]; then
        
        # DEBUGGING
        echo "Looking for script: $LFS/$TOOL_DIR/$script_name"
        
        echo "Removing stale flag file for $script_name"
        rm -f "$flag_file"
    fi
done

# Loop through each script in the directory
for script in "$LFS/$TOOL_DIR"/*; do
    if [[ -f "$script" && -x "$script" ]]; then
        script_name=$(basename "$script")
        flag_file="$FLAG_DIR/$script_name.success"

        # Skip if successful
        if [[ -f "$flag_file" ]]; then
            echo_pass "$script_name already completed successfully, skipping."
            step_pass
            continue
        fi

        echo_warn "Running $script_name..."
        
        # Execute the script and check for success
        if exec_with_check "source $script" "$script_name execution failed."; then
            # Create the success flag file upon successful execution
            touch "$flag_file"
            step_pass
        fi
    fi
done

echo_warn "\n\n\nAll done!"
