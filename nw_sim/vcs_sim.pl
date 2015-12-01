#! /usr/bin/perl -w
eval 'exec perl -S $0 ${1+"$@"}'
    if 0; #$running_under_some_shell 

use strict;
use warnings;
use Carp;
use Getopt::Long;
use Pod::Usage; 

my $trace = 0;

{package Request;
    sub new {
        my $class = shift;
        my $self = {};
        my @fields = qw(sn cmd size data);
        @{$self}{@fields[0 .. $#_]} = @_;
        return bless $self, $class;
    }
    sub deserialize {
        my $class = shift;
        my $unparsed = shift;
        my $common_request = qr@^(?<sn>[0-9]+):(?<cmd>reset|skip|read|write)(?::(?<addr>[^:]+):(?<size>[^:]+)(?::(?<data>.+))?)?$@;
        return undef unless $unparsed =~ /$common_request/;
        return bless {%+}, $class;
    }
    sub to_string {
        my $self = shift;
        my @fields = $self->{'sn', 'cmd'};
        if (exists $self->{addr}) {
            push @fields, $self->{'addr', 'size'};
            if (exists  $self->{data}) {
                push @fields, $self->{'data'};
            }
        }
        return join(':', @fields);
    }
}
{package ACK;
    sub new {
        my $class = shift;
        my Request $request = shift;
        my $self = {};
        @{$self}{qw(sn cmd)} = @{$request}{qw(sn cmd)};
        $self->{'data'} = shift if @_;
        return bless $self, $class;
    }
    sub to_string {
        my $self = shift;
        my @fields = @{$self}{qw(sn cmd)};
        if (exists $self->{'data'}) {
            push @fields, $self->{'data'};
        }        
        return join(':', @fields);
    }
    sub serialize {
        my $self = shift;
        return $self->to_string();
    }
}
{package Proto;
    use fields qw(_socket _last_request _last_ack);
    use IO::Socket::INET;
    sub _create {
        my Proto $self = shift;
        unless (ref $self) {
            $self = fields::new($self);
        }
        #  we call IO::Socket::INET->new() to create the UDP Socket and bound 
        # to specific port number mentioned in LocalPort and there is no need to provide 
        $self->{_socket} = new IO::Socket::INET (
            LocalPort => '5000',
            Proto => 'udp',
            ) or Carp::confess("ERROR in Socket Creation : $!");
        $self->{_last_request} = undef;
        $self->{_last_ack} = undef;
        print "SRV: Create Proto instance\n" if $trace;
        return $self;
    }
    our $proto = undef;
    sub get_proto {
        unless (defined($proto)) {
            $proto = _create Proto;
        }
        return $proto;
    }
    sub get_last_request {
        my $self = shift;
        return $self->{_last_request};
    }
    sub get_next_request {
        my $self = shift;
        my Request $request = undef;
        until (defined($request)) {
            print "SRV: Recv...\n" if $trace;
            $self->{_socket}->recv(my $buffer, 1024);
            print "SRV: Request from (", $self->{_socket}->peerhost(), ", ", $self->{_socket}->peerport(), "): ", $buffer, "\n" if $trace;
            $request = deserialize Request ($buffer);
            if (defined($request) && defined($self->get_last_request()) && $request->{sn} == $self->get_last_request()->{sn}) {
                print "SRV: Resend ACK to (", $self->{_socket}->peerhost(), ", ", $self->{_socket}->peerport(), "): ", $self->{_last_ack}->serialize(), "\n" if $trace;
                $self->{_socket}->send($self->{_last_ack}->serialize());
                $request = undef;
            }
        }
        return $self->{_last_request} = $request; 
    }
    sub ack {
        my $self = shift;
        $self->{_last_ack} = new ACK ($self->get_last_request(), @_);
    }
    sub send_ack {
        my $self = shift;
        print "SRV: Send ACK to (", $self->{_socket}->peerhost(), ", ", $self->{_socket}->peerport(), "): ", $self->{_last_ack}->serialize(), "\n" if $trace;
        $self->{_socket}->send($self->{_last_ack}->serialize());
    }
}
sub spikeSetReset {
    my $reset = shift;
    my Proto $proto = Proto::get_proto();
    return if $reset;
    do {} until $proto->get_next_request()->{cmd} eq "reset";
    $proto->ack($reset);
    $proto->send_ack();
}
sub spikeClock {
    my $cmd = Proto::get_proto()->get_next_request()->{cmd};
    if ($cmd =~ /read/) {
        return 1;
    }
    elsif ($cmd =~ /write/) {
        Proto::get_proto()->ack();
        return 2;
    }
    else {
        Proto::get_proto()->ack();
        return 0;
    }
}
sub spikeGetAddress {
    return Proto::get_proto()->get_last_request()->{addr};
}
sub spikeGetSize {
    return Proto::get_proto()->get_last_request()->{size};
}
sub spikeGetData {
    return Proto::get_proto()->get_last_request()->{data};
}
sub spikeSetData {
    my $data = shift;
    Proto::get_proto()->ack($data);
}
sub spikeEndClock {
    Proto::get_proto()->send_ack();
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
