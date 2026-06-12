<?php

function map_integer_value(
    $value,
    $inputMin,
    $inputMax,
    $outputMin = -1.0,
    $outputMax = 1.0,
    $clip = false
): float {
    if (!is_int($value) || !is_int($inputMin) || !is_int($inputMax)) {
        throw new InvalidArgumentException('value, input_min, and input_max must be integers');
    }
    if (!is_finite((float)$outputMin) || !is_finite((float)$outputMax)) {
        throw new InvalidArgumentException('output_min and output_max must be finite numbers');
    }
    $outputMin = (float) $outputMin;
    $outputMax = (float) $outputMax;
    if ($inputMin >= $inputMax) {
        throw new InvalidArgumentException('input_min must be less than input_max');
    }
    if ($outputMin >= $outputMax) {
        throw new InvalidArgumentException('output_min must be less than output_max');
    }
    $v = $value;
    if ($clip) {
        if ($v < $inputMin) $v = $inputMin;
        if ($v > $inputMax) $v = $inputMax;
    } else {
        if ($v < $inputMin || $v > $inputMax) {
            throw new OutOfRangeException('value out of range');
        }
    }
    return $outputMin + (($v - $inputMin) / ($inputMax - $inputMin)) * ($outputMax - $outputMin);
}

function map_float_value(
    $value,
    $inputMin,
    $inputMax,
    $outputMin = -1.0,
    $outputMax = 1.0,
    $clip = false
): float {
    if (!is_numeric($value) || !is_finite((float)$value)) {
        throw new InvalidArgumentException('value must be a finite number');
    }
    if (!is_numeric($inputMin) || !is_numeric($inputMax) || !is_finite((float)$inputMin) || !is_finite((float)$inputMax)) {
        throw new InvalidArgumentException('input_min and input_max must be finite numbers');
    }
    if (!is_numeric($outputMin) || !is_numeric($outputMax) || !is_finite((float)$outputMin) || !is_finite((float)$outputMax)) {
        throw new InvalidArgumentException('output_min and output_max must be finite numbers');
    }

    $inputMin = (float) $inputMin;
    $inputMax = (float) $inputMax;
    $outputMin = (float) $outputMin;
    $outputMax = (float) $outputMax;
    $value = (float) $value;

    if ($inputMin >= $inputMax) {
        throw new InvalidArgumentException('input_min must be less than input_max');
    }
    if ($outputMin >= $outputMax) {
        throw new InvalidArgumentException('output_min must be less than output_max');
    }

    if ($clip) {
        if ($value < $inputMin) $value = $inputMin;
        if ($value > $inputMax) $value = $inputMax;
    } elseif ($value < $inputMin || $value > $inputMax) {
        throw new OutOfRangeException('value out of range');
    }

    return $outputMin + (($value - $inputMin) / ($inputMax - $inputMin)) * ($outputMax - $outputMin);
}

function map_boolean_value(
    $value,
    $outputMin = -1.0,
    $outputMax = 1.0,
    $falseValue = null,
    $trueValue = null
): float {
    if (!is_bool($value)) {
        throw new InvalidArgumentException('value must be a boolean');
    }

    if (!is_numeric($outputMin) || !is_numeric($outputMax) || !is_finite((float)$outputMin) || !is_finite((float)$outputMax)) {
        throw new InvalidArgumentException('output_min and output_max must be finite numbers');
    }

    $outputMin = (float)$outputMin;
    $outputMax = (float)$outputMax;
    if ($outputMin >= $outputMax) {
        throw new InvalidArgumentException('output_min must be less than output_max');
    }

    $falseValue = $falseValue === null ? $outputMin : (float)$falseValue;
    $trueValue = $trueValue === null ? $outputMax : (float)$trueValue;

    if (!is_numeric($falseValue) || !is_finite((float)$falseValue) || !is_numeric($trueValue) || !is_finite((float)$trueValue)) {
        throw new InvalidArgumentException('false_value and true_value must be finite numbers');
    }

    $falseValue = (float)$falseValue;
    $trueValue = (float)$trueValue;
    if ($falseValue < $outputMin || $falseValue > $outputMax || $trueValue < $outputMin || $trueValue > $outputMax) {
        throw new InvalidArgumentException('false_value and true_value must be inside output range');
    }
    if ($falseValue === $trueValue) {
        throw new InvalidArgumentException('false_value and true_value must be different');
    }

    return $value ? $trueValue : $falseValue;
}

if (!debug_backtrace()) {
    $mapped = map_integer_value(50, 0, 100);
    assert(abs($mapped - 0.0) < 1e-9);
    $mapped = map_integer_value(150, 0, 100, -1.0, 1.0, true);
    assert(abs($mapped - 1.0) < 1e-9);
    $mapped = map_float_value(0.5, 0.0, 1.0);
    assert(abs($mapped - 0.0) < 1e-9);
    $mapped = map_boolean_value(true);
    assert(abs($mapped - 1.0) < 1e-9);
}
