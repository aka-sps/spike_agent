package Server;
use fields qw(_socket _last_request _last_ack);

our $trace = 0;

sub _create {
    my Server $self = shift;
    unless (ref $self) {
        $self = fields::new($self);
    }
    use IO::Socket::INET;
    $self->{_socket} = new IO::Socket::INET (
        LocalPort => '5000',
        Proto => 'udp',
        ) or Carp::confess("ERROR in Socket Creation : $!");
    $self->{_last_request} = undef;
    $self->{_last_ack} = undef;
    print "SRV: Create Server instance\n" if $trace;
    return $self;
}
our $_instance = undef;
sub get {
    $_instance = _create Server unless defined($_instance);
    return $_instance;
}
sub get_last_request {
    my $self = shift;
    return $self->{_last_request};
}
sub get_next_request {
    my $self = shift;
    use Spike_vcs::Request;
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
    use Spike_vcs::ACK;
    $self->{_last_ack} = new ACK ($self->get_last_request()->{sn}, @_);
}
sub send_ack {
    my $self = shift;
    print "SRV: Send ACK to (", $self->{_socket}->peerhost(), ", ", $self->{_socket}->peerport(), "): ", $self->{_last_ack}->serialize(), "\n" if $trace;
    $self->{_socket}->send($self->{_last_ack}->serialize());
}
1;
