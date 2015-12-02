package Request;

sub new {
    my $class = shift;
    my $self = {};
    @{$self}{qw(sn cmd addr size data)[0 .. $#_]} = @_;
    return bless $self, $class;
}
sub deserialize {
    my $class = shift;
    my $unparsed = shift;
    my $common_request = qr@^(?<sn>[^:]+):(?<cmd>reset|skip|read|write)(?::(?<addr>[^:]+):(?<size>[^:]+)(?::(?<data>.+))?)?$@;
    return undef unless $unparsed =~ /$common_request/;
    return bless {%+}, $class;
}
sub to_string {
    my $self = shift;
    my @fields = @{$self}{qw(sn cmd)};
    if (exists $self->{addr}) {
        push @fields, @{$self}{qw(addr size)};
        if (exists  $self->{data}) {
            push @fields, $self->{'data'};
        }
    }
    return join(':', @fields);
}
sub serialize {
    my $self = shift;
    return $self->to_string();
}
1;