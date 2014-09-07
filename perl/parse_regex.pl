#!/usr/bin/env perl -w
# Turn on the warning option

# The main advantage to using regular expressions to extract information is the ease with
# which you can adjust the pattern to account for different log file formats. If you use
# a server that delimits the date/time item with curly brackets, you only need to change
# the line with the matching operator to accommodate the different format.

$LOGFILE = "access.log";
open(LOGFILE) or die("Could not open log file.");

# It is usually unwise to read entire log files into memory because they can get quite large (in MBs).
# read each line into a single variable ($line) for further processing
foreach $line (<LOGFILE>) {
    # define a word
    $w = "(.+?)";
    # match a regular expression
    $line =~ m/^$w $w $w \[$w:$w $w\] "$w $w $w" $w $w/;

    $site     = $1;
    $logName  = $2;
    $fullName = $3;
    $date     = $4;
    $time     = $5;
    $gmt      = $6;
    $req      = $7;
    $file     = $8;
    $proto    = $9;
    $status   = $10;
    $length   = $11;

    # do line-by-line processing.
}
close(LOGFILE);
