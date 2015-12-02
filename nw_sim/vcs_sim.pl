#! /usr/bin/perl -w
eval 'exec perl -S $0 ${1+"$@"}'
    if 0; #$running_under_some_shell 

use strict;
use warnings;
use Carp;
use Getopt::Long;
use Pod::Usage; 
use Spike_vcs::Server;

my $trace = 0;

sub spikeSetReset {
    my $reset = shift;
    my Server $proto = Server::get();
    return if $reset;
    do {} until $proto->get_next_request()->{cmd} eq "reset";
    $proto->ack('reset', $reset);
    $proto->send_ack();
}
sub spikeClock {
    my $cmd = Server::get()->get_next_request()->{cmd};
    if ($cmd =~ /read/) {
        return 1;
    }
    elsif ($cmd =~ /write/) {
        Server::get()->ack('write');
        return 2;
    }
    elsif ($cmd =~ /reset/) {
        get Server ()->ack('reset', 0);
        return 0;
    }
    else {
        Server::get()->ack('skip');
        return 0;
    }
}
sub spikeGetAddress {
    return Server::get()->get_last_request()->{addr};
}
sub spikeGetSize {
    return Server::get()->get_last_request()->{size};
}
sub spikeGetData {
    return Server::get()->get_last_request()->{data};
}
sub spikeSetData {
    my $data = shift;
    Server::get()->ack('read', $data);
}
sub spikeEndClock {
    Server::get()->send_ack();
}

sub main {
    spikeSetReset(1);
    spikeSetReset(1);
    spikeSetReset(0);

    for (;;) {
        my $cmd = spikeClock();
        if ($cmd == 1) {
            my $data = int(rand(1 << 32));
            printf("SRV: Read %x:%d:%x\n", spikeGetAddress(), spikeGetSize(), $data) if $trace;
            spikeSetData($data);
        }
        elsif ($cmd == 2) {
            printf("SRV: Write %x:%d:%x\n", spikeGetAddress(), spikeGetSize(), spikeGetData()) if $trace;
        }
        else {
            printf("SRV: Skip\n") if $trace;
        }
        spikeEndClock();
    }
    spikeSetReset(1);
    return 0;
}
exit(main());
1;
__END__
