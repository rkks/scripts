#!/bin/sh
export LOCALE=en_US
DARK=gray`expr $RANDOM % 22`
LIGHT=gray`expr 100 - $RANDOM % 23`

if [ "$1" = "--small" ] ; then
    FONT=-sgi-screen-medium-r-normal--13-130-72-72-m-70-iso8859-1
    BOLD=-sgi-screen-bold-r-normal--13-130-72-72-m-80-iso8859-1
    shift
else
    FONT=-sgi-screen-medium-r-normal--16-160-72-72-m-80-iso8859-1
    BOLD=-sgi-screen-bold-r-normal--16-160-72-72-m-90-iso8859-1
fi

exec xterm -sl 20000 -lc +sb -fn $FONT -fb $BOLD -bg $DARK -fg $LIGHT "$@"
