use strict;
use warnings;
use constant EPS => 0.0000001;
use Scalar::Util qw(looks_like_number);

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

sub map_float_value {
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
    die "value must be finite number" unless defined $value && looks_like_number($value);

    my $v = 0.0 + $value;
    die "value must be finite number" if $v != $v || $v == 9**9**9 || $v == -9**9**9;

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

sub map_boolean_value {
    my (%args) = @_;
    my $value = $args{value};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;
    my $false_value = exists $args{false_value} ? $args{false_value} : $output_min;
    my $true_value = exists $args{true_value} ? $args{true_value} : $output_max;

    die "value must be a non-missing boolean" unless defined $value && ($value eq '0' || $value eq '1' || $value == 0 || $value == 1);
    die "output_min must be less than output_max" if $output_min >= $output_max;
    die "output values must be numeric" unless looks_like_number($output_min) && looks_like_number($output_max) && looks_like_number($false_value) && looks_like_number($true_value);
    die "output values must be finite" if $output_min != $output_min || $output_max != $output_max || $false_value != $false_value || $true_value != $true_value;
    die "false_value/true_value must be within output range" if $false_value < $output_min || $false_value > $output_max || $true_value < $output_min || $true_value > $output_max;
    die "false_value and true_value must be different" if $false_value == $true_value;

    return ($value eq '1' || $value == 1) ? $true_value : $false_value;
}

sub map_categorical_value {
    my (%args) = @_;
    my $value = $args{value};
    my $vocabulary = $args{vocabulary};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;

    die "vocabulary must be an array reference" unless ref($vocabulary) eq 'ARRAY';
    die "vocabulary must not be empty" unless @{$vocabulary};
    die "output_min must be less than output_max" if $output_min >= $output_max;
    die "output values must be numeric" unless looks_like_number($output_min) && looks_like_number($output_max);
    die "output values must be finite" if $output_min != $output_min || $output_max != $output_max;
    die "value must be a non-reference string token" if !defined $value || ref($value) ne '';

    my %seen;
    my @tokens = @{$vocabulary};
    for my $token (@tokens) {
        die "vocabulary tokens must be non-reference strings" if !defined $token || ref($token) ne '';
        die "duplicate vocabulary token $token" if $seen{$token}++;
    }

    my $index = -1;
    for my $i (0 .. $#tokens) {
        if ($tokens[$i] eq $value) {
            $index = $i;
            last;
        }
    }
    die "unknown categorical token $value" if $index < 0;

    if (@tokens == 1) {
        return ($output_min + $output_max) / 2.0;
    }

    my $span = $output_max - $output_min;
    return $output_min + (($index) / ($#tokens)) * $span;
}

sub map_text_value {
    my (%args) = @_;
    my $value       = $args{value};
    my $mode        = exists $args{mode} ? $args{mode} : "codepoint";
    my $alphabet    = exists $args{alphabet} ? $args{alphabet} : "";
    my $output_min  = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max  = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip        = $args{clip} ? 1 : 0;
    my $allow_empty = $args{allow_empty} ? 1 : 0;

    die "value must be a non-reference string" if !defined $value || ref($value) ne '';
    die "mode must be a non-empty string" if !defined $mode || ref($mode) ne '' || $mode eq '';
    die "output values must be numeric" unless looks_like_number($output_min) && looks_like_number($output_max);
    die "output values must be finite" if $output_min != $output_min || $output_max != $output_max;
    die "output_min must be less than output_max" if $output_min >= $output_max;

    $mode = lc $mode;
    die "unsupported text mode $mode" unless $mode eq "codepoint" || $mode eq "byte" || $mode eq "alphabet";
    die "empty text input is invalid by default; set allow_empty=1 to map empty text." if length($value) == 0 && !$allow_empty;
    return [] if length($value) == 0;

    if ($mode eq "byte") {
        return map_bytes_value(
            value => $value,
            output_min => $output_min,
            output_max => $output_max,
            clip => $clip,
            allow_empty => $allow_empty,
        );
    }

    my @tokens = split //, $value;
    my @mapped;

    if ($mode eq "alphabet") {
        die "alphabet must be a non-empty string for alphabet mode" if !defined $alphabet || ref($alphabet) ne '' || $alphabet eq '';
        my %seen;
        my @alphabet_tokens = split //, $alphabet;
        for my $token (@alphabet_tokens) {
            die "duplicate alphabet token $token" if $seen{$token}++;
        }

        for my $index (0 .. $#tokens) {
            my $position = -1;
            for my $candidate (0 .. $#alphabet_tokens) {
                if ($alphabet_tokens[$candidate] eq $tokens[$index]) {
                    $position = $candidate;
                    last;
                }
            }
            die "unknown text token $tokens[$index]" if $position < 0;
            push @mapped, @alphabet_tokens == 1
                ? (($output_min + $output_max) / 2.0)
                : $output_min + (($position) / ($#alphabet_tokens)) * ($output_max - $output_min);
        }
        return \@mapped;
    }

    die "alphabet must be empty unless mode is alphabet" if defined $alphabet && $alphabet ne "";
    for my $index (0 .. $#tokens) {
        my $codepoint = ord($tokens[$index]);
        if ($codepoint > 255) {
            die "text codepoint $codepoint at index $index is above input_range upper bound 255; enable clip to clamp." unless $clip;
            $codepoint = 255;
        }
        push @mapped, $output_min + (($codepoint - 0.0) / 255.0) * ($output_max - $output_min);
    }

    return \@mapped;
}

sub map_bytes_value {
    my (%args) = @_;
    my $value      = $args{value};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip       = $args{clip} ? 1 : 0;
    my $allow_empty = $args{allow_empty} ? 1 : 0;

    die "output_min must be less than output_max" if $output_min >= $output_max;
    die "output values must be numeric" unless looks_like_number($output_min) && looks_like_number($output_max);
    die "output values must be finite" if $output_min != $output_min || $output_max != $output_max;
    die "value must be a string or array reference" unless defined $value && (ref($value) eq '' || ref($value) eq 'ARRAY');

    my @bytes;
    if (ref($value) eq '') {
        @bytes = unpack('C*', $value);
    } else {
        @bytes = @{$value};
    }

    die "empty bytes value is invalid by default; set allow_empty=1 to map empty bytes." if !@bytes && !$allow_empty;

    my @mapped;
    for my $index (0 .. $#bytes) {
        my $byte = $bytes[$index];
        die "bytes[$index] must be an integer" unless defined $byte && int($byte) == $byte;
        if ($byte < 0) {
            die "byte value $byte at index $index is below input_range lower bound 0; enable clip to clamp." unless $clip;
            $byte = 0;
        }
        if ($byte > 255) {
            die "byte value $byte at index $index is above input_range upper bound 255; enable clip to clamp." unless $clip;
            $byte = 255;
        }
        push @mapped, $output_min + (($byte - 0.0) / 255.0) * ($output_max - $output_min);
    }

    return \@mapped;
}

sub _validate_map_object_bool {
    my ($value, $name) = @_;
    die "$name must be a boolean-like flag" unless !defined $value || $value eq 0 || $value eq 1;
    return $value ? 1 : 0;
}

sub map_object_value {
    my (%args) = @_;
    my $value      = $args{value};
    my $schema     = $args{schema};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip       = _validate_map_object_bool($args{clip}, "clip");
    my $allow_unknown_fields = _validate_map_object_bool($args{allow_unknown_fields}, "allow_unknown_fields");
    my $allow_empty = _validate_map_object_bool($args{allow_empty}, "allow_empty");

    die "schema and value must be HASH references" unless ref($value) eq 'HASH' && ref($schema) eq 'HASH';
    die "schema must not be empty" unless keys %{$schema};
    if (!$allow_empty) {
        die "empty object is invalid by default; set allow_empty=1 to map empty objects." unless keys %{$value};
    }

    my @schema_fields = sort keys %{$schema};
    my @missing_fields;
    for my $field (@schema_fields) {
        die "schema entry for $field must include a non-empty family string"
            unless ref($schema->{$field}) eq 'HASH'
            && exists $schema->{$field}->{family}
            && defined $schema->{$field}->{family}
            && ref($schema->{$field}->{family}) eq ''
            && length $schema->{$field}->{family};
        push @missing_fields, $field unless exists $value->{$field};
    }

    if (@missing_fields) {
        die "missing required object field(s): " . join(", ", @missing_fields);
    }

    if (!$allow_unknown_fields) {
        my @unknown_fields;
        for my $field (sort keys %{$value}) {
            next if exists $schema->{$field};
            push @unknown_fields, $field;
        }
        die "unknown object field(s): " . join(", ", @unknown_fields) if @unknown_fields;
    }

    my %mapped;
    for my $field (@schema_fields) {
        $mapped{$field} = map_object_field(
            field       => $field,
            value       => $value->{$field},
            spec        => $schema->{$field},
            output_min  => $output_min,
            output_max  => $output_max,
            clip        => $clip,
        );
    }

    return \%mapped;
}

sub map_object_field {
    my (%args) = @_;
    my $field      = exists $args{field} ? $args{field} : "field";
    my $value      = $args{value};
    my $spec       = $args{spec};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip       = exists $args{clip} ? _validate_map_object_bool($args{clip}, "clip") : 0;

    die "field mapper for $field must be a hash reference" unless ref($spec) eq 'HASH';
    die "field mapper for $field must define a family" unless exists $spec->{family};
    my $family = $spec->{family};
    die "field mapper for $field requires a non-empty family string"
        unless defined $family && ref($family) eq '' && length $family;

    if ($family eq 'integer') {
        return map_integer_value(
            value => $value,
            input_min => $spec->{input_min},
            input_max => $spec->{input_max},
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
            clip => exists $spec->{clip} ? _validate_map_object_bool($spec->{clip}, "clip") : $clip,
        );
    }

    if ($family eq 'float') {
        return map_float_value(
            value => $value,
            input_min => $spec->{input_min},
            input_max => $spec->{input_max},
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
            clip => exists $spec->{clip} ? _validate_map_object_bool($spec->{clip}, "clip") : $clip,
        );
    }

    if ($family eq 'boolean') {
        return map_boolean_value(
            value => $value,
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
            false_value => exists $spec->{false_value} ? $spec->{false_value} : $output_min,
            true_value => exists $spec->{true_value} ? $spec->{true_value} : $output_max,
        );
    }

    if ($family eq 'text') {
        return map_text_value(
            value => $value,
            mode => exists $spec->{mode} ? $spec->{mode} : "codepoint",
            alphabet => exists $spec->{alphabet} ? $spec->{alphabet} : "",
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
            clip => exists $spec->{clip} ? _validate_map_object_bool($spec->{clip}, "clip") : $clip,
            allow_empty => exists $spec->{allow_empty} ? _validate_map_object_bool($spec->{allow_empty}, "allow_empty") : 0,
        );
    }

    if ($family eq 'bytes') {
        return map_bytes_value(
            value => $value,
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
            clip => exists $spec->{clip} ? _validate_map_object_bool($spec->{clip}, "clip") : $clip,
            allow_empty => _validate_map_object_bool($spec->{allow_empty}, "allow_empty"),
        );
    }

    if ($family eq 'categorical') {
        return map_categorical_value(
            value => $value,
            vocabulary => $spec->{vocabulary},
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
        );
    }

    if ($family eq 'sequence') {
        my $sequence_mapper = $spec->{mapper};
        die "map field $field requires a nested mapper specification under key 'mapper'" unless ref($sequence_mapper) eq 'HASH';
        return map_object_sequence_value(
            values => $value,
            mapper => $sequence_mapper,
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
            clip => exists $spec->{clip} ? _validate_map_object_bool($spec->{clip}, "clip") : $clip,
            allow_empty => _validate_map_object_bool($spec->{allow_empty}, "allow_empty"),
        );
    }

    if ($family eq 'object') {
        my $nested_schema = $spec->{schema};
        return map_object_value(
            value => $value,
            schema => $nested_schema,
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
            clip => exists $spec->{clip} ? _validate_map_object_bool($spec->{clip}, "clip") : $clip,
            allow_unknown_fields => _validate_map_object_bool($spec->{allow_unknown_fields}, "allow_unknown_fields"),
            allow_empty => _validate_map_object_bool($spec->{allow_empty}, "allow_empty"),
        );
    }

    if ($family eq 'temporal') {
        return map_temporal_value(
            value => $value,
            input_min => $spec->{input_min},
            input_max => $spec->{input_max},
            output_min => exists $spec->{output_min} ? $spec->{output_min} : $output_min,
            output_max => exists $spec->{output_max} ? $spec->{output_max} : $output_max,
            clip => exists $spec->{clip} ? _validate_map_object_bool($spec->{clip}, "clip") : $clip,
        );
    }

    die "unsupported field mapper family '$family' for $field";
}

sub map_object_sequence_value {
    my (%args) = @_;
    my $values      = $args{values};
    my $mapper      = $args{mapper};
    my $output_min  = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max  = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip        = exists $args{clip} ? _validate_map_object_bool($args{clip}, "clip") : 0;
    my $allow_empty = _validate_map_object_bool($args{allow_empty}, "allow_empty");

    die "values must be an array reference" unless ref($values) eq 'ARRAY';
    die "sequence mapper must be a hash reference" unless ref($mapper) eq 'HASH';
    die "empty sequence input is invalid by default" unless @$values || $allow_empty;

    my @mapped;
    for my $item (@{$values}) {
        if (ref($item) eq 'ARRAY') {
            push @mapped, map_object_sequence_value(
                values => $item,
                mapper => $mapper,
                output_min => $output_min,
                output_max => $output_max,
                clip => $clip,
                allow_empty => $allow_empty,
            );
            next;
        }

        push @mapped, map_object_field(
            value => $item,
            spec => $mapper,
            output_min => $output_min,
            output_max => $output_max,
            clip => $clip,
        );
    }

    return \@mapped;
}

sub map_temporal_value {
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
    die "value must be a finite Unix-millisecond integer" unless defined $value && looks_like_number($value) && int($value) == $value;

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

sub map_integer_sequence_value {
    my (%args) = @_;
    my $values     = $args{values};
    my $input_min  = $args{input_min};
    my $input_max  = $args{input_max};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip       = $args{clip} ? 1 : 0;

    die "values must be an array reference" unless ref($values) eq 'ARRAY';
    die "empty sequence input is invalid by default" unless @{$values};

    my @mapped;
    for my $item (@{$values}) {
        if (ref($item) eq 'ARRAY') {
            push @mapped, map_integer_nested_sequence_value(
                values => $item,
                input_min => $input_min,
                input_max => $input_max,
                output_min => $output_min,
                output_max => $output_max,
                clip => $clip,
            );
            next;
        }

        push @mapped, map_integer_value(
            value => $item,
            input_min => $input_min,
            input_max => $input_max,
            output_min => $output_min,
            output_max => $output_max,
            clip => $clip,
        );
    }
    return \@mapped;
}

sub map_integer_nested_sequence_value {
    my (%args) = @_;
    my $values     = $args{values};
    my $input_min  = $args{input_min};
    my $input_max  = $args{input_max};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip       = $args{clip} ? 1 : 0;

    die "values must be an array reference" unless ref($values) eq 'ARRAY';
    die "empty sequence input is invalid by default" unless @{$values};

    my @mapped;
    for my $item (@{$values}) {
        die "nested sequence elements must be array references" unless ref($item) eq 'ARRAY';
        push @mapped, map_integer_sequence_value(
            values => $item,
            input_min => $input_min,
            input_max => $input_max,
            output_min => $output_min,
            output_max => $output_max,
            clip => $clip,
        );
    }
    return \@mapped;
}

sub map_image_value {
    my (%args) = @_;
    my $value      = $args{value};
    my $output_min = exists $args{output_min} ? $args{output_min} : -1.0;
    my $output_max = exists $args{output_max} ? $args{output_max} : 1.0;
    my $clip       = $args{clip} ? 1 : 0;
    my $allow_empty = $args{allow_empty} ? 1 : 0;

    if (ref($value) eq 'ARRAY') {
        if (@{$value} == 0) {
            die "empty image input is invalid by default; set allow_empty=1" unless $allow_empty;
            return [];
        }

        my @mapped;
        for my $item (@{$value}) {
            if (ref($item) eq 'ARRAY') {
                push @mapped, map_image_value(
                    value => $item,
                    output_min => $output_min,
                    output_max => $output_max,
                    clip => $clip,
                    allow_empty => $allow_empty,
                );
            } else {
                push @mapped, map_bytes_value(
                    value => [$item],
                    output_min => $output_min,
                    output_max => $output_max,
                    clip => $clip,
                    allow_empty => $allow_empty,
                )->[0];
            }
        }
        return \@mapped;
    }

    return map_bytes_value(
        value => $value,
        output_min => $output_min,
        output_max => $output_max,
        clip => $clip,
        allow_empty => $allow_empty,
    );
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
    my $mapped_again = map_integer_value(
        value => 50,
        input_min => 0,
        input_max => 100,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    );
    die "expected repeated 0" unless abs($mapped_again - 0.0) < EPS;

    my $float_mapped = map_float_value(
        value => 0.5,
        input_min => 0.0,
        input_max => 1.0,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    );
    die "expected float 0" unless abs($float_mapped - 0.0) < EPS;
    die "expected float repeated 0" unless abs(map_float_value(
        value => 0.5,
        input_min => 0.0,
        input_max => 1.0,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    ) - 0.0) < EPS;

    my $boolean_true = map_boolean_value(value => 1, output_min => -1.0, output_max => 1.0);
    my $boolean_false = map_boolean_value(value => 0, output_min => -1.0, output_max => 1.0);
    die "expected boolean true" unless abs($boolean_true - 1.0) < EPS;
    die "expected boolean false" unless abs($boolean_false + 1.0) < EPS;

    my $bytes_mapped = map_bytes_value(value => "\x00\x7F\xFF", output_min => -1.0, output_max => 1.0);
    die "expected three bytes" unless scalar(@{$bytes_mapped}) == 3;
    die "expected bytes first" unless abs($bytes_mapped->[0] + 1.0) < EPS;
    die "expected bytes repeat" unless abs(map_bytes_value(value => "\x00\x7F\xFF", output_min => -1.0, output_max => 1.0)->[1] - (((127.0 / 255.0) * 2.0) - 1.0)) < EPS;

    my $categorical_first = map_categorical_value(value => "cat", vocabulary => ["cat", "dog"], output_min => -1.0, output_max => 1.0);
    my $categorical_second = map_categorical_value(value => "dog", vocabulary => ["cat", "dog"], output_min => -1.0, output_max => 1.0);
    die "expected categorical first" unless abs($categorical_first + 1.0) < EPS;
    die "expected categorical second" unless abs($categorical_second - 1.0) < EPS;
    die "expected categorical repeat" unless abs(map_categorical_value(value => "dog", vocabulary => ["cat", "dog"], output_min => -1.0, output_max => 1.0) - 1.0) < EPS;

    my $text_mapped = map_text_value(value => "abc", mode => "alphabet", alphabet => "abc", output_min => -1.0, output_max => 1.0);
    die "expected text length 3" unless scalar(@{$text_mapped}) == 3;
    die "expected text first" unless abs($text_mapped->[0] + 1.0) < EPS;
    die "expected text middle" unless abs($text_mapped->[1]) < EPS;
    die "expected text last" unless abs($text_mapped->[2] - 1.0) < EPS;
    die "expected text repeat" unless abs(map_text_value(value => "abc", mode => "alphabet", alphabet => "abc")->[1]) < EPS;
    my $text_unknown_failed = 0;
    eval { map_text_value(value => "abd", mode => "alphabet", alphabet => "abc"); };
    $text_unknown_failed = 1 if $@;
    die "expected unknown text token failure" unless $text_unknown_failed;

    my $temporal_mapped = map_temporal_value(
        value => 1700000050000,
        input_min => 1700000000000,
        input_max => 1700000100000,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    );
    die "expected temporal 0" unless abs($temporal_mapped - 0.0) < EPS;
    die "expected temporal repeat 0" unless abs(map_temporal_value(
        value => 1700000050000,
        input_min => 1700000000000,
        input_max => 1700000100000,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    ) - 0.0) < EPS;

    my $categorical_failed = 0;
    eval { map_categorical_value(value => "missing", vocabulary => ["cat"], output_min => -1.0, output_max => 1.0); };
    $categorical_failed = 1 if $@;
    die "expected unknown categorical token failure" unless $categorical_failed;

    my $sequence_mapped = map_integer_sequence_value(
        values => [0, 50, 100],
        input_min => 0,
        input_max => 100,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    );
    die "expected sequence length 3" unless scalar(@{$sequence_mapped}) == 3;
    die "expected sequence first" unless abs($sequence_mapped->[0] + 1.0) < EPS;
    die "expected sequence repeat" unless abs(map_integer_sequence_value(
        values => [0, 50, 100],
        input_min => 0,
        input_max => 100,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    )->[1]) < EPS;

    my $nested_sequence_mapped = map_integer_nested_sequence_value(
        values => [[0, 50], [100]],
        input_min => 0,
        input_max => 100,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
    );
    die "expected nested sequence rows 2" unless scalar(@{$nested_sequence_mapped}) == 2;
    die "expected nested sequence value" unless abs($nested_sequence_mapped->[0][1]) < EPS;

    my $image_mapped = map_image_value(value => "\x00\x7F\xFF", output_min => -1.0, output_max => 1.0);
    die "expected image bytes length 3" unless scalar(@{$image_mapped}) == 3;
    die "expected image first" unless abs($image_mapped->[0] + 1.0) < EPS;
    die "expected image repeat" unless abs(map_image_value(value => "\x00\x7F\xFF", output_min => -1.0, output_max => 1.0)->[1] - (((127.0 / 255.0) * 2.0) - 1.0)) < EPS;

    my $object_schema = {
        age => { family => "integer", input_min => 0, input_max => 120 },
        active => { family => "boolean" },
        profile => {
            family => "object",
            schema => {
                score => { family => "integer", input_min => 0, input_max => 100 },
                tag => { family => "categorical", vocabulary => ["new", "vip", "admin"] },
            },
        },
        history => {
            family => "sequence",
            mapper => { family => "integer", input_min => 0, input_max => 2 },
            allow_empty => 0,
        },
    };

    my $object_value = {
        age => 30,
        active => 1,
        profile => {
            score => 75,
            tag => "vip",
        },
        history => [0, 1, [0, 2]],
    };
    my $object_mapped = map_object_value(
        value => $object_value,
        schema => $object_schema,
        output_min => -1.0,
        output_max => 1.0,
        clip => 0,
        allow_unknown_fields => 0,
        allow_empty => 0,
    );
    die "expected mapped object key count 4" unless scalar(keys %{$object_mapped}) == 4;
    die "expected mapped object age" unless abs($object_mapped->{age} + 0.5) < EPS;
    die "expected mapped object bool" unless abs($object_mapped->{active} - 1.0) < EPS;
    die "expected mapped object category" unless abs($object_mapped->{profile}->{tag} - 0.0) < EPS;
    die "expected mapped object nested sequence" unless abs($object_mapped->{history}[2][1] - 1.0) < EPS;

    my $object_mapped_repeat = map_object_value(
        value => $object_value,
        schema => $object_schema,
        clip => 0,
        allow_unknown_fields => 0,
        allow_empty => 0,
    );
    die "expected map object repeat age" unless abs($object_mapped_repeat->{age} + 0.5) < EPS;

    my $object_unknown_failed = 0;
    eval {
        map_object_value(
            value => { %{$object_value}, extra => 1 },
            schema => $object_schema,
            clip => 0,
            allow_unknown_fields => 0,
            allow_empty => 0,
        );
    };
    $object_unknown_failed = 1 if $@;
    die "expected unknown object field failure" unless $object_unknown_failed;

    my $object_missing_failed = 0;
    eval {
        map_object_value(
            value => {
                active => 1,
                profile => {
                    score => 75,
                    tag => "vip",
                },
                history => [0],
            },
            schema => $object_schema,
            clip => 0,
            allow_unknown_fields => 0,
            allow_empty => 0,
        );
    };
    $object_missing_failed = 1 if $@;
    die "expected missing object field failure" unless $object_missing_failed;
}
