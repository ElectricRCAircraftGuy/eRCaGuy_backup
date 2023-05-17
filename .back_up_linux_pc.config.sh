# This file is part of eRCaGuy_dotfiles: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles

# This file is sourced by "back_up_linux_pc.sh". See that file for installation instructions.
#
# References:
# 1. My ssh notes: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/tree/master/home/.ssh


# Set the destination folder

# Option 1: back up to a USB drive (recommended: back up to an encrypted USB drive only)
# DEST_FOLDER="/media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop"    # GS: to my 4 TB HDD
DEST_FOLDER="/media/gabriel/Linux_bak_ssd/Backups/rsync/Main_Dell_laptop"  # GS: to my 2 TB SSD
# Option 2: back up to a target machine over ssh; use syntax expected by rsync
# - If using this option, also set something valid in `PRIV_SSH_KEY` below.
# DEST_FOLDER="gabriel@192.168.0.2:/media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop"

# For ssh destinations only, specify here the path to your private key which will be used to make
# the ssh connection. Set to an empty string to *not* use ssh.
# PRIV_SSH_KEY="$HOME/.ssh/id_ed25519"
PRIV_SSH_KEY=""

# Set the **absolute** log folder and log file paths.

# LOG_FOLDER="$SCRIPT_DIRECTORY/logs"
LOG_FOLDER="$HOME/rsync_logs"

# Set the log subfolder created each run. The log subfolder should be placed within the main log
# folder.
LOG_SUBFOLDER="${LOG_FOLDER}/${DATE}${DRYRUN_SUFFIX}"

# Set the **absolute** log file names.

# 1. manual stdout log
# - We manually log this because rsync unfortunately does *not* log "deleting" type messages
#   (which indicate which files are going to be deleted) to its `--log-file`-specified logs. Those
#   messages *do* go to stdout, however, so we will manually capture stdout.
# LOG_STDOUT="/dev/null"  # Use this to discard the log data and NOT create this log file this run
LOG_STDOUT="$LOG_SUBFOLDER/stdout.txt"

# 2. manual stderr log
# - We will also manually `tee` (split) stderr messages to this log file so that you can quickly see
#   if and what any stderr messages were, since they are easy to get lost in the other log files.
# - I will also manually log some extra information to this file before and after rsync runs.
# LOG_STDERR="/dev/null"  # Use this to discard the log data and NOT create this log file this run
LOG_STDERR="$LOG_SUBFOLDER/stderr.txt"

# 3. rsync logfile
# - This log file is where rsync logs via `--log-file path/to/logfile`. I have confirmed that rsync
#   logs **both** stdout and stderr type messages here, but unfortunately does **not**
#   log "deleting" type messages which indicate which files are going to be deleted. So, we must
#   manually log stdout too in order to capture that.
# - See also my modifications to this answer, and this project's readme, for additional details:
#   https://superuser.com/a/1002097/425838
# LOG_RSYNC="/dev/null"  # Use this to discard the log data and NOT create this log file this run
LOG_RSYNC="$LOG_SUBFOLDER/rsync_logfile.txt"

# 4. list of all files that are going to be (for a dry run) or were (for an actual backup) deleted
LOG_DELETED="$LOG_SUBFOLDER/deleted.txt"


# The user can override any rsync variables here which are set inside the `configure_variables`
# function in the main script, if desired, since this function gets called near the end of that
# script.
set_user_overrides_for_rsync() {
    # Turn OFF rsync compression. Do this when syncing to a destination on a USB drive.
    COMPRESS_ARRAY=()
    # Turn ON rsync compression. Do this when syncing to a destination over ssh. Search my main
    # script for "compress" for more of my comments and notes on the details of this and when to
    # use `ssh`'s `-C` compression instead.
    # COMPRESS_ARRAY=("--compress")

    # VERBOSE_ARRAY=()  # disable verbose
    # PROGRESS_ARRAY=()  # disable progress
}
