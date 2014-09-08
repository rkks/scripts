#!/bin/bash
#  DETAILS: tmux handler script
#  CREATED: 01/28/14 10:51:03 IST
# MODIFIED: 09/08/14 10:41:45 IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2014, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# No utilities from ~/.bashrc are used here, except PATH. So, only doing that.
PATH=".:/homes/raviks/scripts/bin:/homes/raviks/tools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
[[ "$(uname -s)" == "Linux" ]] && PATH="/homes/raviks/tools/bin/linux:$PATH"
[[ "$(uname -s)" == "FreeBSD" ]] && PATH="/homes/raviks/tools/bin/freebsd:$PATH"
export PATH;

function check_os_load()
{
    # Alternately, [[ "Linux" == "$(uname -s)" ]] && { FIELD=5; } || { FIELD=4; }
    # uptime | cut -d":" -f$FIELD | sed s/,//g | sed 's/^[[:space:]]*//'    OR
    # uptime | rev | cut -d":" -f1 | rev | sed s/,//g | sed 's/^[[:space:]]*//'
    UPTIME="$(uptime | awk '{print $(NF-2),$(NF-1),$NF}' | sed s/,//g)"
    echo "$UPTIME" #(tmux_load.sh)
}

usage()
{
    echo "Usage: tmux.sh <-h|-a|-c|-e|-k|-l|-n <new-session-name>|-o|-r>"
    echo "Options:"
    echo "  -a  - attach to available session on this machine"
    echo "  -c  - check machine load on this machine"
    echo "  -e  - exclusive attach (detaches other clients)"
    echo "  -i  - print tmux information on this machine"
    echo "  -k  - list tmux key bindings of current ~/.tmux.conf"
    echo "  -l  - list tmux sessions on this machine"
    echo "  -o  - list all commands supported by current tmux"
    echo "  -r  - reload ~/.tmux.conf for current session"
    echo "  -n <session-name> - start new session with given name"
    echo "  -h  - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local PARSE_OPTS="haceikln:or"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
            [a-zA-Z0-9])
                #log DEBUG "-$opt was triggered, Parameter: $OPTARG"
                local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
                ;;
            \?)
                echo "Invalid option: -$OPTARG"; usage; exit $EINVAL;
                ;;
            :)
                echo "[ERROR] Option -$OPTARG requires an argument";
                usage; exit $EINVAL;
                ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((!opts_found)); then
        usage && exit $EINVAL;
    fi

    ((opt_a)) && tmux attach;           # non-exclusive attach to existing session
    ((opt_c)) && check_os_load;         # check machine load
    ((opt_e)) && tmux attach -d;        # exclusive (detach all other clients)
    ((opt_i)) && tmux info;             # check machine load
    ((opt_k)) && tmux list-keys;        # list key binding
    ((opt_l)) && tmux list-sessions;    # list existing sessions
    ((opt_n)) && tmux new -s $optarg_n; # new session
    ((opt_o)) && tmux list-commands;    # list commands
    ((opt_r)) && tmux source-file ~/.tmux.conf; # reload conf file
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename tmux.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
