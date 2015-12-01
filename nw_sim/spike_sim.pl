#! /usr/bin/perl -w
eval 'exec perl -S $0 ${1+"$@"}'
    if 0; #$running_under_some_shell 

use strict;
use warnings;
use Carp;
my $trace = 0;
{package Proto;
    use fields qw(_socket _last_request _sn);
    use IO::Socket::INET;
    sub new {
        my Proto $self = shift;
        unless (ref $self) {
            $self = fields::new($self);
        }
        #  we call IO::Socket::INET->new() to create the UDP Socket and bound 
        # to specific port number mentioned in LocalPort and there is no need to provide 
        $self->{_socket} = new IO::Socket::INET (
            PeerAddr => 'localhost:5000',
            Proto => 'udp',
            ) or Carp::confess("ERROR in Socket Creation : $!");
        $self->{_sn} = int(rand(256));
        $self->{_last_request} = undef;
        print "CLNT: Create Client Proto instance\n" if $trace;
        return $self;
    }
    our $proto = undef;
    sub get_proto {
        unless (defined($proto)) {
            $proto = new Proto;
        }
        return $proto;
    }
    sub _get_last_request {
        my $self = shift;
        return $self->{_last_request};
    }
    sub _new_sn {
        my $self = shift;
        my $sn = int(rand(256));
        while ($sn == $self->{_sn}) {
            $sn = int(rand(256));
        }
        return $self->{_sn} = $sn;
    }
    sub request {
        my $self = shift;
        my $req = shift;
        $self->{_last_request} = $self->_new_sn() . ":" . $req;
        unless ($self->{_last_request} =~/^(?<hdr>[^:]+:)/ ) {
            Carp::confess("ERROR in request");
        }
        my $hdr = $+{hdr};

        my $rin = '';
        vec($rin, fileno($self->{_socket}), 1) = 1;
        my $win = '';
        my $ein = $rin | $win;
        my $timeout = 1;
        my $received = undef;
        for (;;) {
            $self->{_socket}->send($self->{_last_request});
            my ($rout, $wout, $eout);
            my $nfound = select($rout=$rin, $wout=$win, $eout=$ein, $timeout);
            next unless $nfound && vec($rout, fileno($self->{_socket}), 1);
            $self->{_socket}->recv($received, 1024);
            printf("CLNT: Received ACK %s\n", $received) if $trace;
            last if $received =~ /^${hdr}/;
        }
        $received =~ /^[^:]+:(?<ack>.*)$/;
        return $+{ack};
    }
}

for (;;) {
    my $req = "reset";
    my $ack = Proto::get_proto()->request($req);
    printf("CLNT: For Req <%s> ACK <%s>\n", $req, $ack);
    last if $ack =~ /reset:0/;
}
my $base = 0xFEED000;
my $limit = 1 << 12;
for (;;) {
    my $r = int(rand(4));
    my $req;
    if ($r == 0) {
        my $shift = int(rand(3));
        my $size = 1 << $shift;
        my $offset = int(rand($limit >> $shift)) << $shift;
        $req = sprintf("%s:%d:%d", "read", $base + $offset, $size);
    }
    elsif ($r == 1) {
        my $shift = int(rand(3));
        my $size = 1 << $shift;
        my $offset = int(rand($limit >> $shift)) << $shift;
        my $data = int(rand(1 << (8 * ($shift + 1))));
        $req = sprintf("%s:%d:%d:%d", "write", $base + $offset, $size, $data);
    }
    else {
        $req = sprintf("%s", "skip");
    }
    my $ack = Proto::get_proto()->request($req);
    printf("CLNT: For Req <%s> ACK <%s>\n", $req, $ack);
}
