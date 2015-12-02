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
    return $self->to_string();
}
sub deserialize {
    my $class = shift;
    my $buffer = shift;
    return undef unless $buffer =~ /^(?<sn>[^:]+):(?<cmd>[^:]+)(?::(?<data>.*))?$/;
    return bless {%+}, $class;
}
1;