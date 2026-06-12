<?php

declare(strict_types=1);

function decode_utf8_codepoints(string $value): array
{
    $bytes = unpack("C*", $value);
    if ($bytes === false) {
        return [];
    }

    $codepoints = [];
    $index = 1;
    $length = count($bytes);

    while ($index <= $length) {
        $byte1 = $bytes[$index];

        if (($byte1 & 0x80) === 0x00) {
            $codepoints[] = $byte1;
            $index += 1;
            continue;
        }

        if (($byte1 & 0xE0) === 0xC0) {
            if ($index + 1 > $length) {
                throw new InvalidArgumentException("invalid UTF-8 sequence in string");
            }
            $byte2 = $bytes[$index + 1];
            if (($byte2 & 0xC0) !== 0x80) {
                throw new InvalidArgumentException("invalid UTF-8 continuation byte");
            }
            $codepoint = (($byte1 & 0x1F) << 6) | ($byte2 & 0x3F);
            if ($codepoint < 0x80) {
                throw new InvalidArgumentException("overlong UTF-8 sequence");
            }
            $codepoints[] = $codepoint;
            $index += 2;
            continue;
        }

        if (($byte1 & 0xF0) === 0xE0) {
            if ($index + 2 > $length) {
                throw new InvalidArgumentException("invalid UTF-8 sequence in string");
            }
            $byte2 = $bytes[$index + 1];
            $byte3 = $bytes[$index + 2];
            if (($byte2 & 0xC0) !== 0x80 || ($byte3 & 0xC0) !== 0x80) {
                throw new InvalidArgumentException("invalid UTF-8 continuation bytes");
            }
            $codepoint = (($byte1 & 0x0F) << 12) | (($byte2 & 0x3F) << 6) | ($byte3 & 0x3F);
            if ($codepoint < 0x800 || ($codepoint >= 0xD800 && $codepoint <= 0xDFFF)) {
                throw new InvalidArgumentException("invalid UTF-8 codepoint");
            }
            $codepoints[] = $codepoint;
            $index += 3;
            continue;
        }

        if (($byte1 & 0xF8) === 0xF0) {
            if ($index + 3 > $length) {
                throw new InvalidArgumentException("invalid UTF-8 sequence in string");
            }
            $byte2 = $bytes[$index + 1];
            $byte3 = $bytes[$index + 2];
            $byte4 = $bytes[$index + 3];
            if (($byte2 & 0xC0) !== 0x80 || ($byte3 & 0xC0) !== 0x80 || ($byte4 & 0xC0) !== 0x80) {
                throw new InvalidArgumentException("invalid UTF-8 continuation bytes");
            }
            $codepoint = (($byte1 & 0x07) << 18) | (($byte2 & 0x3F) << 12) | (($byte3 & 0x3F) << 6) | ($byte4 & 0x3F);
            if ($codepoint < 0x10000 || $codepoint > 0x10FFFF) {
                throw new InvalidArgumentException("invalid UTF-8 codepoint");
            }
            $codepoints[] = $codepoint;
            $index += 4;
            continue;
        }

        throw new InvalidArgumentException("invalid UTF-8 leading byte");
    }

    return $codepoints;
}

function map_text_value(
    string $value,
    float $output_min = -1.0,
    float $output_max = 1.0,
    string $mode = "codepoint",
    bool $clip = false,
    bool $allow_empty = false,
    ?string $alphabet = null
): array {
    if (!is_finite($output_min) || !is_finite($output_max)) {
        throw new InvalidArgumentException("output range endpoints must be finite");
    }
    if (!is_string($mode)) {
        throw new InvalidArgumentException("mode must be a string");
    }
    if (!is_bool($clip)) {
        throw new InvalidArgumentException("clip must be a boolean");
    }
    if (!is_bool($allow_empty)) {
        throw new InvalidArgumentException("allow_empty must be a boolean");
    }

    if ($output_min >= $output_max) {
        throw new InvalidArgumentException("output_min must be less than output_max");
    }

    if ($mode === "alphabet") {
        if ($alphabet === null || $alphabet === "") {
            throw new InvalidArgumentException("alphabet is required for alphabet mode");
        }
        $alphabet_codepoints = decode_utf8_codepoints($alphabet);
        if (count($alphabet_codepoints) === 0) {
            throw new InvalidArgumentException("alphabet must not be empty");
        }
        $alphabet_map = [];
        $index = 0;
        foreach ($alphabet_codepoints as $codepoint) {
            if (array_key_exists((string)$codepoint, $alphabet_map)) {
                throw new InvalidArgumentException("alphabet must contain unique characters");
            }
            $alphabet_map[(string)$codepoint] = $index;
            $index += 1;
        }
        $values = decode_utf8_codepoints($value);
        $input_min = 0.0;
        $input_max = (float)($index - 1);
    } elseif ($mode === "byte") {
        $values = unpack("C*", $value);
        if ($values === false) {
            $values = [];
        }
        $input_min = 0.0;
        $input_max = 255.0;
    } elseif ($mode === "codepoint") {
        $values = decode_utf8_codepoints($value);
        $input_min = 0.0;
        $input_max = 1114111.0;
    } else {
        throw new InvalidArgumentException("mode must be one of 'codepoint', 'byte', or 'alphabet'");
    }

    if (!$allow_empty && count($values) === 0) {
        throw new OutOfRangeException("empty string is invalid by default; set allow_empty=true to map empty strings.");
    }

    $out_span = $output_max - $output_min;
    $in_span = $input_max - $input_min;
    $mapped = [];

    foreach ($values as $unit) {
        if ($mode === "alphabet") {
            $key = (string)$unit;
            if (!array_key_exists($key, $alphabet_map)) {
                throw new OutOfRangeException(sprintf("unknown character %d for alphabet mode.", $unit));
            }
            $value = (float)$alphabet_map[$key];
        } else {
            $value = (float)$unit;
        }

        if ($clip) {
            if ($value < $input_min) {
                $value = $input_min;
            } elseif ($value > $input_max) {
                $value = $input_max;
            }
        } elseif ($value < $input_min || $value > $input_max) {
            throw new OutOfRangeException("value out of range");
        }

        $mapped[] = $output_min + (($value - $input_min) / $in_span) * $out_span;
    }

    return $mapped;
}

function map_bytes_value(
    mixed $value,
    float $output_min = -1.0,
    float $output_max = 1.0,
    bool $clip = false,
    bool $allow_empty = false
): array {
    if (!is_finite($output_min) || !is_finite($output_max)) {
        throw new InvalidArgumentException("output range endpoints must be finite");
    }
    if (!is_bool($clip)) {
        throw new InvalidArgumentException("clip must be a boolean");
    }
    if (!is_bool($allow_empty)) {
        throw new InvalidArgumentException("allow_empty must be a boolean");
    }
    if ($output_min >= $output_max) {
        throw new InvalidArgumentException("output_min must be less than output_max");
    }

    if (is_string($value)) {
        $values = unpack("C*", $value);
        if ($values === false) {
            $values = [];
        }
    } elseif (is_array($value)) {
        $values = [];
        foreach ($value as $index => $item) {
            if (!is_int($item)) {
                throw new InvalidArgumentException(sprintf("bytes value at index %s must be integer", (string)$index));
            }
            if ($item < 0 || $item > 255) {
                throw new OutOfRangeException(sprintf("bytes value at index %s must be in [0, 255]", (string)$index));
            }
            $values[] = $item;
        }
    } else {
        throw new InvalidArgumentException("value must be a string or array of integers");
    }

    if (!$allow_empty && count($values) === 0) {
        throw new OutOfRangeException("empty bytes input is invalid by default; set allow_empty=true to map empty input.");
    }

    $input_min = 0.0;
    $input_max = 255.0;
    $out_span = $output_max - $output_min;
    $in_span = $input_max - $input_min;
    $mapped = [];

    foreach ($values as $unit) {
        $current = (float)$unit;
        if ($clip) {
            if ($current < $input_min) {
                $current = $input_min;
            } elseif ($current > $input_max) {
                $current = $input_max;
            }
        } elseif ($current < $input_min || $current > $input_max) {
            throw new OutOfRangeException("byte value out of range");
        }
        $mapped[] = $output_min + (($current - $input_min) / $in_span) * $out_span;
    }

    return $mapped;
}

function is_list_array(array $value): bool
{
    $expected_index = 0;
    foreach ($value as $key => $_) {
        if ($key !== $expected_index) {
            return false;
        }
        $expected_index += 1;
    }

    return true;
}

function map_image_scalar_value(
    mixed $value,
    float $output_min = -1.0,
    float $output_max = 1.0,
    bool $clip = false
): float {
    if (!is_int($value) && !is_float($value)) {
        throw new InvalidArgumentException("image pixel values must be numeric");
    }
    if (!is_finite((float)$value)) {
        throw new InvalidArgumentException("image pixel values must be finite");
    }

    $current = (float)$value;
    $input_min = 0.0;
    $input_max = 255.0;

    if ($clip) {
        if ($current < $input_min) {
            $current = $input_min;
        } elseif ($current > $input_max) {
            $current = $input_max;
        }
    } elseif ($current < $input_min || $current > $input_max) {
        throw new OutOfRangeException("image pixel value out of range");
    }

    $out_span = $output_max - $output_min;
    $in_span = $input_max - $input_min;
    return $output_min + (($current - $input_min) / $in_span) * $out_span;
}

function map_image_value(
    mixed $value,
    float $output_min = -1.0,
    float $output_max = 1.0,
    bool $clip = false,
    bool $allow_empty = false
): array {
    if (!is_finite($output_min) || !is_finite($output_max)) {
        throw new InvalidArgumentException("output range endpoints must be finite");
    }
    if (!is_bool($clip)) {
        throw new InvalidArgumentException("clip must be a boolean");
    }
    if (!is_bool($allow_empty)) {
        throw new InvalidArgumentException("allow_empty must be a boolean");
    }
    if ($output_min >= $output_max) {
        throw new InvalidArgumentException("output_min must be less than output_max");
    }

    if (is_string($value)) {
        return map_bytes_value($value, $output_min, $output_max, $clip, $allow_empty);
    }

    if (!is_array($value)) {
        throw new InvalidArgumentException("value must be a string or nested list of numeric pixel values");
    }
    if (!is_list_array($value)) {
        throw new InvalidArgumentException("image values must use list arrays");
    }
    if (!$allow_empty && count($value) === 0) {
        throw new OutOfRangeException("empty image is invalid by default; set allow_empty=true to map empty images.");
    }

    $mapped = [];
    foreach ($value as $item) {
        if (is_array($item)) {
            $mapped[] = map_image_value($item, $output_min, $output_max, $clip, $allow_empty);
            continue;
        }

        $mapped[] = map_image_scalar_value($item, $output_min, $output_max, $clip);
    }

    return $mapped;
}

function map_float_value(
    float $value,
    float $input_min,
    float $input_max,
    float $output_min = -1.0,
    float $output_max = 1.0,
    bool $clip = false
): float {
    if (!is_finite($value)) {
        throw new InvalidArgumentException("value must be finite");
    }
    if (!is_finite($input_min) || !is_finite($input_max)) {
        throw new InvalidArgumentException("input range endpoints must be finite");
    }
    if (!is_finite($output_min) || !is_finite($output_max)) {
        throw new InvalidArgumentException("output range endpoints must be finite");
    }
    if (!is_bool($clip)) {
        throw new InvalidArgumentException("clip must be a boolean");
    }

    if ($input_min >= $input_max) {
        throw new InvalidArgumentException("input_min must be less than input_max");
    }
    if ($output_min >= $output_max) {
        throw new InvalidArgumentException("output_min must be less than output_max");
    }

    if ($clip) {
        if ($value < $input_min) {
            $value = $input_min;
        } elseif ($value > $input_max) {
            $value = $input_max;
        }
    } elseif ($value < $input_min || $value > $input_max) {
        throw new OutOfRangeException("value out of range");
    }

    $span = $input_max - $input_min;
    $out_span = $output_max - $output_min;
    return $output_min + (($value - $input_min) / $span) * $out_span;
}

function map_sequence_value(
    array $value,
    callable $element_mapper,
    bool $allow_empty = false
): array {
    if (!is_bool($allow_empty)) {
        throw new InvalidArgumentException("allow_empty must be a boolean");
    }

    if (!$allow_empty && count($value) === 0) {
        throw new OutOfRangeException("empty sequence is invalid by default; set allow_empty=true to map empty containers.");
    }

    $mapped = [];
    foreach ($value as $item) {
        if (is_array($item)) {
            $mapped[] = map_sequence_value($item, $element_mapper, $allow_empty);
            continue;
        }

        $mapped_value = $element_mapper($item);
        if (!is_float($mapped_value) && !is_int($mapped_value)) {
            throw new InvalidArgumentException("element mapping must return float or int");
        }
        if (!is_finite((float)$mapped_value)) {
            throw new InvalidArgumentException("element mapping must return a finite number");
        }
        $mapped[] = (float)$mapped_value;
    }

    return $mapped;
}

function map_object_value(
    array $value,
    array $schema,
    bool $allow_extra = false,
    bool $allow_empty = false
): array {
    if (count($schema) === 0) {
        throw new InvalidArgumentException("schema must contain at least one mapped field");
    }

    if (!is_bool($allow_extra)) {
        throw new InvalidArgumentException("allow_extra must be a boolean");
    }
    if (!is_bool($allow_empty)) {
        throw new InvalidArgumentException("allow_empty must be a boolean");
    }

    if (!$allow_empty && count($value) === 0) {
        throw new OutOfRangeException("empty object is invalid by default; set allow_empty=true to map empty objects.");
    }

    if (!$allow_empty && count($schema) > count($value) && count(array_intersect_key($value, $schema)) < count($schema)) {
        $missing_fields = [];
        foreach ($schema as $key => $_) {
            if (!array_key_exists($key, $value)) {
                $missing_fields[] = (string)$key;
            }
        }
        throw new OutOfRangeException(sprintf(
            "missing required object field(s): %s",
            implode(", ", $missing_fields)
        ));
    }

    $mapped = [];
    foreach ($schema as $field => $mapper) {
        if (!array_key_exists($field, $value)) {
            throw new OutOfRangeException(sprintf("missing required object field: %s", (string)$field));
        }

        if (!is_callable($mapper)) {
            throw new InvalidArgumentException(sprintf("schema entry for %s must be a callable mapper", (string)$field));
        }

        $mapped_value = $mapper($value[$field]);
        if (!is_float($mapped_value) && !is_int($mapped_value)) {
            throw new InvalidArgumentException(sprintf("object mapper for %s must return float or int", (string)$field));
        }
        if (!is_finite((float)$mapped_value)) {
            throw new InvalidArgumentException(sprintf("object mapper for %s must return a finite number", (string)$field));
        }
        $mapped[(string)$field] = (float)$mapped_value;
    }

    if (!$allow_extra) {
        foreach ($value as $field => $_) {
            if (!array_key_exists($field, $schema)) {
                throw new OutOfRangeException(sprintf("unknown object field: %s", (string)$field));
            }
        }
    }

    return $mapped;
}

function map_integer_value(
    int $value,
    int $input_min,
    int $input_max,
    float $output_min = -1.0,
    float $output_max = 1.0,
    bool $clip = false
): float {
    if (!is_int($input_min) || !is_int($input_max)) {
        throw new InvalidArgumentException("input_min and input_max must be integers");
    }
    if (!is_int($value)) {
        throw new InvalidArgumentException("value must be an integer");
    }
    if (!is_finite($output_min) || !is_finite($output_max)) {
        throw new InvalidArgumentException("output range endpoints must be finite");
    }
    if (!is_bool($clip)) {
        throw new InvalidArgumentException("clip must be a boolean");
    }

    if ($input_min >= $input_max) {
        throw new InvalidArgumentException("input_min must be less than input_max");
    }
    if ($output_min >= $output_max) {
        throw new InvalidArgumentException("output_min must be less than output_max");
    }

    if ($clip) {
        if ($value < $input_min) {
            $value = $input_min;
        } elseif ($value > $input_max) {
            $value = $input_max;
        }
    } elseif ($value < $input_min || $value > $input_max) {
        throw new OutOfRangeException("value out of range");
    }

    $span = $input_max - $input_min;
    $out_span = $output_max - $output_min;
    return $output_min + (($value - $input_min) / $span) * $out_span;
}

function map_boolean_value(
    bool $value,
    float $output_min = -1.0,
    float $output_max = 1.0,
    ?float $false_value = null,
    ?float $true_value = null
): float {
    if (!is_finite($output_min) || !is_finite($output_max)) {
        throw new InvalidArgumentException("output range endpoints must be finite");
    }
    if (!is_null($false_value) && !is_finite($false_value)) {
        throw new InvalidArgumentException("false_value must be finite");
    }
    if (!is_null($true_value) && !is_finite($true_value)) {
        throw new InvalidArgumentException("true_value must be finite");
    }

    $false_value = $false_value ?? $output_min;
    $true_value = $true_value ?? $output_max;

    if ($output_min >= $output_max) {
        throw new InvalidArgumentException("output_min must be less than output_max");
    }
    if ($false_value < $output_min || $false_value > $output_max) {
        throw new InvalidArgumentException("false_value must be within output range");
    }
    if ($true_value < $output_min || $true_value > $output_max) {
        throw new InvalidArgumentException("true_value must be within output range");
    }
    if ($false_value === $true_value) {
        throw new InvalidArgumentException("false_value and true_value must differ");
    }

    return $value ? $true_value : $false_value;
}

function map_temporal_value(
    mixed $value,
    float $input_min,
    float $input_max,
    float $output_min = -1.0,
    float $output_max = 1.0,
    bool $clip = false
): float {
    if (!is_finite($input_min) || !is_finite($input_max)) {
        throw new InvalidArgumentException("input range endpoints must be finite");
    }
    if (!is_finite($output_min) || !is_finite($output_max)) {
        throw new InvalidArgumentException("output range endpoints must be finite");
    }
    if (!is_bool($clip)) {
        throw new InvalidArgumentException("clip must be a boolean");
    }
    if ($input_min >= $input_max) {
        throw new InvalidArgumentException("input_min must be less than input_max");
    }
    if ($output_min >= $output_max) {
        throw new InvalidArgumentException("output_min must be less than output_max");
    }

    if ($value instanceof DateTimeInterface) {
        $timestamp = (float)$value->format("U");
        $fraction = (float)$value->format("u") / 1000000.0;
        $current = $timestamp + ($timestamp >= 0 ? $fraction : -$fraction);
    } elseif (is_int($value) || is_float($value)) {
        if (!is_finite((float)$value)) {
            throw new InvalidArgumentException("temporal values must be finite");
        }
        $current = (float)$value;
    } else {
        throw new InvalidArgumentException("value must be a DateTimeInterface or numeric timestamp");
    }

    if ($clip) {
        if ($current < $input_min) {
            $current = $input_min;
        } elseif ($current > $input_max) {
            $current = $input_max;
        }
    } elseif ($current < $input_min || $current > $input_max) {
        throw new OutOfRangeException("value out of range");
    }

    $span = $input_max - $input_min;
    $out_span = $output_max - $output_min;
    return $output_min + (($current - $input_min) / $span) * $out_span;
}

function map_categorical_value(
    string|int $value,
    array $vocabulary,
    float $output_min = -1.0,
    float $output_max = 1.0
): float {
    if (count($vocabulary) === 0) {
        throw new InvalidArgumentException("vocabulary must contain at least one symbol");
    }

    if (!is_finite($output_min) || !is_finite($output_max)) {
        throw new InvalidArgumentException("output range endpoints must be finite");
    }
    if ($output_min >= $output_max) {
        throw new InvalidArgumentException("output_min must be less than output_max");
    }

    $index_map = [];
    foreach ($vocabulary as $position => $token) {
        $normalized = is_string($token) ? (string)$token : (int)$token;
        if (array_key_exists((string)$normalized, $index_map)) {
            throw new InvalidArgumentException(sprintf("vocabulary contains duplicate token: %s", $normalized));
        }
        $index_map[(string)$normalized] = $position;
    }

    $key = is_string($value) ? $value : (string)$value;
    if (!array_key_exists($key, $index_map)) {
        throw new OutOfRangeException(sprintf("unknown categorical token: %s", $key));
    }

    $position = (float)$index_map[$key];
    $input_min = 0.0;
    $input_max = (float)(count($vocabulary) - 1);

    if ($input_min === $input_max) {
        return $output_min;
    }

    $out_span = $output_max - $output_min;
    $in_span = $input_max - $input_min;
    return $output_min + (($position - $input_min) / $in_span) * $out_span;
}

if (!debug_backtrace()) {
    $mapped = map_integer_value(50, 0, 100);
    if (abs($mapped - 0.0) > 1e-12) {
        throw new RuntimeException(sprintf("smoke test failure: expected 0, got %f", $mapped));
    }

    $mapped_float = map_float_value(0.5, 0.0, 1.0);
    if (abs($mapped_float - 0.0) > 1e-12) {
        throw new RuntimeException(sprintf("float smoke test failure: expected 0, got %f", $mapped_float));
    }

    $mapped_true = map_boolean_value(true);
    if (abs($mapped_true - 1.0) > 1e-12) {
        throw new RuntimeException(sprintf("boolean smoke test failure: expected 1, got %f", $mapped_true));
    }

    $mapped_temporal = map_temporal_value(new DateTimeImmutable("@0"), -10.0, 10.0);
    if (abs($mapped_temporal - 0.0) > 1e-12) {
        throw new RuntimeException(sprintf("temporal smoke test failure: expected 0, got %f", $mapped_temporal));
    }
    $mapped_temporal_repeat = map_temporal_value(new DateTimeImmutable("@0"), -10.0, 10.0);
    if (abs($mapped_temporal_repeat - $mapped_temporal) > 1e-12) {
        throw new RuntimeException(sprintf("temporal repeat smoke test failure: expected %f, got %f", $mapped_temporal, $mapped_temporal_repeat));
    }

    $mapped_text = map_text_value("\0", -1.0, 1.0, "byte", true);
    if (count($mapped_text) !== 1 || abs($mapped_text[0] - (-1.0)) > 1e-12) {
        throw new RuntimeException(sprintf("text byte smoke test failure: %s", json_encode($mapped_text)));
    }

    $mapped_alpha = map_text_value("c", -1.0, 1.0, "alphabet", true, true, "abc");
    if (abs($mapped_alpha[0] - 1.0) > 1e-12) {
        throw new RuntimeException(sprintf("text alphabet smoke test failure: expected 1, got %f", $mapped_alpha[0]));
    }

    $mapped_bytes = map_bytes_value("\x00\xff", -1.0, 1.0, true);
    if (count($mapped_bytes) !== 2 || abs($mapped_bytes[0] - (-1.0)) > 1e-12 || abs($mapped_bytes[1] - 1.0) > 1e-12) {
        throw new RuntimeException(sprintf("bytes smoke test failure: %s", json_encode($mapped_bytes)));
    }

    $mapped_bytes_array = map_bytes_value([0, 255], -1.0, 1.0, false, true);
    if (count($mapped_bytes_array) !== 2 || abs($mapped_bytes_array[0] - (-1.0)) > 1e-12 || abs($mapped_bytes_array[1] - 1.0) > 1e-12) {
        throw new RuntimeException(sprintf("bytes array smoke test failure: %s", json_encode($mapped_bytes_array)));
    }

    $mapped_bytes_repeat = map_bytes_value("\x00\xff", -1.0, 1.0, true);
    if (json_encode($mapped_bytes_repeat) !== json_encode($mapped_bytes)) {
        throw new RuntimeException(sprintf("bytes repeat smoke test failure: %s", json_encode($mapped_bytes_repeat)));
    }

    $mapped_image = map_image_value("\x00\x80\xff", -1.0, 1.0, true);
    if (count($mapped_image) !== 3 || abs($mapped_image[0] - (-1.0)) > 1e-12 || abs($mapped_image[1] - 0.0039215686274509665) > 1e-12 || abs($mapped_image[2] - 1.0) > 1e-12) {
        throw new RuntimeException(sprintf("image bytes smoke test failure: %s", json_encode($mapped_image)));
    }

    $mapped_image_nested = map_image_value([
        [0, 128, 255],
        [64, 192, 32],
    ]);
    $mapped_image_nested_repeat = map_image_value([
        [0, 128, 255],
        [64, 192, 32],
    ]);
    if (json_encode($mapped_image_nested) !== json_encode($mapped_image_nested_repeat)) {
        throw new RuntimeException(sprintf("image repeat smoke test failure: %s", json_encode($mapped_image_nested_repeat)));
    }
    if (count($mapped_image_nested) !== 2 || count($mapped_image_nested[0]) !== 3 || count($mapped_image_nested[1]) !== 3) {
        throw new RuntimeException(sprintf("image nested smoke test failure: %s", json_encode($mapped_image_nested)));
    }
    if (abs($mapped_image_nested[0][0] - (-1.0)) > 1e-12 || abs($mapped_image_nested[0][2] - 1.0) > 1e-12 || abs($mapped_image_nested[1][1] - 0.5058823529411764) > 1e-12) {
        throw new RuntimeException(sprintf("image nested value smoke test failure: %s", json_encode($mapped_image_nested)));
    }

    $image_failed = false;
    try {
        map_image_value([256], -1.0, 1.0, false, true);
    } catch (OutOfRangeException $error) {
        $image_failed = true;
    }
    if (!$image_failed) {
        throw new RuntimeException("image strict out-of-range smoke test should fail");
    }

    $bytes_failed = false;
    try {
        map_bytes_value([256], -1.0, 1.0, false, true);
    } catch (OutOfRangeException $error) {
        $bytes_failed = true;
    }
    if (!$bytes_failed) {
        throw new RuntimeException("bytes strict out-of-range smoke test should fail");
    }

    $mapped_sequence = map_sequence_value([0, [25, 50], 100], function (int $item): float {
        return map_integer_value($item, 0, 100);
    });
    if (json_encode($mapped_sequence) !== json_encode([-1.0, [-0.5, 0.0], 1.0])) {
        throw new RuntimeException(sprintf("sequence smoke test failure: %s", json_encode($mapped_sequence)));
    }

    $mapped_categorical = map_categorical_value("cat", ["cat", "dog", "bird"], -1.0, 1.0);
    if (abs($mapped_categorical - 0.0) > 1e-12) {
        throw new RuntimeException(sprintf("categorical smoke test failure: expected 0, got %f", $mapped_categorical));
    }

    $mapped_categorical_repeat = map_categorical_value("cat", ["cat", "dog", "bird"], -1.0, 1.0);
    if (abs($mapped_categorical_repeat - $mapped_categorical) > 1e-12) {
        throw new RuntimeException(sprintf("categorical repeated mapping failure: expected %f, got %f", $mapped_categorical, $mapped_categorical_repeat));
    }

    $mapped_object = map_object_value(
        ["age" => 25, "active" => true],
        [
            "age" => fn(int $value): float => map_integer_value($value, 0, 120),
            "active" => fn(bool $value): float => map_boolean_value($value),
        ]
    );
    if (json_encode($mapped_object) !== json_encode(["age" => -0.5833333333333334, "active" => 1.0])) {
        throw new RuntimeException(sprintf("object smoke test failure: %s", json_encode($mapped_object)));
    }

    $missing_object_failed = false;
    try {
        map_object_value(
            ["age" => 25],
            [
                "age" => fn(int $value): float => map_integer_value($value, 0, 120),
                "active" => fn(bool $value): float => map_boolean_value($value),
            ]
        );
    } catch (OutOfRangeException $error) {
        $missing_object_failed = true;
    }
    if (!$missing_object_failed) {
        throw new RuntimeException("object missing-field smoke test should fail");
    }

    $nested_missing_object_failed = false;
    try {
        map_object_value(
            [
                "profile" => [
                    "age" => 25,
                ],
                "active" => true,
            ],
            [
                "profile" => function (array $value): array {
                    return map_object_value(
                        $value,
                        [
                            "age" => fn(int $item): float => map_integer_value($item, 0, 100),
                            "tags" => fn(array $item): array => map_sequence_value(
                                $item,
                                fn(string $tag): float => map_categorical_value($tag, ["red", "green", "blue"], -1.0, 1.0),
                                true
                            ),
                        ]
                    );
                },
                "active" => fn(bool $value): float => map_boolean_value($value),
            ]
        );
    } catch (OutOfRangeException $error) {
        $nested_missing_object_failed = true;
    }
    if (!$nested_missing_object_failed) {
        throw new RuntimeException("nested object missing-field smoke test should fail");
    }

    $nested_mapper = function (array $payload): array {
        return map_object_value(
            $payload,
            [
                "age" => fn(int $value): float => map_integer_value($value, 0, 100),
                "tags" => fn(array $value): array => map_sequence_value(
                    $value,
                    fn(string $item): float => map_categorical_value($item, ["red", "green", "blue"], -1.0, 1.0),
                    true
                ),
            ]
        );
    };

    $nested_input = [
        ["age" => 25, "tags" => ["red", "green"]],
        ["age" => 75, "tags" => ["blue", "green", "red"]],
    ];
    $nested_first = map_sequence_value($nested_input, $nested_mapper);
    $nested_second = map_sequence_value($nested_input, $nested_mapper);

    if (json_encode($nested_first) !== json_encode($nested_second)) {
        throw new RuntimeException(sprintf("nested determinism smoke test failure: %s", json_encode($nested_first)));
    }
    if (json_encode($nested_first) !== json_encode([["age" => -0.5, "tags" => [-1.0, 0.0]], ["age" => 0.5, "tags" => [1.0, 0.0, -1.0]]])) {
        throw new RuntimeException(sprintf("nested composition smoke test failure: %s", json_encode($nested_first)));
    }
}
