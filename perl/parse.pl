#!/usr/bin/env perl -w
# Turn on the warning option

$LOGFILE = "access.log";
open(LOGFILE) or die("Could not open log file.");

# It is usually unwise to read entire log files into memory because they can get quite large (in MBs).
# read each line into a single variable ($line) for further processing
foreach $line (<LOGFILE>) {
    # remove the newline from $line
    chomp($line);
    # split $line using the space character as the delimiter
    ($site, $logName, $fullName, $date, $gmt, $req, $file, $proto, $status, $length) = split(' ',$line);
    # time is 13th char onwards on date string
    $time = substr($date, 13);
    $date = substr($date, 1, 11);
    # remove " from beginning of $req
    $req  = substr($req, 1);
    # remove end square bracket from $gmt
    chop($gmt);
    # remove the end quote from protocol value
    chop($proto);
    # do line-by-line processing.
}
close(LOGFILE);
