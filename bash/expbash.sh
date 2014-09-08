#!/bin/bash

# Source .bashrc only if invoked as a sub-shell.
if [[ "$(basename bashexp.sh)" == "$(basename -- $0)" ]] && [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
fi

[ "$#" -eq 2 ] || die "2 arguments required, $# provided"

username=$1;
newpass=$2;
export HISTIGNORE="expect*";

expect -c "
        spawn passwd $username
        expect "?assword:"
        send \"$newpass\r\"
        expect "?assword:"
        send \"$newpass\r\"
        expect eof"

export HISTIGNORE="";

