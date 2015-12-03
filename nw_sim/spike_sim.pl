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
my $limit_bytes = 1 << 12;
for (;;) {
    my $r = int(rand(4));
    my $ack = undef;
    if ($r < 2) {
        my $log2_byte_size = int(rand(3));
        # my $log2_byte_size = 2;
        my $size_bytes = 1 << $log2_byte_size;
        my $num_cells = int($limit_bytes / $size_bytes);
        my $offset = int(rand($num_cells)) * $size_bytes;
        if ($r == 0) {
            $ack = get Client ()->request("read", $base + $offset, $size_bytes);
        } else {
            my $size_bits = 8 * $size_bytes;
            my $data = int(rand(1 << $size_bits));
            my $repeated_data = 0;
            for (1 .. (4 / $size_bytes)) {
                $repeated_data = ($repeated_data << $size_bits) | $data;
            }
            $ack = get Client ()->request("write", $base + $offset, $size_bytes, $repeated_data);
        }
    } else {
        $ack = get Client ()->request("skip");
    }
    printf("CLNT: For Req <%s> ACK <%s>\n", get Client ()->get_last_request()->to_string(), $ack->to_string()) if $trace > 0;
}
