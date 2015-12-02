package ACK;
sub new {
    my $class = shift;
    my $self = {};
    @{$self}{qw(sn cmd data)[0 .. $#_]} = @_;
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
    if ($self->{cmd} =~ /read/) {
        return pack('C1 A1 N1', $self->{sn} + 0, 'r', $self->{data} + 0);
    } elsif ($self->{cmd} =~ /reset/) {
        return pack('C1 A1 N1', $self->{sn} + 0, 'R', $self->{data} + 0);
    } elsif ($self->{cmd} =~ /write/) {
        return pack('C1 A1', $self->{sn} + 0, 'w');
    } else {
        return pack('C1 A1', $self->{sn} + 0, 'c');
    }
}
sub deserialize {
    my $class = shift;
    my $buffer = shift;
    my ($sn, $cmd, $rest) = unpack('C1 A1 a*', $buffer);
    my $res = {sn => $sn};
    my %subs = ('r' => 'read', 'w' => 'write', 'R' => 'reset', 'c' => 'skip');
    $res->{cmd} = $subs{$cmd};
    if ($cmd =~ /^(?:R|r)$/) {
        my ($data) = unpack('N', $rest);
        $res->{data} = $data;
    }
    return bless $res, $class;
}
1;