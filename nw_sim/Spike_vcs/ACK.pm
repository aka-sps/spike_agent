package ACK;
sub new {
    my $class = shift;
    my $self = {};
    @{$self}{qw(sn cmd data)[0 .. $#_]} = @_;
    return bless $self, $class;
}
sub deserialize {
    my $class = shift;
    my $buffer = shift;
    my ($sn, $cmd, $rest) = unpack('C1 A1 a*', $buffer);
    my $res = {sn => $sn};
    my %decode = ('r' => 'read', 'w' => 'write', 'R' => 'reset', 'c' => 'skip');
    $res->{cmd} = exists $decode{$cmd} ? $decode{$cmd} : 'c';
    if ($cmd =~ /^(?:R|r)$/) {
        my ($data) = unpack('x2 N', $rest);
        $res->{data} = $data;
    }
    return bless $res, $class;
}

sub serialize {
    my $self = shift;
    my $cmd = 'c';
    my %encode = ('read' => 'r', 'reset' => 'R', 'write' => 'w', 'skip' => 'c');
    $cmd = $encode{$self->{cmd}} if exists $encode{$self->{cmd}};
    if ($self->{cmd} =~ /^(?:read|reset)$/) {
        return pack('C1 A1 x2 N1', $self->{sn}, $cmd, $self->{data} + 0);
    } else {
        return pack('C1 A1', $self->{sn}, $cmd);
    }
}

sub to_string {
    my $self = shift;
    my @fields = @{$self}{qw(sn cmd)};
    if (exists $self->{'data'}) {
        push @fields, $self->{'data'};
    }        
    return join(':', @fields);
}
1;