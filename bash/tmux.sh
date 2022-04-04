#!/bin/bash
#  DETAILS: tmux handler script
#  CREATED: 01/28/14 10:51:03 IST
# MODIFIED: 25/Mar/2022 04:25:35 PDT
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2014, Ravikiran K.S.

# Warn unset vars as error, Verbose (echo each command), Enable debug mode
#set -uvx

# No utilities from ~/.bashrc.dev are used here, except PATH. So, only doing that.
UNAMES=$(uname -s)
export PATH=".:$HOME/scripts/bin:$HOME/tools/$UNAMES/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
WIN_NAMES='bld tb1 tb2 tb3 th1 th2 th3 any all dev'

function check_os_load()
{
    # Alternately, [[ "Linux" == "$(uname -s)" ]] && { FIELD=5; } || { FIELD=4; }
    # uptime | cut -d":" -f$FIELD | sed s/,//g | sed 's/^[[:space:]]*//'    OR
    # uptime | rev | cut -d":" -f1 | rev | sed s/,//g | sed 's/^[[:space:]]*//'
    UPTIME="$(uptime | awk '{print $(NF-2),$(NF-1),$NF}' | sed s/,//g)"
    echo "$UPTIME" #(tmux_load.sh)
}

function create_session()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <sess-name>"; return $EINVAL; }
    # has-session is better, $(tmux list-sessions -F '#S' | grep -w $1)
    tmux has-session -t $1 > /dev/null 2>&1; local rval=$?;
    [[ $rval -eq 0 ]] && { echo "session $1 already exists"; return $EINVAL; }
    tmux start-server
    for name in $WIN_NAMES; do
        if [ -z $SESS_UP ]; then
            local SESS_UP=$1;
            tmux new-session -d -s $1 -n $name\; split-window -h;
        else
            tmux new-window -a -t $1 -n $name\; split-window -h;
        fi
    done
}

function execute_cmds()
{
    [[ $# -ne 1 ]] && { echo "Usage: $FUNCNAME <cmd-file>"; return $EINVAL; }
    tmux list-sessions > /dev/null 2>&1; local rval=$?;
    [[ $rval -ne 0 ]] && { echo "no sessions exist"; return $EINVAL; }
    [[ ! -e $1 ]] && { echo "cmds file $1 does not exist"; return $EINVAL; }
    local rval=0; local line=""; local sess=""; local cmds="";
    while read -r line; do
        [[ "$line" == \#* ]] && { continue; }
        IFS=, read -r sess cmds <<<"$line";
        # tmux send-keys -t {session}:{window}.{pane} "cmd <args>"
        tmux send-keys -t $sess "$cmds" C-m;
        rval=$?; [[ $rval -ne 0 ]] && { break; }
    done < $1
}

function show_info()
{
    tmux server-info | grep -vw "string\|missing\|number\|flag";
    echo "";
    echo "Environment:";
    tmux show-environment;
}

usage()
{
    echo "Usage: tmux.sh <-h|-a|-c|-e|-k|-l|-n <new-session-name>|-o|-r>"
    echo "Options:"
    echo "  -a <sess-name>  - attach to given session (pass -x for exclusive)"
    echo "  -c              - check OS, user load on this machine"
    echo "  -e <cmd-file>   - execute tmux commands in the given file"
    echo "  -i              - print tmux information on this machine"
    echo "  -k              - kill tmux server and all sessions within"
    echo "  -l              - list tmux sessions on this machine"
    echo "  -m              - list all commands supported by current tmux"
    echo "  -n <sess-name>  - start new session with given name"
    echo "  -r              - reload ~/.tmux.conf for current session"
    echo "  -s <sess-name>  - stop session with given name, all windows in it"
    echo "  -t              - start tmux server alone, no sessions "
    echo "  -x              - exclusive attach (detaches other clients)"
    echo "  -y              - list tmux key bindings of current ~/.tmux.conf"
    echo "  -h              - print this help message"
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    local PARSE_OPTS="ha:ce:iklmn:rs:txy"
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

    ((opt_c)) && check_os_load;                 # check machine load
    ((opt_i)) && show_info;                     # dumps detailed tmux info
    ((opt_y)) && tmux list-keys;                # 'C-a ?' within tmux window
    ((opt_l)) && tmux list-sessions;            # list existing sessions
    ((opt_m)) && tmux list-commands;            # list commands
    ((opt_s)) && tmux kill-session -t $optarg_s;# stop session
    ((opt_k)) && tmux kill-server;              # kill tmux server
    ((opt_t)) && tmux start-server;             # start tmux server
    ((opt_r)) && tmux source-file ~/.tmux.conf; # reload conf file
    ((opt_n)) && create_session $optarg_n;      # new session
    ((opt_e)) && execute_cmds $optarg_e;        # execute tmux cmds from file
    ((opt_x)) && { XCL="-d"; }  # exclusive (detach all other clients)
    ((opt_a)) && tmux attach -t $optarg_a $XCL; # attach to existing sess
    ((opt_h)) && { usage; exit 0; }

    exit 0
}

if [ "$(basename -- $0)" == "$(basename tmux.sh)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
