# eRCaGuy_backup
Easily back up your files on any Linux system via an rsync wrapper, dry-runs, include &amp; exclude files, and nice logging.


## Usage

TODO; start by looking at the comments at the top of `back_up_linux_pc.sh`.


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

1. Add code (perhaps using Python3?) to automatically clean up a log file afterwards by deleting all lines which begin with 5 or more spaces, since these are the lines which show only global percent (%) complete status indicators rather than showing actual files or paths copied or deleted. I'd really like a better picture of what is being done to the files stored in my permanent logs, not just thousands of lines showing % complete at that instant!


## Example `rsync` runs and cmds

You can extract the main rsync run cmds using `set -x` in your script, just before the place where you want your cmd to be printed. It will be printed with a `+` symbol just before it. 

Here are some example commands I extracted, modified, and manually ran during testing:

1. works
    `sudo rsync --dry-run --dry-run -rah -v --stats --relative --delete --delete-excluded --partial-dir=.rsync-partial --files-from /home/gabriel/.back_up_linux_pc.files_to_include.txt --exclude-from /home/gabriel/.back_up_linux_pc.files_to_exclude.txt / /media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop`

1. works great with logging!
    `sudo rsync --dry-run --dry-run -rah -v --stats --relative --delete --delete-excluded --partial-dir=.rsync-partial --files-from /home/gabriel/.back_up_linux_pc.files_to_include.txt --exclude-from /home/gabriel/.back_up_linux_pc.files_to_exclude.txt --log-file ~/rsync_logs/rsync.log / /media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop`

1. works perfectly as well, with logging to a log-file *and* with total progress via `--info=progress2`. Note that progress is *not* logged, which is nice so that it does _not_ clog up the logs!
    See my modifications to this answer here: https://superuser.com/a/1002097/425838

    `sudo rsync --dry-run --dry-run -rah -v --stats --relative --delete --delete-excluded --partial-dir=.rsync-partial --files-from /home/gabriel/.back_up_linux_pc.files_to_include.txt --exclude-from /home/gabriel/.back_up_linux_pc.files_to_exclude.txt --log-file ~/rsync_logs/rsync2.log --info=progress2 / /media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop`
