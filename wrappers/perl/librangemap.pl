use strict;
use warnings;
use constant EPS => 0.0000001;

sub map_integer_value {
    my (%args) = @_;
    my $value      = $args{value};
    my $input_min  = $args{input_min};
    my $input_max  = $args{input_max};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip       = $args{clip} ? 1 : 0;

    die "input_min, input_max required" unless defined $input_min && defined $input_max;
    die "output_min and output_max required" unless defined $output_min && defined $output_max;
    die "input_min must be less than input_max" if $input_min >= $input_max;
    die "output_min must be less than output_max" if $output_min >= $output_max;
    die "value must be finite integer" unless defined $value && int($value) == $value;

    my $v = int($value);
    if ($clip) {
        $v = $input_min if $v < $input_min;
        $v = $input_max if $v > $input_max;
    } else {
        die "value out of range" if $v < $input_min || $v > $input_max;
    }

    my $span = $input_max - $input_min;
    my $out_span = $output_max - $output_min;
    return $output_min + (($v - $input_min) / $span) * $out_span;
}

if (!caller()) {
    my $mapped = map_integer_value(
        value => 50,
        input_min => 0,
        input_max => 100,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    );
    die "expected 0" unless abs($mapped - 0.0) < EPS;
}
