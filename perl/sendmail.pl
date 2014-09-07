#!/usr/bin/env perl -w
use strict;
use CGI;
#use Email::Valid;
my $query = new CGI;

# It is important to check the validity of the email address # supplied by the
# user both to catch genuine (mis-)typing errors but also to avoid exploitation
# by malicious users who could pass arbitrary strings to sendmail through the
# "send_to" CGI parameter - including whole email messages

#unless(Email::Valid->address($query->param('send_to'))) {
#   print $query->header;
#   print "You supplied an invalid email address.";
#   exit;
#}

my $sendmail = "/usr/sbin/sendmail -t";
my $reply_to = "Reply-to: mrksravikiran@gmail.com\n";
my $subject = "Subject: Confirmation of your submission\n";
my $content = "Thanks for your submission.";
my $to = $query->param('send_to')."\n";
my  $file = "subscribers.txt";

unless ($to) {
    print $query->header;
    print "Please fill in your email and try again";
}

open (FILE, ">>$file") or die "Cannot open $file: $!";
print $to,"\n";
close(FILE);

my $send_to = "To: ".$query->param('send_to');

open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
print SENDMAIL $reply_to;
print SENDMAIL $subject;
print SENDMAIL $send_to;
print SENDMAIL "Content-type: text/plain\n\n";
print SENDMAIL $content;
close(SENDMAIL);

print $query->header;
print "Confirmation of your submission will be emailed to you.";
