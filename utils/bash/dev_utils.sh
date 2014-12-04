#!/bin/bash
#  DETAILS: Development Utilities
#  CREATED: 06/25/13 11:16:41 IST
# MODIFIED: 12/04/14 17:30:43 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# Admin functions
# grab ownership of given file/directory
function chownall() { sudo chown -R ${USER} ${1:-.}; }

# cpx : 'Expert' cp : uses tar to preserve ownership and permissions
function cpx () { [[ $# -ne 2 ]] && { echo "Usage: cpx src dest"; return $EINVAL; } || { tar cpf - $1 | (cdie $2 && tar xvpBf -); return $?; }; }

function dos2unixall() { local file; for file in $(find ${1:-.} -type f -print | xargs file | grep -v ELF | cut -d: -f1); do dos2unix $file; done; }

# fixtty : reset TTY after it has turned unusable (cat binary file to tty, scp failed, etc.). Alternate: alias r='echo -e \\033c'
function reset_tty() { stty sane; reset; [[ "$UNAMES" != "SunOS" ]] && { stty stop '' -ixoff; stty erase '^?'; }; }

# Using octal codes (ex. 0755 for dir/0644 for files) overwrites all old settings with new perms. go-rwx only affects given perms.
function hide() { test -z $1 && { echo "Usage: hide <dir-name>"; return $EINVAL; } || chmod -R go-rwx $dir; }

function unhide() { test -z $1 && { echo "Usage: unhide <dir-name>"; return $EINVAL; } || chmod -R go+rx $dir; }

function screentab() { test -z $1 && { echo "usage: screentab <name>"; return $EINVAL; } || screen -t $1 bash; }

# You should be able to reach index.html through 8080 port of machine. usage: cd <doc-root> && starthttp
function starthttp() { python -m SimpleHTTPServer 8080; }

function truncate_file() { run cat /dev/null > $1; }

function vncs() { test -z $1 && { echo "usage: vncs <geometry>\nEx:1600x900,1360x760"; return $EINVAL; } || (own vncserver) && vncserver -geometry $*; }

# push SSH public key to another box
function push_ssh_cert()
{
    local _host
    test -f ~/.ssh/id_dsa.pub || ssh-keygen -t dsa
    for _host in "$@";
    do
        echo $_host
        ssh $_host 'cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
    done
}

# development helper functions
# Search and find functions
function f() { test -z $1 && { echo "Usage: f <file-name>"; return $EINVAL; } || find . -name $1; }

function bug() { [[ $# -eq 0 ]] && { ls ~/work/PR/; return; } || cdie ~/work/PR/$1; }

function rli() { [[ $# -eq 0 ]] && { ls ~/work/RLI/; return; } || cdie ~/work/RLI/$1; }

# make workspace aliases. easy to jump between different workspaces
function make_workspace_alias()
{
    [[ $# -ne 1 ]] && { echo "usage: make_workspace_alias <sb-parent-dir>"; return $EINVAL; }
    [[ ! -d "$1" ]] && { echo "[ERROR] directory $1 not found"; return $ENOENT; }

    local PARENT=$1; local SB;
    for SB in $(ls $PARENT); do
        [[ "" != "$(alias $SB 2>/dev/null)" ]] && continue;     # already exists
        [[ -d "$PARENT/$SB" && -d "$PARENT/$SB/src" ]] && alias "$SB"="cd $PARENT/$SB/src";
    done
}

function diffscp()
{
    [[ $# -ne 2 ]] && { echo "usage: diffscp <relative-dir-path> <dst-server>"; return $EINVAL; }

    # if relative paths are not given, we need to do circus like: echo ${file#$1}
    for file in $(find $1 -type f); do
        # alternate: ssh $2 cat $file | vim - -c ':vnew $file |windo diffthis'
        vimdiff $file scp://$2/$file;       # GUI
        #ssh $2 cat $file | diff - $file    # CLI
    done
}

function compare()
{
    [[ $# != "2" ]] && { echo "usage: compare <file1> <file2>"; return $EINVAL; }
    # lengthy: cksum11=$(echo $(cksum $1) | awk -F ' ' '{print $1}'); cksum12=$(echo $(cksum $1) | awk -F ' ' '{print $2}');
    read cksum11 cksum12 file1 <<< $(cksum $1); read cksum21 cksum22 file2 <<< $(cksum $2);
    [[ $cksum11 -ne $cksum21 || $cksum12 -ne $cksum22 ]] && echo "Files $1 and $2 are different" || echo "Files $1 and $2 are identical";
    echo "Checksums:"; echo "$file1: $cksum11 $cksum12"; echo "$file2: $cksum21 $cksum22";
}

function show_progress()
{
    [[ $# -eq 1 && -f $1 ]] && { local file=$1; } || { echo "usage: show_progress <file-path>"; return; }
    local delay=0.75
    local spinstr='|/-\'
    local oldwc=0
    local newwc=$(wc -l $file | awk '{print $1}')
    while [ $newwc -gt $oldwc ]; do
        oldwc=$newwc
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
        newwc=$(wc -l $file | awk '{print $1}')
    done
    printf "    \b\b\b\b"
}

# Any string with $ within should be passed as: encrypt 'str' <pass>
function encrypt()
{
    [[ $# -ne 2 ]] && { echo "usage: encrypt <str> <pass>"; return; }
    (own openssl) && { echo "$1" | openssl enc -aes-256-cbc -a -e -k $2; }
}

# Encoded key is Base64, so can be input as: decrypt <key> <pass>
function decrypt()
{
    [[ $# -ne 2 ]] && { echo "usage: decrypt <key> <pass>"; return; }
    (own openssl) && { echo "$1" | openssl enc -aes-256-cbc -a -d -k $2; }
}

usage()
{
    echo "usage: dev_utils.sh []"
}

# Each shell script has to be independently testable. It can also be included/sourced in other files for functions.
main()
{
    if [ "$#" == "0" ]; then
        usage
        exit 1
    fi

    case $1 in
        *)
            usage
            ;;
    esac
    exit 0
}

if [ "$(basename -- $0)" == "$(basename dev_utils.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4

