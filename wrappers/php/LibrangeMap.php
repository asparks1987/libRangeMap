<?php

function map_integer_value(
    int $value,
    int $inputMin,
    int $inputMax,
    float $outputMin = -1.0,
    float $outputMax = 1.0,
    bool $clip = false
): float {
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

if (!debug_backtrace()) {
    $mapped = map_integer_value(50, 0, 100);
    assert(abs($mapped - 0.0) < 1e-9);
    $mapped = map_integer_value(150, 0, 100, -1.0, 1.0, true);
    assert(abs($mapped - 1.0) < 1e-9);
}
