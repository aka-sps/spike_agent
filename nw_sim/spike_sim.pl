#! /usr/bin/perl -w
eval 'exec perl -S $0 ${1+"$@"}'
    if 0; #$running_under_some_shell 

use strict;
use warnings;
use Carp;
my $trace = 1;
use Spike_vcs::Client;

for (;;) {
    my $ack = get Client ()->request("reset");
    printf("CLNT: For Req <%s> ACK <%s>\n", get Client ()->get_last_request()->to_string(), $ack->to_string());
    last if ($ack->{cmd} eq 'reset') && ($ack->{data} == 0);
}
my $base = 0xFEED0000;
my $limit = 1 << 12;
for (;;) {
    my $r = int(rand(4));
    my $ack = undef;
    if ($r == 0) {
        my $shift = int(rand(3));
        my $size = 1 << $shift;
        my $offset = int(rand($limit >> $shift)) << $shift;
        $ack = get Client ()->request("read", $base + $offset, $size);
    }
    elsif ($r == 1) {
        my $shift = int(rand(3));
        my $size = 1 << $shift;
        my $offset = int(rand($limit >> $shift)) << $shift;
        my $shift2 = 8 * ($offset & 0x3);
        my $data = int(rand(1 << (8 * ($shift + 1)))) << $shift2;
        $ack = get Client ()->request("write", $base + $offset, $size, $data);
    }
    else {
        $ack = get Client ()->request("skip");
    }
    printf("CLNT: For Req <%s> ACK <%s>\n", get Client ()->get_last_request()->to_string(), $ack->to_string()) if $trace > 0;
}
