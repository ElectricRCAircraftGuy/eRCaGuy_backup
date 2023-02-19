# eRCaGuy_backup
Easily back up your files on any Linux system via an rsync wrapper, dry-runs, include &amp; exclude files, and nice logging.


## Status: done and works!


## Usage

TODO; start by looking at the comments at the top of `back_up_linux_pc.sh`.


## Build and install the latest version of rsync

...to ensure you have the latest updates & bug fixes.

See the official rsync installation instructions on the official rsync repo by the current primary maintainer on GitHub here: https://github.com/WayneD/rsync/blob/master/INSTALL.md

_Tested on Ubuntu 20.04 on 19 Feb. 2023._

```bash
# install dependencies
# - Use `aptitude` to fix any which fail to install.
sudo apt update
sudo apt install -y gcc g++ gawk autoconf automake python3-cmarkgfm
sudo apt install -y acl libacl1-dev
sudo apt install -y attr libattr1-dev
sudo apt install -y libxxhash-dev
sudo aptitude install libzstd-dev  # choose the correct options to get it fixed and installed
sudo apt install -y libzstd-dev
sudo aptitude install liblz4-dev # choose N, Y, Y
sudo apt install -y liblz4-dev
sudo apt install -y libssl-dev

# check your current version
rsync --version

# go here and find the latest release: https://download.samba.org/pub/rsync/src/
# OR here, on the official GitHub release page: https://github.com/WayneD/rsync/tags

URL="https://download.samba.org/pub/rsync/src/rsync-3.2.7.tar.gz"
# download it
wget "$URL"
# extract it
tar -xf rsync-3.2.7.tar.gz

# build and install it
cd rsync-3.2.7
time ./configure  # Ensure it says "rsync 3.2.7 configuration successful" at the end
time make
sudo make install
. ~/.profile  # re-source bash config files

# check new version
rsync --version
```


## `rsync` notes

1. `tee` doesn't seem to be able to log to a remote ssh host, so log locally instead, then manually rsync the log over when done.
1. If `rsync`ing over ssh, **ensure that both computers have the same _exact_ version of `rsync`**, or else you may get weird errors. 
    Ex: If you have the following error, try forcing the sender rsync version to match the receiver rsync version. My receiver (Ubuntu 18.04 at the time) `rsync --version` was _"rsync version 3.1.2 protocol version 31"_, whereas my sender (an older version of Ubuntu) `rsync --version` was _"rsync version 3.1.0 protocol version 31"_. 

    Here's the error from the sender's side:

    ```bash
    path/to/some/file
             10.20G  20%  600.01MB/s    0:05:22  
    rsync: [sender] write error: Broken pipe (32)
    rsync error: error in rsync protocol data stream (code 12) at io.c(837) [sender=3.1.0]
    ```

    [Google search for "ubuntu 14.04 install rsync 3.1.2"](https://www.google.com/search?q=ubuntu+14.04+install+rsync+3.1.2&oq=ubuntu+14.04+install+rsync+3.1.2&aqs=chrome..69i57.17180j0j7&sourceid=chrome&ie=UTF-8)

    Upgrading to `rsync` 3.1.2 on the sender seemed to have fixed the problem. I followed these instructions: http://www.beginninglinux.com/home/backup/compile-rsync-from-source-on-ubuntu. In short (paraphrased or copied from their instructions):

    1. Download the source code from rsync official website: https://download.samba.org/pub/rsync/src/
    1. Unzip the source file and change to that directory, make sure not to use -z option:
        ```bash
        tar -xf rsync-3.1.1.tar.gz 
        cd rsync-3.1.1
        ```
    1. Build
        ```bash
        ./configure
        make
        sudo checkinstall
        ```
    1. Check new version
        ```bash
        rsync --version
        ```
    Note: When compiling, you may use `./configure --help | less` to show options. For example, the installation location may be chosen. In this case I did not choose to enter any options, so I used the regular `./configure`. 

    With command `sudo checkinstall`, the default options were chosen by pressing Enter. At the first run of `checkinstall` you may be asked to enter EOF. Press Ctrl + D. `sudo checkinstall` will create a .deb file and makes removal of the installed package easy. At the end of the process, it will even give you the command to uninstall the package, and it will tell you the location of the .deb file. So, I recommend using `sudo checkinstall` instead of the more-common `sudo make install`.

  1. More research notes:

        rsync 3.1.0 and 3.0.9 incompatibility

        `rsync error: error in rsync protocol data stream (code 12) at io.c(441) [sender=3.0.9]`

        Solutions: 
        1. Don't use compression (-z, --compress)
        1. Use ssh compression as shown below *instead of* rsync's compression!
            Source: https://bugs.launchpad.net/ubuntu/+source/rsync/+bug/1300367: 

            > Simply move compression from rsync to ssh: `-a -e "ssh -C"`


## TODO

Newest on _TOP_:

1. [ ] Get my log files to show **all files**, instead of just _folders_, during dry runs. After a dry-run you can then modify the script to ask if the user would like to go straight into a real run. Use the dry-run logs of all files as the **means** of piping files to back up **to** the 16 or so rsync threads (described below).
1. [ ] Figure out how to make the rsync `--dry-run` show files which are going to be deleted! 
    1. See my comment here: https://askubuntu.com/questions/706903/get-a-list-of-deleted-files-from-rsync#comment2544333_1304570
    1. That answer says that using `--dry-run --delete-after -av --info=DEL,PROGRESS2` should show it! Try it out. If it does, great! In my comment I explain my current settings do *not* work for me, however. That may be because the log file **shows only folders during dry runs, rather than _files_**. See if you can make the log file show **files** instead! That might then show which **files** are marked to be deleted. 
1. [ ] Make `rsync` multi-threaded with `xargs`. See here: https://stackoverflow.com/a/25532027/4561887. Divvy up the folders to be copied among 16 rsync threads. Rsync seems to be running about 16x slower than my copy medium (6 MB/sec to my external USB HDD x 16 = 96 MB/sec, which is roughly the 100 MB/sec max I'd expect), so 16 threads seems about right. 
    - [ ] Update my project readme and description to state that my wrapper makes rsync multi-threaded. 
    - [ ] Be sure to do thorough testing.
    - [ ] Investigate still having all 16 threads log to the same log files. I *think* that would still work to inter-mingle the logs all together. 
    - [ ] Make the number of threads a configurable parameter in the config file. Try 32, 16, 8, 4, etc. See which performs the best, and use that, favoring more threads over fewer if two options perform similarly. 
1. [x] Add code (perhaps using Python3?) to automatically clean up a log file afterwards by deleting all lines which begin with 5 or more spaces, since these are the lines which show only global percent (%) complete status indicators rather than showing actual files or paths copied or deleted. I'd really like a better picture of what is being done to the files stored in my permanent logs, not just thousands of lines showing % complete at that instant! - DONE 18 Feb. 2023!: I simply used rsync's built-in `--log-file` argument for cleaner logging instead!


## Example `rsync` runs and cmds

You can extract the main rsync run cmds using `set -x` in your script, just before the place where you want your cmd to be printed. It will be printed with a `+` symbol just before it. 

Here are some example commands I extracted, modified, and manually ran during testing:

1. works

    `sudo rsync --dry-run --dry-run -rah -v --stats --relative --delete --delete-excluded --partial-dir=.rsync-partial --files-from /home/gabriel/.back_up_linux_pc.files_to_include.txt --exclude-from /home/gabriel/.back_up_linux_pc.files_to_exclude.txt / /media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop`

1. works great with logging!

    `sudo rsync --dry-run --dry-run -rah -v --stats --relative --delete --delete-excluded --partial-dir=.rsync-partial --files-from /home/gabriel/.back_up_linux_pc.files_to_include.txt --exclude-from /home/gabriel/.back_up_linux_pc.files_to_exclude.txt --log-file ~/rsync_logs/rsync.log / /media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop`

1. works perfectly as well, with logging to a log-file *and* with total progress via `--info=progress2`. Note that progress data (repetitive, % complete statements) is *not* logged, which is nice so that it does _not_ clog up the logs!

    See my modifications to this answer here: https://superuser.com/a/1002097/425838:

    > Use the `--log-file` option. See `man rsync` for details. Example usage:
    > 
    > ```bash
    > rsync -av /source/ /dest/ --log-file=mylog.log
    > ```
    > 
    > Note that successive runs will _append_ to the log file, rather than overwriting it. Also, rsync logs _both_ stderr and stdout type information to the specified log file.

    `sudo rsync --dry-run --dry-run -rah -v --stats --relative --delete --delete-excluded --partial-dir=.rsync-partial --files-from /home/gabriel/.back_up_linux_pc.files_to_include.txt --exclude-from /home/gabriel/.back_up_linux_pc.files_to_exclude.txt --log-file ~/rsync_logs/rsync2.log --info=progress2 / /media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop`

1. [Best so far] Works! Log stderr to its own file as well, to quickly see if any errors occurred during the sync.

    Meaning of `3>&1 1>&2 2>&3`: it swaps stderr and stdout: https://unix.stackexchange.com/a/42776/114401

    `sudo rsync --dry-run --dry-run -rah -v --stats --relative --delete --delete-excluded --partial-dir=.rsync-partial --files-from /home/gabriel/.back_up_linux_pc.files_to_include.txt --exclude-from /home/gabriel/.back_up_linux_pc.files_to_exclude.txt --log-file ~/rsync_logs/rsync2.log --info=progress2 / /media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop 3>&1 1>&2 2>&3 | tee -a ~/rsync_logs/stderr.log`
