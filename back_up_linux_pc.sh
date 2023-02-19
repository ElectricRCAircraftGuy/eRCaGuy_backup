#!/usr/bin/env bash

# This file is part of eRCaGuy_dotfiles: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles

# Gabriel Staples
# Started: July 2019
# Updated 2023 and later
# - I first used an older version of this to back up my Ubuntu 16.04 machine before upgrading to
#   Ubuntu 18!
#
#
# DESCRIPTION:
# Back up all of your Linux Ubuntu personal and configuration files! Based on your settings you set
# in the .back_up_linux_pc.config.sh file, you can either back up over ssh to a remote or local
# system over the network, *or* you can back up to a local USB drive.
#
#
# STATUS: wip
#
#
# INSTALLATION INSTRUCTIONS:
# 1. Copy all config files to your home dir.
#
#       # (recommended for most people) copy the files
#       cp .back_up_linux_pc.config.sh .back_up_linux_pc.files_to_exclude.txt .back_up_linux_pc.files_to_include.txt ~
#
#       # (what I do while developing this code) symlink these files if you want to use exactly
#       # my settings in this repo.
#       ln -si "${PWD}/.back_up_linux_pc.config.sh" "${PWD}/.back_up_linux_pc.files_to_exclude.txt" "${PWD}/.back_up_linux_pc.files_to_include.txt" ~
#
# 2. Manually edit each of the above config files in your home dir, according to your needs.
# 3. Symlink this executable into your PATH. Ex:
#
#       cd path/to/here
#       mkdir -p ~/bin
#       ln -si "${PWD}/back_up_linux_pc.sh" ~/bin/back_up_linux_pc     # required
#       ln -si "${PWD}/back_up_linux_pc.sh" ~/bin/gs_back_up_linux_pc  # optional; replace "gs" with your initials
#       ln -si "${PWD}/back_up_linux_pc.sh" ~/bin/back_up_this_pc      # optional                                   <====
#       ln -si "${PWD}/back_up_linux_pc.sh" ~/bin/gs_back_up_this_pc   # optional; replace "gs" with your initials  <====
#
# 4. Re-source your Ubuntu ~/.profile file to ensure ~/bin gets automatically added to your PATH.
#
#       . ~/.profile
#
#
# USAGE INSTRUCTIONS:
# 1. Plug in your destination USB drive, or ensure you are on the correct network and your ssh to a
# local or remote destination machine is set up.
# 2. Run the backup script using one of the commands below:
#
#       back_up_linux_pc
#       gs_back_up_linux_pc
#       back_up_this_pc
#       gs_back_up_this_pc
#
#
# REFERENCES:
# - https://askubuntu.com/questions/222326/which-folders-to-include-in-backup
# - https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value/2642592#2642592
# - https://stackoverflow.com/questions/18544359/how-to-read-user-input-into-a-variable-in-bash/18546416#18546416
# - https://ryanstutorials.net/bash-scripting-tutorial/bash-if-statements.php
# - [floating point division in bash--MY OWN ANS!]
#   https://stackoverflow.com/questions/12722095/how-do-i-use-floating-point-division-in-bash/58479867#58479867
# 1. eRCaGuy_hello_world/bash/array_practice.sh - especially the "array splicing" example at the
# top!
#
#
# NOTES:
# - single quotes ('') do NOT perform variable substitution within them!
# - double quotes ("") DO perform variable substitution within them!
#
# `rsync` Ex:
#
# 		rsync -avh --stats ~/GS/ ~/temp/GS_copy | tee ~/temp/GS_copy/log_stdout.txt) 3>&1 1>&2 2>&3 \
#		| tee log_stderr.txt`
# 
# Ex: WARNING WARNING WARNING: *DESTRUCTIVE *MIRROR** FROM LEFT TO RIGHT (SRC TO DEST)!
# [Add --dry-run to make it safe and test what will happen first!]
#
# 		sudo rsync -ravh --exclude='.Trash-1001' --stats --delete --delete-excluded \
#		/media/gabriel/SOURCE_DEVICE/ /media/gabriel/temp_bak/bak/TARGET_DEVICE/
# 
# -------------------------------------------
# SINGLE LINE, STAND-ALONE RSYNC EXAMPLE:
# ```bash
# start=$SECONDS; DATE=$(date +%Y%m%d-%H%Mhrs%Ssec); SRC_FOLDER="./my_dir/"; DEST_FOLDER="./my_dir--20230211-0800hrs05sec_snapshot/"; \
# 	LOG_FOLDER="./my_dir--20230211-0800hrs05sec_snapshot_log"; LOG_STDOUT="${LOG_FOLDER}/rsynclog_${DATE}__stdout.txt"; \
# 	LOG_STDERR="${LOG_FOLDER}/rsynclog_${DATE}__stderr.txt"; echo "start" | tee -a $LOG_STDERR $LOG_STDOUT; \
# 	(sudo rsync -rahv --dry-run --stats --info=progress2 $SRC_FOLDER $DEST_FOLDER | tee -a $LOG_STDOUT) 3>&1 1>&2 2>&3 \
# 	| tee -a $LOG_STDERR $LOG_STDOUT; end=$SECONDS; dt_sec=$(( end - start )); dt_min=$(printf %.3f $(echo "$dt_sec/60" | bc -l)); \
# 	echo "runtime = $dt_sec sec = $dt_min min" | tee -a $LOG_STDERR $LOG_STDOUT;
# ```
# -------------------------------------------
#
#
# TODO:
# - search this doc for "TODO".
#


RETURN_CODE_SUCCESS=0
RETURN_CODE_ERROR=1
SCRIPT_NAME="$(basename "$0")"
FULL_TERMINAL_CMD="$0 $@"

# See my answer: https://stackoverflow.com/a/60157372/4561887
FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[-1]}")"
export SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
SCRIPT_FILENAME="$(basename "$FULL_PATH_TO_SCRIPT")"

# Back up the user's crontab rules to a local file which will later be backed up by rsync
back_up_crontab() {
	# - see: https://askubuntu.com/questions/216692/where-is-the-user-crontab-stored/216711#216711
	# 1. To back up: `crontab -l > mycrontab.bak`
	# 2. To restore: `crontab mycrontab.bak`
	mkdir -p "$HOME/crontab_bak"
	# The following file will be empty if no crontab exists. Run `crontab -l` manually to see it.
	# Run `crontab -e` manually to edit the current crontab.
	#
	# GS: use 2>&1 instead of > here to direct stderr to the file too, which will state if no
	# crontab exists. Ex: "no crontab for gabriel".
	#
	# TODO(gabriel):
	# - verify this actually works when I *do* have a crontab for my user! Directing stderr to this
	#   file may be corrupting the file, for instance, and make it not work right when I try to
	#   restore it with crontab. I need to test and find out.
	echo -e "First: making a *local* back-up of your user crontab."
	crontab -l 2>&1 | tee -a "$HOME/crontab_bak/mycrontab_${DATE}.bak"
}

# Ensure the passed-in file exists, and if not, exit with an error.
check_for_file() {
    filename="$1"

    if [ ! -f "$filename" ]; then
        echo "Error: missing required file: \"$filename\""
        exit $RETURN_CODE_ERROR
    fi
}

write_options_array() {
    # Combination of all options above:
    # - NB: `-r` (`--recursive`) is *not* included as part of `-a` when `--files-from=` is in-use,
    #   so you must explicitly add it if you want it! (hence why I explicitly added it below).
    #   - See my comment here:
    #     https://superuser.com/questions/1271882/convert-ntfs-partition-to-ext4-how-to-copy-the-data/1464264#comment2404831_1464264
    OPTIONS_ARRAY=(
        "${DRY_RUN_ARRAY[@]}"
        "-rah"
        "${VERBOSE_ARRAY[@]}"
        "${STATS_ARRAY[@]}"
        "--relative"
        "${PROGRESS_ARRAY[@]}"
        "${DELETE_ARRAY[@]}"
        "${REMOTE_SHELL_ARRAY[@]}"
        "${COMPRESS_ARRAY[@]}"
        "${PARTIAL_ARRAY[@]}"
        "--files-from" "$INCLUDE_FILES"
        "--exclude-from" "$EXCLUDE_FILES"
    )

    # echo "OPTIONS_ARRAY = ${OPTIONS_ARRAY[@]}"  # debugging
}

# set variables we will later use in rsync
# TODO:
# 1. [x] Make ALL of these arguments arrays so that you CAN disable them by simply setting them to
#    `=()` in order to be **empty** arrays! See my "empty arrays" example at the top of
#    "eRCaGuy_hello_world/bash/array_practice.sh".
configure_variables() {
    SRC_FOLDER="/" # Make all src files be relative to the *root* directory
    # Files to include (back up)
    INCLUDE_FILES="$HOME/.back_up_linux_pc.files_to_include.txt"
    # File containing exclude patterns (one per line)
    EXCLUDE_FILES="$HOME/.back_up_linux_pc.files_to_exclude.txt"

    # Set our default `rsync` options for this script.
    # - See `man rsync` for explanations of each.
    # - Each option variable below is a bash array, even if the option only has one element. This is
    #   for convenience so that we can say to **not** set this option by making the array empty via
    #   `=()`.

    # VERBOSE_ARRAY=()
    VERBOSE_ARRAY=("-v")

    # PROGRESS_ARRAY=()
    # PROGRESS_ARRAY=("--progress")
    PROGRESS_ARRAY=("--info=progress2") # DEFAULT; Use this option to see the global progress
                                        # percentage after each file is copied

    # From `man rsync`:
    #
    # --delete
    #       This tells  rsync to delete extraneous files from the receiving side (ones that aren't
    #       on the sending side), but only for the directories that are being synchronized.
    #
    # --delete-excluded
    #       In addition to deleting the files on the receiving side that are not on the sending
    #       side, this tells rsync to also delete any files on the receiving side that are
    #       excluded

    # DELETE_ARRAY=("")
    # DELETE_ARRAY=("--delete") # A safer option than the one below! [USE THIS IF JUST *TEMPORARILY*
                        # excluding something and you want to NOT delete that temporarily-excluded
                        # file or folder from the destination side--rather, you ONLY want to delete
                        # included stuff on the right but not the left!]
    DELETE_ARRAY=("--delete" "--delete-excluded") # for a true MIRROR effect from source to
                                                  # destination! <======= USE ONCE READY, BUT BE
                                                  # SURE TO DO DRY RUN FIRST!

    # STATS_ARRAY=()
    STATS_ARRAY=("--stats")
    # STATS_ARRAY=("--info=stats2")  # same as `--stats` above, when `--stats` is combined with 0 or
                                     # 1 -v options (ie: -v or -vv)
    # STATS_ARRAY=("--info=stats3")

    # ----------- ssh handling start -----------

    # Disable host key checking and known_hosts file:
    # - DANGER DANGER! Although useful for my case, disabling host key checking (and not using a
    #   known_hosts file) can make you susceptible to man-in-the-middle attacks. Use at your own
    #   risk!--ie: essentially just when you are `ssh`ing from a secure, *private* or local
    #   network, and NOT over the world wide web.
    # - See where I learned how to do this here:
    #   https://serverfault.com/questions/559885/temporarily-ignore-my-ssh-known-hosts-file/588980#588980

    # Disable known_hosts file, but do NOT automatically accept whatever "ECDSA key fingerprint" the
    # ssh server has; this means I'll still have to interactively and manually type "yes" to accept
    # the key and continue, which gives me a chance to *manually* detect man-in-the-middle
    # attacks! This is what I choose for the **first** ssh/rsync connection.
    SSH_KNOWN_HOSTS_ARRAY_1=(
        "-o" "GlobalKnownHostsFile=/dev/null"
        "-o" "UserKnownHostsFile=/dev/null"
    )

    # Disable known_hosts file AND also automatically accept whatever "ECDSA key fingerprint" the
    # ssh server has; this means I do NOT have the opportunity to (manually) detect
    # man-in-the-middle attacks!
    #
    # I accept this risk for **all but the 1st** ssh/rsync connection I make in this script, as I
    # want to AT LEAST MANUALLY VERIFY THE ECDSA KEY FINGERPRINT *ONCE*, BEFORE JUST BLINDLY
    # ACCPETING IT THEREAFTER.
    SSH_KNOWN_HOSTS_ARRAY_2=(
        "-o" "GlobalKnownHostsFile=/dev/null"
        "-o" "UserKnownHostsFile=/dev/null"
        "-o" "StrictHostKeyChecking=no"
    )

    # SSH_ARRAY=("")
    # SSH_ARRAY=("-e" "ssh")

    # NB: see the notes below under the "COMPRESS" section for when to use `ssh -C`
    #
    # WithOUT ssh compression!
    # - NB: this `-i` option is REQUIRED when doing rsync over ssh with `sudo`, as sudo does NOT
    #   work with the ssh-agent, so you must **manually** load the identity (ssh private key) file
    #   via the `-i path/to/ssh_key` option.
    SSH_ARRAY=(
        "ssh" "-i" "$PRIV_SSH_KEY" "${SSH_KNOWN_HOSTS_ARRAY_1[@]}"
    )
    # WITH ssh compression!
    # - See `man ssh` for the `-C` option. See also below for more information on compression and
    #   when we might want to use ssh's `-C` option instead of rsync's `--compress` option.
    # SSH_ARRAY=(
    #     "ssh" "-i" "$PRIV_SSH_KEY" "${SSH_KNOWN_HOSTS_ARRAY_1[@]}" "-C"
    # )

    # REMOTE_SHELL_ARRAY: `-e` in rsync apparently specifies the remote shell to use, which we use
    # to specify custom ssh parameters!
    if [ -n "$PRIV_SSH_KEY" ]; then
        REMOTE_SHELL_ARRAY=(
            # NB: this funky echo thing is to force all parts of the `SSH_ARRAY` to act like a **single,
            # quoted argument** to `rsync`. Without echo, each element within the `SSH_ARRAY` would
            # become an element within the `REMOTE_SHELL_ARRAY`, which is NOT what we want in this case.
            "-e" "$(echo "${SSH_ARRAY[@]}")"
        )
    else
        REMOTE_SHELL_ARRAY=()  # empty array
    fi

    # ----------- ssh handling end -------------


    # rsync compression settings:

    # No rsync compression.
    # COMPRESS_ARRAY=()  # empty array

    # NB: if your local and remote host devices are running different version of rsync, using
    # rsync's compression may cause "broken pipe" or whatever problems when transferring large
    # files. Try *NOT using* rsync compression in this case and instead just use the `ssh -C`
    # compression option, which won't be nearly as good as rsync's, but hopefully also will work
    # instead of crashing!
    # - See here: https://bugs.launchpad.net/ubuntu/+source/rsync/+bug/1300367
    #   "Simply move compression from rsync to ssh: -a -e "ssh -C""
    # - Note: it's better to just upgrade the rsync versions to make them the same on the source
    #   and destination computers instead, if possible.

    # Use rsync compression (same as `-z`). Use `--compress` to turn **on** rsync's compression in
    # particular if you are rsyncing over a slow SSH connection.
    COMPRESS_ARRAY=("--compress")


    # Specify where large file parts can be partially stored into a temporary dir as they are
    # transferred in order to speed up the process if copying is interrupted now and then later
    # resumed.
    # See the `man rsync` pages and search for '--partial-dir'.
    # PARTIAL_ARRAY=()
    PARTIAL_ARRAY=("--partial-dir=.rsync-partial")

    set_user_overrides_for_rsync
    write_options_array
}

do_rsync_backup() {
    # Do the actual backup!
    #
    # Full example run command, as revealed by `set -x`, below:
    #
    #       rsync --dry-run --dry-run -rah -v --stats --relative --info=progress2 --delete --delete-excluded \
    #       -e 'ssh -i  -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null' \
    #       --partial-dir=.rsync-partial --files-from /home/gabriel/.back_up_linux_pc.files_to_include.txt \
    #       --exclude-from /home/gabriel/.back_up_linux_pc.files_to_exclude.txt \
    #       / /media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop
    #

    # echo "CMD: rsync --dry-run "${OPTIONS_ARRAY[@]}" $SRC_FOLDER $DEST_FOLDER"  # debugging

    # set -x  # debugging: see the actual cmds being run

    # NB: `sudo` is required below when running `rsync` in order to even **read** certain files and
    # directories. WithOUT sudo, for instance, I will get these "Permission denied" errors!:
    #
    #       rsync: link_stat "/var  # Note: contains logs in /var/log" failed: No such file or directory (2)
    #       rsync: opendir "/etc/cups/ssl" failed: Permission denied (13)
    #       rsync: opendir "/etc/lvm/archive" failed: Permission denied (13)
    #       rsync: opendir "/etc/lvm/backup" failed: Permission denied (13)
    #       rsync: opendir "/etc/multipath" failed: Permission denied (13)
    #       rsync: opendir "/etc/polkit-1/localauthority" failed: Permission denied (13)
    #       rsync: opendir "/etc/ssl/private" failed: Permission denied (13)

    # Meaning of `3>&1 1>&2 2>&3`: it swaps stderr and stdout, allowing piping stderr to `tee` too.
    # See: https://unix.stackexchange.com/a/42776/114401

    # # cmd withOUT variable substitution performed
    #                                                                   write stdout to LOG_STDOUT        write stderr to LOG_STDERR **and** LOG_STDOUT
    # cmd1='(sudo rsync "${OPTIONS_ARRAY[@]}" $SRC_FOLDER $DEST_FOLDER | tee -a $LOG_STDOUT) 3>&1 1>&2 2>&3 | tee -a $LOG_STDERR $LOG_STDOUT'
    # # cmd WITH variable substitution performed
    # cmd2="(sudo rsync "${OPTIONS_ARRAY[@]}" $SRC_FOLDER $DEST_FOLDER | tee -a $LOG_STDOUT) 3>&1 1>&2 2>&3 | tee -a $LOG_STDERR $LOG_STDOUT"

    # Log the command to the top of the stdout log file
    log_str="
Terminal command run by user ($USER): '$FULL_TERMINAL_CMD'
in directory \"$PWD\"
at date & time: $DATE ($(date))

Now running rsync cmd:
  simplified:
        "'sudo rsync "${OPTIONS_ARRAY[@]}" "$SRC_FOLDER" "$DEST_FOLDER"'"
  expanded:
        sudo rsync "${OPTIONS_ARRAY[@]}" "$SRC_FOLDER" "$DEST_FOLDER"
"
    echo "$log_str" | tee -a $LOG_STDOUT

    log_str="\n===== RSYNC LOG START =====\n"
    echo -e "$log_str" | tee -a $LOG_STDOUT
    echo -e "$log_str" >> $LOG_STDERR

    # Actually run the rsync cmd here!:
    # NB: explicitly include `--dry-run` for safety in testing
    sudo rsync --dry-run "${OPTIONS_ARRAY[@]}" "$SRC_FOLDER" "$DEST_FOLDER"  # for testing
    # sudo rsync "${OPTIONS_ARRAY[@]}" "$SRC_FOLDER" "$DEST_FOLDER"  # the final version

    log_str="\n====== RSYNC LOG END`` ======\n"
    echo -e "$log_str" | tee -a $LOG_STDOUT
    echo -e "$log_str" >> $LOG_STDERR
} # do_rsync_backup

print_elapsed_time() {
    # See my answer: https://unix.stackexchange.com/a/547849/114401
    end=$SECONDS
    duration_sec=$(( end - start ))
    duration_min=$(printf %.3f $(echo "$duration_sec/60" | bc -l))
    duration_hrs=$(printf %.3f $(echo "$duration_sec/3600" | bc -l))
    elapsed_time_str="\
Total script run-time = $duration_sec sec
                      = $duration_min min
                      = $duration_hrs hrs"
    echo -e "\n$elapsed_time_str" | tee -a $LOG_STDOUT $LOG_STDERR
}

main() {
	start=$SECONDS
    export DATE=$(date +%Y%m%d-%H%Mhrs%Ssec)

    echo "Running $SCRIPT_NAME"

    check_for_file ~/.back_up_linux_pc.config.sh
    check_for_file ~/.back_up_linux_pc.files_to_exclude.txt
    check_for_file ~/.back_up_linux_pc.files_to_include.txt

    # Source the main config file
    . ~/.back_up_linux_pc.config.sh
    echo "User settings:"
    echo "  DEST_FOLDER   = \"$DEST_FOLDER\""
    echo "  PRIV_SSH_KEY  = \"$PRIV_SSH_KEY\""
    echo "  LOG_FOLDER    = \"$LOG_FOLDER\""
    echo "  LOG_STDOUT    = \"$LOG_STDOUT\""
    echo "  LOG_STDERR    = \"$LOG_STDERR\""

    mkdir -p "$LOG_FOLDER"

    # For ssh destinations only:
    # If the user specified a `PRIV_SSH_KEY` path...
    if [ -n "$PRIV_SSH_KEY" ]; then
        # See if the ssh private key is already added to the ssh agent, & add it if not
        PRIV_SSH_KEY="../../.ssh/id_rsa_h"
        if [[ "$(ssh-add -l | grep "${PRIV_SSH_KEY}" | wc -l)" == 1 ]]; then
            echo "Private ssh key already added"
        else
            echo "Adding ssh private key to ssh-agent"
            ssh-add "${PRIV_SSH_KEY}"
        fi
    fi

    back_up_crontab

    # Ask the user if this should be a dry run or not.
    # CAUTION: THIS CODE being correct is critical to avoiding data loss. Edit it with care.
    # See: https://stackoverflow.com/a/18546416/4561887
    is_dry_run="true"
    read -p "Make this rsync backup session a dry run [Y/n]? " user_do_dry_run
    if [[ "$user_do_dry_run" == [Nn] || "$user_do_dry_run" == [Nn][Oo] ]]; then
    	# Confirm once again, giving the user one last chance to back out
        echo "
WARNING: You are about to do a REAL run instead of a dry run. Improper rsync configuration can cause
permanent data loss. It is recommended that you cancel this operation and do a dry-run first if you
have not already done so, to ensure that everything looks correct, especially in the stats output
at the end of the rsync dry-run.
"

        read -p "Are you sure you'd like to continue with the real rsync run [y/N]?
(Use Enter or N to cancel & do a dry-run instead). " user_continue
    	if [[ "$user_continue" = [Yy] || "$user_continue" == [Yy][Ee][Ss] ]]; then
            is_dry_run="false"
    	fi
    fi

    # echo "is_dry_run = \"$is_dry_run\""  # debugging

    # Set the `DRY_RUN_ARRAY` argument to rsync, and append "_dryrun" to the end of the file name if this
    # is a dry run
    if [ "$is_dry_run" = "true" ]; then
        # CAUTION: DON'T FORGET THIS PART OR YOU RISK LOSING THE USER'S DATA!
        DRY_RUN_ARRAY=("--dry-run")

        LOG_STDOUT="${LOG_STDOUT}_dryrun.txt"
    	LOG_STDERR="${LOG_STDERR}_dryrun.txt"

        dry_run_str="This is a DRY RUN. \${DRY_RUN_ARRAY[@]}=\"${DRY_RUN_ARRAY[@]}\""
    else
        DRY_RUN_ARRAY=()  # empty array

        LOG_STDOUT="${LOG_STDOUT}.txt"
    	LOG_STDERR="${LOG_STDERR}.txt"

        dry_run_str="WARNING: This is ***NOT a dry run***. \${DRY_RUN_ARRAY[@]}=\"${DRY_RUN_ARRAY[@]}\""
    fi

    # Create the log files and write to them for the first time

    echo -e "stdout:" >> $LOG_STDOUT
    echo -e "stderr:" >> $LOG_STDERR

    echo -e "\nBeginning of \"$FULL_PATH_TO_SCRIPT\"" | tee -a $LOG_STDOUT
    echo -e "\nBeginning of \"$FULL_PATH_TO_SCRIPT\"" >> $LOG_STDERR

	echo -e "$dry_run_str" | tee -a "$LOG_STDOUT"
    echo -e "$dry_run_str" >> "$LOG_STDERR"

    configure_variables
    do_rsync_backup
    print_elapsed_time

    # # LASTLY, copy over (NON-destructively [ie: withOUT `--delete`]) the log files we just tee'ed now too
    # # BELOW CMD WORKS!
    # # sudo rsync -avh -e "ssh -i $HOME/.ssh/id_ed25519" --info=progress2 "./logs" "gabriel@192.168.0.2:/home/gabriel/temp/a"
    # # THIS WORKS TOO, SO LONG AS MY PRIV KEY IS ALREADY ADDED TO THE SSH-AGENT!
    # # - notice I simply removed sudo and the -i ssh option; sudo makes the ssh-agent not work, as the loaded
    # #   ssh-agent is for the *current user*, NOT for the root (sudo) user!
    # # - ie: do NOT use `sudo`! See here (incl my comments under the ans): https://superuser.com/a/1454634/425838.
    # # rsync -avh -e "ssh" --info=progress2 "./logs" "gabriel@192.168.0.2:/home/gabriel/temp/a"
    # echo -e "\nnow rsyncing the \"${LOG_FOLDER}\" rsync log folder over to the destination too\n"
    # rsync -avh "${DRY_RUN_ARRAY[@]}" "${COMPRESS_ARRAY[@]}" -e "ssh '${SSH_KNOWN_HOSTS_ARRAY_2[@]}'" --stats --info=progress2 $LOG_FOLDER $DEST_FOLDER

    # # Remove ssh private key from ssh-agent
    # # - UNCOMMENT/*DO* USE THIS BELOW SECTION ONCE DONE TESTING!
    # if [[ $(ssh-add -l | grep "${PRIV_SSH_KEY}" | wc -l) == 1 ]]; then
    # 	echo "Removing ssh key from ssh-agent"
    # 	ssh-add -d "${PRIV_SSH_KEY}"
    # fi

    echo -e "PROGRAM DONE!\n"
}  # main


# Determine if the script is being sourced or executed (run).
# See:
# 1. "eRCaGuy_hello_world/bash/if__name__==__main___check_if_sourced_or_executed_best.sh"
# 1. My answer: https://stackoverflow.com/a/70662116/4561887
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    # This script is being run.
    __name__="__main__"
else
    # This script is being sourced.
    __name__="__source__"
fi

# --------------------------------------------------------------------------------------------------
# Main program entry point
# --------------------------------------------------------------------------------------------------

# Only run `main` if this script is being **run**, NOT sourced (imported).
# - See my answer: https://stackoverflow.com/a/70662116/4561887
if [ "$__name__" = "__main__" ]; then
    main
    exit $RETURN_CODE_SUCCESS
fi



######## OLD NOTES #########

# Meaning of `3>&1 1>&2 2>&3`: it swaps stderr and stdout:
# https://unix.stackexchange.com/a/42776/114401

# # cmd withOUT variable substitution performed
# cmd1='(sudo rsync "${OPTIONS_ARRAY[@]}" $SRC_FOLDER $DEST_FOLDER | tee -a $LOG_STDOUT) 3>&1 1>&2 2>&3 | tee -a $LOG_STDERR $LOG_STDOUT'
# # cmd WITH variable substitution performed
# cmd2="(sudo rsync "${OPTIONS_ARRAY[@]}" $SRC_FOLDER $DEST_FOLDER | tee -a $LOG_STDOUT) 3>&1 1>&2 2>&3 | tee -a $LOG_STDERR $LOG_STDOUT"

# rsync_backup()
# {
#   echo "running main rsync_backup command"
#   eval $cmd2
# }

# # Log the command to the top of the stdout log file
# echo -e "Terminal command run by user ($USER): $0 $1 $2 $3 $4 $5 $6 $7 $8 $9\nin directory \"$PWD\"\nat date & time: $DATE\n" | tee -a $LOG_STDOUT
# echo -e "Now running rsync cmd:\n\nSimplified form:\n$cmd1\n" | tee -a $LOG_STDOUT
# echo -e "Expanded form:\n$cmd2\n\n" | tee -a $LOG_STDOUT

# # Run the rsync cmd
# echo -e "===== RSYNC LOG START =====\n" | tee -a $LOG_STDOUT
# echo -e "===== RSYNC LOG START =====\n" >> $LOG_STDERR
# rsync_backup
# echo -e "\n====== RSYNC LOG END ======\n" | tee -a $LOG_STDOUT
# echo -e "\n====== RSYNC LOG END ======\n" >> $LOG_STDERR

# do_rsync_backup
# print_elapsed_time
