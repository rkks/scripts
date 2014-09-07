#!/usr/bin/env perl -w

if(defined $ARGV[2])
{
    $dir = $ARGV[0];
    $src = $ARGV[1];
    $dst = $ARGV[2];
}
else
{
    die  "USAGE: replace.pl dir textToReplace replaceWith";
}

@fileList = `ls $dir`;

`mkdir $dir."/tmp"`;

foreach $file (@fileList)
{
    $srcFile = $dir."/".$file;
    $dstFile = $dir."/tmp/".$file;
    print "$srcFile";
    print "$dstFile";

    open(SPTR,"$srcFile");
    open(DPTR,">$dstFile");

    @lines = <SPTR>;

    foreach $line (@lines)
    {
        $line =~ s/$src/$dst/gi;
        print DPTR $line;
    }

    close(DPTR);
    close(SPTR);
}
