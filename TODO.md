

# TODO

Newest dates on _TOP_:


## 20230219

1. [x] Use date-named log *dir* instead of *file*. Copy all 3 config files and even the backup script itself into this dir as part of the log files at the time of back up. This way, all script files and contents are present in case I need to look at the include or exclude list or track down something in particular in the script at the time of backup.

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
