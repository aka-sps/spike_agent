package Request;

sub new {
    my $class = shift;
    my $self = {};
    @{$self}{qw(sn cmd addr size data)[0 .. $#_]} = @_;
    return bless $self, $class;
}
sub deserialize {
    my $class = shift;
    my $buffer = shift;
    my ($sn, $cmd, $rest) = unpack('C1 A1 a*', $buffer);
    my $res = {sn => $sn, cmd =>'skip'};
    my %decode = ('r' => 'read', 'w' => 'write', 'R' => 'reset', 'c' => 'skip');
    $res->{cmd} = $decode{$cmd} if exists $decode{$cmd};
    if ($cmd =~ /^(?:r|w)$/) {
        my ($size, $addr, $rest1) = unpack('C1 x1 N1 a*', $rest);
        @{$res}{qw(addr size)} = ($addr, $size);
        if ($cmd =~ /^(?:w)$/) {
            my ($data) = unpack('N1', $rest1);
            $res->{data} = $data;
        }
    }
    return bless $res, $class;
}
sub serialize {
    my $self = shift;
    my %encode = ('read' => 'r', 'reset' => 'R', 'write' => 'w', 'skip' => 'c');
    my $cmd = exists $encode{$self->{cmd}} ? $encode{$self->{cmd}} : 'c';
    if ($self->{cmd} =~ /^(?:write)$/) {
        return pack('C1 A1 C1 x1 N1 N1', $self->{sn}, $cmd, @{$self}{qw(size addr data)});
    } elsif ($self->{cmd} =~ /^(?:read)$/) {
        return pack('C1 A1 C1 x1 N1', $self->{sn}, $cmd, @{$self}{qw(size addr)});
    } else {
        return pack('C1 A1', $self->{sn}, $cmd);
    }
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
1;