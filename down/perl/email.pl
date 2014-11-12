#!/usr/bin/env perl -w

# A simple Perl-based CGI email handler.
#
# Copyright 2004 Boutell.Com, Inc. Compatible with our earlier C program.
#
# Released under the same license terms as Perl 5 itself.
#
# We ask, but do not require, that you link to
# http://www.boutell.com/email/ when using this script or a
# variation of it.

use CGI;

my $sendmail = "/usr/sbin/sendmail";

# A text file containing a list of valid email recipients and the web pages to
# which the user should be redirected after email is sent to each, on
# alternating lines.  This allows one copy of the script to serve multiple
# purposes without the risk that the script will be abused to send spam.
# YOU MUST CREATE SUCH A TEXT FILE AND CHANGE THE NEXT LINE TO ITS
# LOCATION ON THE SERVER.

my $emailConfPath = "/home/boutell/email/email.conf";

# Parse any submitted form fields and return an object we can use
# to retrieve them
my $query = new CGI;

my $name = &veryclean($query->param('name'));
my $email = &veryclean($query->param('email'));
my $recipient = &veryclean($query->param('recipient'));
my $subject = &veryclean($query->param('subject'));
#newlines allowed
my $content = &clean($query->param('content'));

#Note: subject is not mandatory, but you can easily change that
if (($name eq "") || ($email eq "") || ($content eq "") || ($recipient eq ""))
{
    &error("Email Rejected",
        "Please fill out all fields provided. Back up to the " .
        "previous page to try again.");
}

if (!open(IN, "$emailConfPath")) {
    &error("Configuration Error",
        "The file $emailConfPath does not exist or cannot be " .
        "opened. Please read the documentation before installing " .
        "email.cgi.");
}

my $returnpage;

my $ok = 0;
while (1) {
    my $recipientc = <IN>;
    $recipientc =~ s/\s+$//;
    if ($recipientc eq "") {
        last;
    }
    my $returnpagec = <IN>;
    $returnpagec =~ s/\s+$//;
    if ($returnpagec eq "") {
        last;
    }
    if ($recipientc eq $recipient) {
        $ok = 1;
        $returnpage = $returnpagec;
        last;
    }
}
close(IN);
if (!$ok) {
    &error("Email Rejected",
        "The requested destination address is not one of " .
        "the permitted email recipients. Please read the " .
        "documentation before installing email.cgi.");
}

# Open a pipe to the sendmail program
open(OUT, "|$sendmail -t");
# Use the highly convenient <<EOM notation to include the message
# in this script more or less as it will actually appear
print OUT <<EOM
To: $recipient
Subject: $subject
Reply-To: $email
Supposedly-From: $name
[This message was sent through a www-email gateway.]

$content
EOM
;
close(OUT);
# Now redirect to the appropriate "landing" page for this recipient.
print $query->redirect($returnpage);

exit 0;

sub clean
{
    # Clean up any leading and trailing whitespace
    # using regular expressions.
    my $s = shift @_;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}

sub veryclean
{
    # Also forbid newlines by folding all internal whitespace to
    # single spaces. This prevents faking extra headers to cc
    # extra people.
    my $s = shift @_;
    $s = &clean($s);
    $s =~ s/\s+$/ /g;
    return $s;
}

sub error
{
    # Output a valid HTML page as an error message
    my($title, $content) = @_;
    print $query->header;
    print <<EOM
<html>
<head>
<title>$title</title>
</head>
<body>
<h1 align="center">$title</h1>
<p>
$content
</p>
EOM
;
    exit 0;
}

