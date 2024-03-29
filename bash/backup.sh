#!/usr/bin/env bash
#  DETAILS: Backup the directories and the daily stuff.
#
#   AUTHOR: Ravikiran K.S. (ravikirandotks@gmail.com)
#  CREATED: 11/07/11 13:32:37 PST
# MODIFIED: 05/Apr/2022 00:36:31 PDT

# Monday to Saturday, an incremental backup is made so that you have daily backups for new files until next week.
# Every Sunday, do backup of all tars from last week. One such incremental backup tarball for each of 52 weeks in a year.
# On the 1st of the month, do permanent full backups.

#set -uvx               # Treat unset variables as an error, verbose, debug mode

# Source .bashrc.dev only if invoked as a sub-shell.
[[ "$(basename backup.sh)" == "$(basename -- $0)" && -f $HOME/.bashrc.dev ]] && { source $HOME/.bashrc.dev; }
# Global defines go here. (Re)define ENV only if necessary.
# Reduce list of paths to trusted directories (most->least trusted)

# Local defines
DOW=$(date +%a)         # Day of the week e.g. Mon
DOM=$(date +%d)         # Date of the Month e.g. 27
WOY=$(date +%W)         # Week of the Year
YOC=$(date +%Y)         # Year of the Century
MAD=$(date +%b%d)       # Month and Date e.g. Sep27

BACKUP_DIR=$(echo $HOME/backups/$YOC)   # Where to store all the backups
MONTHLY_DIR=$(echo $BACKUP_DIR/monthly) # Monthly backups
WEEKLY_DIR=$(echo $BACKUP_DIR/weekly)   # Weekly backups
DAILY_DIR=$(echo $BACKUP_DIR/daily)     # Daily backups
LAST_LAST_BACKUP=$(echo $BACKUP_DIR/last-last-backup-date)
LAST_BACKUP=$(echo $BACKUP_DIR/last-backup-date)
FILE_LIST=backup_files

OWNER=$USER         # Owner and Group for backup files

function make_archive()
{
  local archOpts=cvjf && local archFile=$(echo $1".tar.bz2") && local fileList=$2
  # du -k is not reliable. for small files returns zero 0.
  [[ $(wc -l "$fileList" | awk '{print $1}') -eq 0 ]] && return;
  run tar $archOpts $archFile $(cat $fileList);
  run chmod 640 "$archFile" && run chown $OWNER "$archFile"
  mv -f $fileList $(echo $archFile".txt")
}

# Update full backup date to track incremental backups.
function update_date()
{
  # Do not truncate log file as it has trail of errors.
  run mv -f $LAST_BACKUP $LAST_LAST_BACKUP
  run echo $(date +"%Y-%m-%d %X") > "$LAST_BACKUP";   # NOW
  run chmod 640 "$LAST_BACKUP" && chown $OWNER "$LAST_BACKUP"
}

function monthly_backup()
{
    log INFO "Running monthly backup for $PWD/$1 on $(/bin/date +'%a %b/%d/%Y %T%p %Z')"
    # Make a full monthly backup based on given directories
    #find $1 -depth -type f -print > $MONTHLY_DIR/$FILE_LIST;
    find $WEEKLY_DIR -depth -type f -name "*-$2.tar.bz2" -print > $MONTHLY_DIR/$FILE_LIST;
    make_archive "$MONTHLY_DIR/$MAD-$2" "$MONTHLY_DIR/$FILE_LIST";
}

function weekly_backup()
{
    log INFO "Running weekly backup for $PWD/$1 on $(/bin/date +'%a %b/%d/%Y %T%p %Z')"
    # Then create a new weekly backup for this day-of-week
    find $DAILY_DIR -depth -type f -name "*-$2.tar.bz2" -print > $WEEKLY_DIR/$FILE_LIST;
    make_archive "$WEEKLY_DIR/$WOY-$2" "$WEEKLY_DIR/$FILE_LIST";
}

function daily_backup()
{
    log INFO "Running daily backup for $PWD/$1 on $(/bin/date +'%a %b/%d/%Y %T%p %Z')"
    # Make incremental backup using date in NEWER file. --newer option in tar fetches empty directories unnecessarily.
    # tar --newer="$NEWER" -cpPzf "$DAILY_DIR/$DOW-$file.tar.bz2" "$1";  # So using find to do the right job.
    if [ -z $BACKUP_FILE ]; then
        find $1 -depth -type f \( -ctime -1 -o -mtime -1 \) -print > $DAILY_DIR/$FILE_LIST;
    else
        echo $BACKUP_FILE > $DAILY_DIR/$FILE_LIST;
    fi
    make_archive "$DAILY_DIR/$DOW-$2" "$DAILY_DIR/$FILE_LIST";
}

function usage()
{
    echo "Usage: backup.sh [-h|-l <alternate-backup-location>] <[path1|path2|...]>"
    echo "Options:"
    echo "  -l <backup-location>- alternate destination where to place backups <path>"
    echo "  -v <backup-patch>   - revision-control diff file to backup"
    echo "  <path>              - source location that needs to be backed up"
    echo "  -h                  - print this help"
}

function sighdlr() {
    echo "Signal Handler: ctrl-c,...";
}

function main()
{
    trap sighdlr INT
    PARSE_OPTS="hl:v:"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                log DEBUG "-$opt was triggered, Parameter: $OPTARG"
                local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
                ;;
            \?)
                echo "Invalid option: -$OPTARG"; usage; exit $EINVAL
                ;;
            :)
                echo "[ERROR] Option -$OPTARG requires an argument";
                usage; exit $EINVAL
                ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((opts_found)); then
        ((opt_l)) && BACKUP_DIR=$optarg_l;
        ((opt_v)) && BACKUP_FILE=$optarg_v; # revision-control diff file
        ((opt_h)) && (usage; exit 0)
    fi

    [[ "$(id -nu)" != "$OWNER" ]] && die $EACCES "Sorry, you must be $OWNER!";

    [[ $# -eq 0 ]] && die $EINVAL "Usage: backup.sh [-l <backup-location>] <<path1> <path2> ...>"

    # Create directories (if absent). Files are created automatically on need basis.
    batch_mkdie "$BACKUP_DIR $MONTHLY_DIR $WEEKLY_DIR $DAILY_DIR"

    for dir in $*; do
        [[ ! -d "$dir" ]] && { log WARN "Backup dir $dir doesn't exist. Skip!"; continue; }
        local targetdir=$(basename -- $dir); local bkup_nm=${dir//'/'/'_'}; cdie $(dirname $dir);

        # Make incremental backups - overwrite last weeks
        daily_backup "$targetdir" $bkup_nm;

        # Create Full Weekly Backups on Sundays
        [[ "$DOW" = "Sun" ]] && { weekly_backup "$targetdir" $bkup_nm; }

        # Create Monthly Backups on 1st day of each month
        [[ "$DOM" = "01" ]] && { monthly_backup "$targetdir" $bkup_nm; }
    done
    update_date;

    exit 0
}

if [ "$(basename -- $0)" == "$(basename backup.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4
