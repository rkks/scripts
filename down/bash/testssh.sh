#!/bin/bash
#
# testssh.sh - Test which ssh version is running on all hosts in a network. 
# Copyright (C) 2002 Oskar Andreasson
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# USA
#
# $Id: testssh.sh,v 1.2 2003/09/09 14:10:05 blueflux Exp $

HOSTS=`nmap -sP -n $1|grep "appears to be up"| sed 's/(/ /g'| sed 's/)/ /g'|tr -s " "| cut -d " " -f 2`

sshv2="Takes SSH v2: "
sshv1="Takes SSH v1: "
sshv12="Takes SSH v1 and v2: "
weird="Weird hosts which answers, but incorrectly: "
nossh="No SSH: "

for host in $HOSTS ; do
	output=`ssh -1 $host 2> /tmp/testssh.sh`
	msg=$?
	echo -n $output
	if [ $msg -eq 255 ] ; then
		ssh -2 $host 2> /tmp/testssh.sh
		msg2=$?
		if [ $msg2 -eq 0 ] ; then
			sshv2="$sshv2 $host"
		else 
			weird="$weird $host"
		fi
	elif [ $msg -eq 1 ] ; then
		nossh="$nossh $host"
	elif [ $msg -eq 0 ] ; then
		ssh -2 $host 2> /tmp/testssh.sh
		msg2=$?
		if [ $msg2 -eq 0 ] ; then
			sshv12="$sshv12 $host"
		else
			sshv1="$sshv1 $host"
		fi
	fi
done

echo $sshv1
echo
echo $sshv2
echo
echo $sshv12
echo
echo $weird
echo 
echo $nossh
