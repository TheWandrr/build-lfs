## Project Overview

**Early development stages, limited testing.**

If you find this project useful or would like to contribute, please let me know!

### Usage Instructions

1. **Set Up Your Environment**:
   - Configure your partition, filesystem, users, and environments according to the LFS 12.4 instructions.

2. **Execute the Following Commands**:

    ```bash
    sudo -i
    cd $LFS
    git clone https://github.com/TheWandrr/build-lfs.git
    LFS/build-lfs/00-start-lfs-systemd.sh
    ```

3. **Continue After Success**:
   - Upon successful execution, follow the instructions to proceed with the next script.

### Important Notes

- The initial tasks of the script include fetching `wget-list-systemd` and `md5sums` from the LFS project URLs. Existing files will not be overwritten by default, allowing your modifications to be preserved. This enables customization of your build.
  
- If any step fails, carefully read the output messages and attempt to resolve the issue. Rerun the script afterward; previously successful steps will be skipped. 
    - To force a re-execution of successful steps, delete the associated file in `build-lfs/build-___/flags`. 

- Maintaining the correct build order is crucial during the early stages, as there are dependencies that must be satisfied. This concern diminishes as you complete more steps.

### Adding or Modifying Source Packages

1. **Update Source URL**:
   - Add the new source URL to `sources/wget-list-systemd`.

2. **Add MD5 Checksum**:
   - Include a line with a trusted MD5 checksum and filename to `sources/md5sums`.

3. **Create a Build Script**:
   - Write a build script in `build-lfs/built-tool` or `build-lfs/build-package`, using existing examples to adhere to naming requirements and conventions.
