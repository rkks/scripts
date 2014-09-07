#!/usr/bin/env perl
#
# $Id: searchcore.pl,v 1.1 2005/08/31 23:30:40 steven Exp $
#
# Usage: $PROGRAM_NAME [ -b <blocksize> ] [-o <overlap> ] [-m <vmamodulo> ]
#                      <regex> <corefile>
#
# Searches the data and core sections of a corefile converted to hex.
# Prints the virtual memory address and corefile offset of each match.
# Specifying -m 4 is useful for matching word-aligned vma addresses, such
# as pointers.

use Getopt::Std;

getopts('b:o:m:');
$blocksize = defined($opt_b) ? $opt_b : 32768; # size of reads
$overlap = defined($opt_o) ? $opt_o : 4096; # overlap for reads
$vmamodulo = defined($opt_m) ? $opt_m : 1; # vma modulo

$search = shift;        # search string

die "No core file specified" if (!defined($ARGV[0]));

@headers = getheaders($ARGV[0]); # read section headers into an array

open HD, $ARGV[0] or die "Cannot open file $ARGV[0].\n";

# skip ELF headers
$offset = $headers[0]->{foff};
seek(HD, $offset, 0);

# Iterate over the file by reading blocks of the file, overlapping reads.
while (read(HD, $buffer, $blocksize)) {
    $foff = 0;
    $_ = unpack("H*", $buffer); # convert into hex
    while (m/$search/gio) { # find all matches
    $soff = pos($_) - length($&);
    next if ($soff % 2);    # skip if uneven offset
    $foff = $offset + $soff / 2; # compute file offset
    foreach $rec (@headers) {
        if ($foff >= $rec->{foff} &&
        $foff < $rec->{foff} + $rec->{size}) {
        $vma = $rec->{vma} + $foff - $rec->{foff};
        next if ($vma % $vmamodulo);
        printf("%s at vma 0x%x, file offset 0x%x\n",
               $&, $rec->{vma} + $foff - $rec->{foff}, $foff);
        last;
        }
    }           # foreach
    }               # while

    # Compute offset of next block to read.
    $offset += $blocksize - $overlap;
    if ($offset < $foff) {  # Skip past location of last match
    $offset = $foff + 2;
    }
    last if !seek(HD, $offset, 0);
}

#
# getheaders
#
# Read the section headers with non-zero vma addresses.  Hand back
# an array of headers.  Each element is a hash reference containing
# the section size (size), virtual memory address (vma) and file
# offset (foff).
#
sub getheaders {
    my @objdump = split /^/m, `objdump -h $_[0]`; # split into lines
    my $line;
    my @headers;

    # get rid of leading lines
    while ($_ = shift @objdump) {
    last if (/^Idx Name/);
    }

    for (my $i = 0; $i < @objdump; $i += 2) {
    my ($size, $vma, $foff) = unpack("x18 a8 x2 a8 x12 a8", $objdump[$i]);
    foreach ($size, $vma, $foff) { # Convert hex strings to integers
        $_ = hex($_);
    }
    next if ($vma == 0);
    push @headers, { 'size' => $size, 'vma' => $vma, 'foff' => $foff };
    }
    return @headers;
}
