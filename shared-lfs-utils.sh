export LFS="/mnt/lfs"

TOOL_DIR_1="build-lfs/build-tool-1"
TOOL_DIR_2="build-lfs/build-tool-2"
PACKAGE_DIR="build-lfs/build-package"

WGET_LIST_FILE_NAME="wget-list-systemd"
MD5_SUMS_FILE_NAME="md5sums"
BASE_URL="https://www.linuxfromscratch.org/lfs/view/stable-systemd"

STEP=1

NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'

function step_pass() {
    echo -e "${CYAN}Step $STEP: ${GREEN}SUCCESS${NC}"
    STEP=$((STEP + 1))
}

function step_fail() {
    local message="$1"
    echo -e "${CYAN}Step $STEP: ${RED}FAILED${NC}"
    echo "$message"
    exit 1
}

function exec_with_check() {
    local command="$1"
    local message="$2"

    # Run the command in a subshell; this will maintain interactivity
    bash -c "$command"
    local status=$?  # Capture exit status immediately

    if [[ $status -ne 0 ]]; then
        echo_fail "$message"
        exit 1
    fi
}

function echo_fail() {
    local message="$1"
    echo -e "${RED}$message${NC}"
}

function echo_pass() {
    local message="$1"
    echo -e "${GREEN}$message${NC}"
}

function echo_warn() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
}

extract_filename_from_url() {
    local url="$1"
    local filename=$(echo "$url" | sed 's|.*/||')
    echo "$filename"
}

extract_archive() {
    local archive="$1"

    if [[ ! -f "$archive" ]]; then
        echo_fail "File not found: $archive"
        return 1
    fi

    # Determine the expected extraction directory name
    dirname=$(basename "$archive" | sed -E 's/\.(tar\.(gz|xz|bz2)|tgz|zip|7z|rar)$//')

    # Check if the extraction directory already exists
    if [[ -d "$dirname" ]]; then
        echo_fail "Directory $dirname already exists! This needs to be deleted before continuing."

        echo -en "${RED}Proceed to delete the existing directory and its contents? -OR- Reuse the existing files     (y/n/r): ${NC}"
        read -n 1 -r answer
        echo  # Move to the next line

        case "$answer" in
            [Yy])
                rm -rf "$dirname"  # Forcefully remove the directory
                ;;
            [rR])
                echo_warn "Reusing existing directory: $dirname"
                return 0  # Return success code since we are reusing
                ;; 
            *)
                echo_fail "Do what you need to with the extracted source directory for $dirname, then delete it before re-running this script."
                return 2  # Return an error code indicating the operation is aborted
                ;;
        esac
    fi

    # Proceed with extraction
    case "$archive" in
        *.tar.gz | *.tgz)
            echo "Extracting $archive..."
            tar -xzf "$archive"
            ;;
        *.tar.xz)
            echo "Extracting $archive..."
            tar -xJf "$archive"
            ;;
        *.tar.bz2)
            echo "Extracting $archive..."
            tar -xjf "$archive"
            ;;
        *.zip)
            echo "Extracting $archive..."
            unzip "$archive"
            ;;
        *.7z)
            echo "Extracting $archive..."
            7z x "$archive"
            ;;
        *.rar)
            echo "Extracting $archive..."
            unrar x "$archive"
            ;;
        *)
            echo "Unsupported file type: $archive"
            return 3  # Return an error code for unsupported file types
            ;;
    esac

    # Return the directory name if extraction succeeds
    if [[ -d "$dirname" ]]; then
        echo "Archive extracted to: $dirname"  # Output the directory name
    else
        echo_fail "Extracted directory not found: $dirname"
        return 4  # Error code for missing directory after extraction
    fi

    return 0
}

function build_unit_header() {
    local archive="$1"
    local use_build_dir="$2"

    if [ -z "$LFS" ]; then
        exit_fail "LFS variable is not set. Please set LFS to the root of your LFS filesystem."
    fi

    cd "$LFS/sources" || { echo_fail "Error changing to \$LFS/sources directory"; exit 1; }

    extract_archive "$archive" || { echo_fail "Error extracting archive $archive"; exit 1; }

    output_dir=$dirname

    #echo "Extracted directory name: $output_dir"

    if [[ -d "$output_dir" ]]; then
        cd "$output_dir" || { echo_fail "Failed to change directory to $output_dir"; exit 1; }
    else
        echo_fail "Directory $output_dir does not exist after extraction."
        exit 1
    fi

    # Decide whether to make a 'build' directory based on input parameter
    if [[ "$use_build_dir" -eq 1 ]]; then
        mkdir -v build
        cd build || { echo_fail "Failed to change directory to build"; exit 1; }
    fi

    echo_warn "Building $archive in $(pwd)"
}

function build_unit_footer() {
    local archive="$1"
    
    # Navigate back to the sources directory
    cd "$LFS/sources" || { echo_fail "Error changing directory back to \$LFS/sources"; exit 1; }

    # Determine the expected archive name for cleanup purposes
    local dirname="${archive%.tar.*}"

    # Clean up the extracted directory
    if [[ -d "$dirname" ]]; then
        echo "Cleaning up extracted source files: $dirname"
        exec_with_check "rm -rf \"$dirname\"" "Error removing extracted source files: $dirname"
    fi

    #echo_pass "Cleanup completed successfully."
}

function build_packages() {
    local package_path="$1"

    local flag_dir="$LFS/$package_path/flags"

    # Clean up stale flags for scripts that no longer exist
    for flag_file in "$flag_dir"/*; do
        script_name=$(basename "$flag_file" ".success")
        if [[ ! -f "$LFS/$package_path/$script_name" ]]; then
            
            # DEBUGGING
            echo "Looking for script: $LFS/$package_path/$script_name"
            
            echo "Removing stale flag file for $script_name"
            rm -f "$flag_file"
        fi
    done

    # Loop through each script in the directory
    for script in "$LFS/$package_path"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            script_name=$(basename "$script")
            flag_file="$flag_dir/$script_name.success"

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

}