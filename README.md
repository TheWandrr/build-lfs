Early development stages, limited testing.

If you want to help or have found any of this useful, let me know.

Usage:

1. Set up partition, filesystem, users and environments according to LFS 12.4 instructions.
2. Check out build-lfs to your $LFS root.
3. As root, execute 00-start-lfs-systemd.sh
4. Upon success, follow the insctuctions to proceed with the next script.

Some of the first tasks of the script are to fetch wget-list-systemd and md5sums from the LFS project URLs. Existing files will not be overwritten by default, so modifications to these files will be preserved. In this way, your build may be customized.

If any step fails, read the messages and try to fix the problem. Run the script again. Previously successful steps should be skipped. To force successful steps to be run again, delete the associated file in build-lfs/build-___/flags. Especially for the early stages, it is likely necessary that the build order be preserved, as there are dependencies that must be satisfied. This becomes less of an issue as more steps are completed.

Adding/modifying source packages:

1. Add the source URL to sources/wget-list-systemd
2. Add a line with a trusted MD5 checksum and file name to sources/md5sums
3. Add a build script to build-lfs/built-tool or build-lfs/build-package using existing examples for any naming requirements or conventions

