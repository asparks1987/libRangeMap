//go:build windows && cgo

package librangemap

/*
#cgo windows CFLAGS: -I${SRCDIR}/../../../csrc
#cgo windows LDFLAGS: -L${SRCDIR}/../../../librangemap/native -llibrangemap_core
#include "librangemap_core.h"
*/
import "C"

import (
	"encoding/json"
	"errors"
	"fmt"
)

const SpecVersion = "1.0-alpha"

var (
	ErrInvalidRange = errors.New("librangemap: invalid range")
	ErrInvalidValue = errors.New("librangemap: invalid value")
	ErrOutOfRange   = errors.New("librangemap: value out of range")
	ErrNullPointer  = errors.New("librangemap: null pointer")
)

type IntegerRangeMapper struct {
	cmapper C.lrm_integer_range_mapper_t
}

type MapperSpec struct {
	SpecVersion string     `json:"spec_version"`
	MapperType  string     `json:"mapper_type"`
	InputRange  [2]int64   `json:"input_range"`
	OutputRange [2]float64 `json:"output_range"`
	Clip        bool       `json:"clip"`
}

func NewIntegerRangeMapper(inputMin, inputMax int64, outputMin, outputMax float64, clip bool) (*IntegerRangeMapper, error) {
	var mapper IntegerRangeMapper
	status := C.lrm_integer_range_mapper_init(
		&mapper.cmapper,
		C.int64_t(inputMin),
		C.int64_t(inputMax),
		C.double(outputMin),
		C.double(outputMax),
		boolToInt(clip),
	)
	if status != C.LRM_OK {
		return nil, statusError("init", status)
	}
	return &mapper, nil
}

func NewDefaultIntegerRangeMapper(inputMin, inputMax int64) (*IntegerRangeMapper, error) {
	return NewIntegerRangeMapper(inputMin, inputMax, -1.0, 1.0, false)
}

func (m *IntegerRangeMapper) MapValue(value int64) (float64, error) {
	var out C.double
	status := C.lrm_integer_range_mapper_map_value(&m.cmapper, C.int64_t(value), &out)
	if status != C.LRM_OK {
		return 0, statusError("map_value", status)
	}
	return float64(out), nil
}

func (m *IntegerRangeMapper) Map(value int64) (float64, error) {
	return m.MapValue(value)
}

func (m *IntegerRangeMapper) Spec() (MapperSpec, error) {
	var native C.lrm_integer_range_mapper_spec_t
	status := C.lrm_integer_range_mapper_get_spec(&m.cmapper, &native)
	if status != C.LRM_OK {
		return MapperSpec{}, statusError("get_spec", status)
	}
	return MapperSpec{
		SpecVersion: SpecVersion,
		MapperType:  "integer_range",
		InputRange:  [2]int64{int64(native.input_min), int64(native.input_max)},
		OutputRange: [2]float64{float64(native.output_min), float64(native.output_max)},
		Clip:        intToBool(native.clip),
	}, nil
}

func (m *IntegerRangeMapper) ToJSON() (string, error) {
	spec, err := m.Spec()
	if err != nil {
		return "", err
	}
	data, err := json.Marshal(spec)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

func NewIntegerRangeMapperFromJSON(text string) (*IntegerRangeMapper, error) {
	var spec MapperSpec
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewIntegerRangeMapperFromSpec(spec)
}

func NewIntegerRangeMapperFromSpec(spec MapperSpec) (*IntegerRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "integer_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	return NewIntegerRangeMapper(
		spec.InputRange[0],
		spec.InputRange[1],
		spec.OutputRange[0],
		spec.OutputRange[1],
		spec.Clip,
	)
}

func boolToInt(value bool) C.int {
	if value {
		return 1
	}
	return 0
}

func intToBool(value C.int) bool {
	return value != 0
}

func statusError(op string, status C.int) error {
	switch int(status) {
	case C.LRM_ERROR_INVALID_RANGE:
		return fmt.Errorf("librangemap: %s: %w", op, ErrInvalidRange)
	case C.LRM_ERROR_INVALID_VALUE:
		return fmt.Errorf("librangemap: %s: %w", op, ErrInvalidValue)
	case C.LRM_ERROR_OUT_OF_RANGE:
		return fmt.Errorf("librangemap: %s: %w", op, ErrOutOfRange)
	case C.LRM_ERROR_NULL_POINTER:
		return fmt.Errorf("librangemap: %s: %w", op, ErrNullPointer)
	default:
		return fmt.Errorf("librangemap: %s failed with native status %d", op, int(status))
	}
}
