package Client;
use fields qw(_socket _last_request _sn);
our $trace = 0;
sub new {
    my Client $self = shift;
    $self = fields::new($self) unless ref $self;

    use IO::Socket::INET;
    $self->{_socket} = new IO::Socket::INET (
        PeerAddr => 'localhost:5000',
        Proto => 'udp',
        ) or Carp::confess("ERROR in Socket Creation : $!");
    $self->{_sn} = 0;
    $self->{_last_request} = undef;
    print "CLNT: Create Client instance\n" if $trace;
    return $self;
}

our $_instance = undef;
sub get {
    $_instance = new Client unless defined($_instance);
    return $_instance;
}
sub get_last_request {
    my $self = shift;
    return $self->{_last_request};
}
sub _new_sn {
    my $self = shift;
    return $self->{_sn} = ($self->{_sn} + 1) % 256;
}
sub request {
    my $self = shift;
    my $sn = $self->_new_sn();
    use Spike_vcs::Request;
    $self->{_last_request} = new Request ($sn, @_);

    my $rin = '';
    vec($rin, fileno($self->{_socket}), 1) = 1;
    my $win = '';
    my $ein = $rin | $win;
    my $timeout = 1;
    my $received = undef;
    for (;;) {
        $self->{_socket}->send($self->{_last_request}->serialize());
        my ($rout, $wout, $eout);
        my $nfound = select($rout=$rin, $wout=$win, $eout=$ein, $timeout);
        next unless $nfound && vec($rout, fileno($self->{_socket}), 1);
        $self->{_socket}->recv($received, 1024);
        use Spike_vcs::ACK;
        my $ack = deserialize ACK ($received);
        if (defined($ack) && ($ack->{sn} == $sn)) {
            printf("CLNT: Received ACK %s\n", $ack->to_string()) if $trace;
            return $ack;
        }
    }
}
1;