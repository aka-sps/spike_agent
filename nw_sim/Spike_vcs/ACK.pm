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
    return undef unless length($buffer) >= 2;
    my ($sn, $cmd, $rest) = unpack('C1 C1 a*', $buffer);
    my $res = {sn => $sn};
    my %decode = (1 => 'read', 2 => 'write', 3 => 'reset', 0 => 'skip');
    $res->{cmd} = exists $decode{$cmd} ? $decode{$cmd} : 0;
    if ($cmd == 1 || $cmd == 3) {
        return undef unless length($rest) == 6;
        my ($data) = unpack('x2 N1', $rest);
        $res->{data} = $data;
    }
    return bless $res, $class;
}

sub serialize {
    my $self = shift;
    my $cmd = 'c';
    my %encode = ('read' => 1, 'reset' => 3, 'write' => 2, 'skip' => 0);
    $cmd = $encode{$self->{cmd}} if exists $encode{$self->{cmd}};
    if ($self->{cmd} =~ /^(?:read|reset)$/) {
        return pack('C1 C1 x2 N1', $self->{sn}, $cmd, $self->{data} + 0);
    } else {
        return pack('C1 C1', $self->{sn}, $cmd);
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