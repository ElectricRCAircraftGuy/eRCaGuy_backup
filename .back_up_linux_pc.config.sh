# This file is part of eRCaGuy_dotfiles: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles

# This file is sourced by "back_up_linux_pc.sh". See that file for installation instructions.
#
# References:
# 1. My ssh notes: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/tree/master/home/.ssh


# Set the destination folder

# Option 1: back up to a USB drive (recommended: back up to an encrypted USB drive only)
DEST_FOLDER="/media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop"
# Option 2: back up to a target machine over ssh; use syntax expected by rsync
# - If using this option, also set something valid in `PRIV_SSH_KEY` below.
# DEST_FOLDER="gabriel@192.168.0.2:/media/gabriel/Linux_bak/Backups/rsync/Main_Dell_laptop"

# For ssh destinations only, specify here the path to your private key which will be used to make
# the ssh connection. Set to an empty string to *not* use ssh.
# PRIV_SSH_KEY="$HOME/.ssh/id_ed25519"
PRIV_SSH_KEY=""

# Set the log folder path and log file paths.

# Use this to discard the log data and NOT create log files this run.
# LOG_FOLDER="/dev/null"
# LOG_FOLDER="$SCRIPT_DIRECTORY/logs"
LOG_FOLDER="$HOME/rsync_logs"
# Set log file names. No file extension is needed, as .txt will be automatically appended later.
LOG_STDOUT="${LOG_FOLDER}/rsynclog_${DATE}__1_stdout"  # standard output
LOG_STDERR="${LOG_FOLDER}/rsynclog_${DATE}__2_stderr"  # standard error

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
