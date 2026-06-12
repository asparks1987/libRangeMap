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
	"math"
	"sort"
	"strings"
	"time"
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

type FloatMapperSpec struct {
	SpecVersion   string     `json:"spec_version"`
	MapperType    string     `json:"mapper_type"`
	InputRange    [2]float64 `json:"input_range"`
	OutputRange   [2]float64 `json:"output_range"`
	Clip          bool       `json:"clip"`
	AllowInteger  bool       `json:"allow_integer"`
}

type BooleanMapperSpec struct {
	SpecVersion string  `json:"spec_version"`
	MapperType  string  `json:"mapper_type"`
	FalseValue  float64 `json:"false_value"`
	TrueValue   float64 `json:"true_value"`
}

type CategoricalRangeMapper struct {
	vocabulary []string
	index      map[string]int
	outputMin  float64
	outputMax  float64
	name       string
}

type CategoricalMapperSpec struct {
	SpecVersion string    `json:"spec_version"`
	MapperType  string    `json:"mapper_type"`
	Vocabulary  []string  `json:"vocabulary"`
	OutputRange [2]float64 `json:"output_range"`
	Name        string    `json:"name,omitempty"`
}

type TextRangeMapper struct {
	mode       string
	alphabet   string
	inputMin   int64
	inputMax   int64
	outputMin  float64
	outputMax  float64
	clip       bool
	allowEmpty bool
	name       string
}

type TextMapperSpec struct {
	SpecVersion string   `json:"spec_version"`
	MapperType  string   `json:"mapper_type"`
	Mode        string   `json:"mode"`
	Alphabet    string   `json:"alphabet,omitempty"`
	InputRange  [2]int64 `json:"input_range"`
	OutputRange [2]float64 `json:"output_range"`
	Clip        bool     `json:"clip"`
	AllowEmpty  bool     `json:"allow_empty"`
	Name        string   `json:"name,omitempty"`
}

type BytesRangeMapper struct {
	outputMin  float64
	outputMax  float64
	clip       bool
	allowEmpty bool
}

type BytesMapperSpec struct {
	SpecVersion string  `json:"spec_version"`
	MapperType  string  `json:"mapper_type"`
	OutputRange [2]float64 `json:"output_range"`
	Clip        bool    `json:"clip"`
	AllowEmpty  bool    `json:"allow_empty"`
}

type ImageRangeMapper struct {
	bytesMapper *BytesRangeMapper
}

type ImageMapperSpec struct {
	SpecVersion string     `json:"spec_version"`
	MapperType  string     `json:"mapper_type"`
	OutputRange [2]float64 `json:"output_range"`
	Clip        bool       `json:"clip"`
	AllowEmpty  bool       `json:"allow_empty"`
}

type SequenceRangeMapper[T any, R any] struct {
	elementMapper func(T) (R, error)
	allowEmpty    bool
}

type SequenceMapperSpec struct {
	SpecVersion string `json:"spec_version"`
	MapperType  string `json:"mapper_type"`
	AllowEmpty  bool   `json:"allow_empty"`
}

type TemporalRangeMapper struct {
	inputMin  int64
	inputMax  int64
	outputMin float64
	outputMax float64
	clip      bool
}

type TemporalMapperSpec struct {
	SpecVersion string      `json:"spec_version"`
	MapperType  string      `json:"mapper_type"`
	InputUnit   string      `json:"input_unit"`
	InputRange  [2]int64    `json:"input_range"`
	OutputRange [2]float64  `json:"output_range"`
	Clip        bool        `json:"clip"`
}

type MapRangeObject struct {
	SpecVersion string       `json:"spec_version"`
	MapperType  string       `json:"mapper_type"`
	AllowUnknown bool        `json:"allow_unknown"`
	Fields      []MapObjectField `json:"fields"`
}

type MapObjectField struct {
	Name        string  `json:"name"`
	AllowMissing bool   `json:"allow_missing"`
	MissingValue *float64 `json:"missing_value,omitempty"`
	Family      string  `json:"family"`
	MapperJSON  string  `json:"mapper_json"`
}

type MapObjectInputField struct {
	Name  string
	Value any
}

type MapObjectRangeMapper struct {
	fields      []mapObjectFieldRuntime
	allowUnknown bool
}

type mapObjectFieldRuntime struct {
	name        string
	allowMissing bool
	missingValue *float64
	mapper      mapObjectValueMapper
}

type mapObjectValueMapper interface {
	mapValue(value any) (float64, error)
	toJSON() (string, error)
}

type objectIntValueMapper struct {
	mapper *IntegerRangeMapper
}

type objectFloatValueMapper struct {
	mapper *FloatRangeMapper
}

type objectBoolValueMapper struct {
	mapper *BooleanRangeMapper
}

type objectTextValueMapper struct {
	mapper *TextRangeMapper
}

type objectCategoricalValueMapper struct {
	mapper *CategoricalRangeMapper
}

type objectTemporalValueMapper struct {
	mapper *TemporalRangeMapper
}

type objectImageValueMapper struct {
	mapper *ImageRangeMapper
}

type objectSequenceValueMapper struct {
	mapper      mapObjectValueMapper
	allowEmpty bool
}

type objectMapValueMapper struct {
	mapper *MapObjectRangeMapper
}

func newMapObjectValueMapper(family, mapperJSON string) (mapObjectValueMapper, error) {
	switch family {
	case "integer_range":
		var spec MapperSpec
		if err := json.Unmarshal([]byte(mapperJSON), &spec); err != nil {
			return nil, err
		}
		mapper, err := NewIntegerRangeMapperFromSpec(spec)
		if err != nil {
			return nil, err
		}
		return &objectIntValueMapper{mapper: mapper}, nil
	case "float_range":
		var spec FloatMapperSpec
		if err := json.Unmarshal([]byte(mapperJSON), &spec); err != nil {
			return nil, err
		}
		mapper, err := NewFloatRangeMapperFromSpec(spec)
		if err != nil {
			return nil, err
		}
		return &objectFloatValueMapper{mapper: mapper}, nil
	case "boolean_range":
		var spec BooleanMapperSpec
		if err := json.Unmarshal([]byte(mapperJSON), &spec); err != nil {
			return nil, err
		}
		mapper, err := NewBooleanRangeMapperFromSpec(spec)
		if err != nil {
			return nil, err
		}
		return &objectBoolValueMapper{mapper: mapper}, nil
	case "text_range":
		var spec TextMapperSpec
		if err := json.Unmarshal([]byte(mapperJSON), &spec); err != nil {
			return nil, err
		}
		mapper, err := NewTextRangeMapperFromSpec(spec)
		if err != nil {
			return nil, err
		}
		return &objectTextValueMapper{mapper: mapper}, nil
	case "categorical_range":
		var spec CategoricalMapperSpec
		if err := json.Unmarshal([]byte(mapperJSON), &spec); err != nil {
			return nil, err
		}
		mapper, err := NewCategoricalRangeMapperFromSpec(spec)
		if err != nil {
			return nil, err
		}
		return &objectCategoricalValueMapper{mapper: mapper}, nil
	case "temporal_range":
		var spec TemporalMapperSpec
		if err := json.Unmarshal([]byte(mapperJSON), &spec); err != nil {
			return nil, err
		}
		mapper, err := NewTemporalRangeMapperFromSpec(spec)
		if err != nil {
			return nil, err
		}
		return &objectTemporalValueMapper{mapper: mapper}, nil
	case "image_range":
		var spec ImageMapperSpec
		if err := json.Unmarshal([]byte(mapperJSON), &spec); err != nil {
			return nil, err
		}
		mapper, err := NewImageRangeMapperFromSpec(spec)
		if err != nil {
			return nil, err
		}
		return &objectImageValueMapper{mapper: mapper}, nil
	case "sequence_range":
		var spec struct {
			SpecVersion string `json:"spec_version"`
			MapperType  string `json:"mapper_type"`
			AllowEmpty bool   `json:"allow_empty"`
			MapperJSON  string `json:"mapper_json"`
		}
		if err := json.Unmarshal([]byte(mapperJSON), &spec); err != nil {
			return nil, err
		}
		if spec.SpecVersion != SpecVersion {
			return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
		}
		if spec.MapperType != "sequence_range" {
			return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
		}
		child, err := newMapObjectValueMapper("integer_range", spec.MapperJSON)
		if err == nil {
			return &objectSequenceValueMapper{mapper: child, allowEmpty: spec.AllowEmpty}, nil
		}
		// fallback to other scalar families when sequence child is not integer
		child, err = newMapObjectValueMapper("float_range", spec.MapperJSON)
		if err == nil {
			return &objectSequenceValueMapper{mapper: child, allowEmpty: spec.AllowEmpty}, nil
		}
		child, err = newMapObjectValueMapper("boolean_range", spec.MapperJSON)
		if err == nil {
			return &objectSequenceValueMapper{mapper: child, allowEmpty: spec.AllowEmpty}, nil
		}
		child, err = newMapObjectValueMapper("text_range", spec.MapperJSON)
		if err == nil {
			return &objectSequenceValueMapper{mapper: child, allowEmpty: spec.AllowEmpty}, nil
		}
		child, err = newMapObjectValueMapper("categorical_range", spec.MapperJSON)
		if err == nil {
			return &objectSequenceValueMapper{mapper: child, allowEmpty: spec.AllowEmpty}, nil
		}
		child, err = newMapObjectValueMapper("temporal_range", spec.MapperJSON)
		if err == nil {
			return &objectSequenceValueMapper{mapper: child, allowEmpty: spec.AllowEmpty}, nil
		}
		child, err = newMapObjectValueMapper("image_range", spec.MapperJSON)
		if err == nil {
			return &objectSequenceValueMapper{mapper: child, allowEmpty: spec.AllowEmpty}, nil
		}
		if nestedSpec, nestedErr := newMapObjectValueMapper("map_range", spec.MapperJSON); nestedErr == nil {
			return &objectSequenceValueMapper{mapper: nestedSpec, allowEmpty: spec.AllowEmpty}, nil
		}
		return nil, fmt.Errorf("librangemap: unsupported sequence child mapper")
	case "map_range":
		mapper, err := NewMapObjectRangeMapperFromJSON(mapperJSON)
		if err != nil {
			return nil, err
		}
		return &objectMapValueMapper{mapper: mapper}, nil
	default:
		return nil, fmt.Errorf("librangemap: unsupported family %q", family)
	}
}

func (m *objectIntValueMapper) mapValue(value any) (float64, error) {
	switch v := value.(type) {
	case int:
		return m.mapper.MapValue(int64(v))
	case int8:
		return m.mapper.MapValue(int64(v))
	case int16:
		return m.mapper.MapValue(int64(v))
	case int32:
		return m.mapper.MapValue(int64(v))
	case int64:
		return m.mapper.MapValue(v)
	case uint:
		return m.mapper.MapValue(int64(v))
	case uint8:
		return m.mapper.MapValue(int64(v))
	case uint16:
		return m.mapper.MapValue(int64(v))
	case uint32:
		return m.mapper.MapValue(int64(v))
	case uint64:
		return m.mapper.MapValue(int64(v))
	default:
		return 0, fmt.Errorf("librangemap: integer field expects integer value")
	}
}

func (m *objectIntValueMapper) toJSON() (string, error) {
	return m.mapper.ToJSON()
}

func (m *objectFloatValueMapper) mapValue(value any) (float64, error) {
	switch v := value.(type) {
	case float64:
		return m.mapper.MapValue(v)
	case float32:
		return m.mapper.MapValue(float64(v))
	case int:
		return m.mapper.MapIntValue(int64(v))
	case int8:
		return m.mapper.MapIntValue(int64(v))
	case int16:
		return m.mapper.MapIntValue(int64(v))
	case int32:
		return m.mapper.MapIntValue(int64(v))
	case int64:
		return m.mapper.MapIntValue(v)
	case uint:
		return m.mapper.MapIntValue(int64(v))
	case uint8:
		return m.mapper.MapIntValue(int64(v))
	case uint16:
		return m.mapper.MapIntValue(int64(v))
	case uint32:
		return m.mapper.MapIntValue(int64(v))
	case uint64:
		return m.mapper.MapIntValue(int64(v))
	default:
		return 0, fmt.Errorf("librangemap: float field expects float value")
	}
}

func (m *objectFloatValueMapper) toJSON() (string, error) {
	return m.mapper.ToJSON()
}

func (m *objectBoolValueMapper) mapValue(value any) (float64, error) {
	v, ok := value.(bool)
	if !ok {
		return 0, fmt.Errorf("librangemap: boolean field expects bool")
	}
	return m.mapper.MapValue(v), nil
}

func (m *objectBoolValueMapper) toJSON() (string, error) {
	return m.mapper.ToJSON()
}

func (m *objectTextValueMapper) mapValue(value any) (float64, error) {
	v, ok := value.(string)
	if !ok {
		return 0, fmt.Errorf("librangemap: text field expects string")
	}
	mapped, err := m.mapper.MapValue(v)
	if err != nil {
		return 0, err
	}
	return mean(mapped), nil
}

func (m *objectTextValueMapper) toJSON() (string, error) {
	return m.mapper.ToJSON()
}

func (m *objectCategoricalValueMapper) mapValue(value any) (float64, error) {
	return m.mapper.MapValue(value)
}

func (m *objectCategoricalValueMapper) toJSON() (string, error) {
	return m.mapper.ToJSON()
}

func (m *objectTemporalValueMapper) mapValue(value any) (float64, error) {
	switch v := value.(type) {
	case int:
		return m.mapper.MapValue(int64(v))
	case int8:
		return m.mapper.MapValue(int64(v))
	case int16:
		return m.mapper.MapValue(int64(v))
	case int32:
		return m.mapper.MapValue(int64(v))
	case int64:
		return m.mapper.MapValue(v)
	case uint:
		return m.mapper.MapValue(int64(v))
	case uint8:
		return m.mapper.MapValue(int64(v))
	case uint16:
		return m.mapper.MapValue(int64(v))
	case uint32:
		return m.mapper.MapValue(int64(v))
	case uint64:
		return m.mapper.MapValue(int64(v))
	case time.Time:
		return m.mapper.MapTime(v)
	default:
		return 0, fmt.Errorf("librangemap: temporal field expects integer epoch milliseconds or time.Time")
	}
}

func (m *objectTemporalValueMapper) toJSON() (string, error) {
	return m.mapper.ToJSON()
}

func (m *objectImageValueMapper) mapValue(value any) (float64, error) {
	b, ok := value.([]byte)
	if !ok {
		return 0, fmt.Errorf("librangemap: image field expects byte payload")
	}
	mapped, err := m.mapper.MapValue(b)
	if err != nil {
		return 0, err
	}
	return mean(mapped), nil
}

func (m *objectImageValueMapper) toJSON() (string, error) {
	return m.mapper.ToJSON()
}

func (m *objectSequenceValueMapper) mapValue(value any) (float64, error) {
	items, ok := value.([]any)
	if !ok {
		return 0, fmt.Errorf("librangemap: sequence field expects sequence values")
	}
	if len(items) == 0 && !m.allowEmpty {
		return 0, fmt.Errorf("librangemap: empty sequence field is invalid by default")
	}
	if len(items) == 0 {
		return 0, nil
	}
	out := make([]float64, 0, len(items))
	for _, item := range items {
		mapped, err := m.mapper.mapValue(item)
		if err != nil {
			return 0, err
		}
		out = append(out, mapped)
	}
	return mean(out), nil
}

func (m *objectSequenceValueMapper) toJSON() (string, error) {
	childJSON, err := m.mapper.toJSON()
	if err != nil {
		return "", err
	}
	spec := map[string]any{
		"spec_version": SpecVersion,
		"mapper_type":  "sequence_range",
		"allow_empty":  m.allowEmpty,
		"mapper_json":  childJSON,
	}
	data, err := json.Marshal(spec)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

func (m *objectMapValueMapper) mapValue(value any) (float64, error) {
	mapped, err := m.mapper.Map(value)
	if err != nil {
		return 0, err
	}
	return mean(mapped), nil
}

func (m *objectMapValueMapper) toJSON() (string, error) {
	return m.mapper.toJSON()
}

func NewMapObjectRangeMapper(fields []MapObjectField, allowUnknown bool) (*MapObjectRangeMapper, error) {
	seen := make(map[string]struct{}, len(fields))
	parsed := make([]mapObjectFieldRuntime, 0, len(fields))
	for _, field := range fields {
		if strings.TrimSpace(field.Name) == "" {
			return nil, fmt.Errorf("librangemap: map field name must be non-empty")
		}
		if _, ok := seen[field.Name]; ok {
			return nil, fmt.Errorf("librangemap: duplicate field %q", field.Name)
		}
		seen[field.Name] = struct{}{}
		mapper, err := newMapObjectValueMapper(field.Family, field.MapperJSON)
		if err != nil {
			return nil, err
		}
		parsed = append(parsed, mapObjectFieldRuntime{
			name: field.Name,
			allowMissing: field.AllowMissing,
			missingValue: field.MissingValue,
			mapper:      mapper,
		})
	}
	return &MapObjectRangeMapper{fields: parsed, allowUnknown: allowUnknown}, nil
}

func NewMapObjectRangeMapperFromJSON(text string) (*MapObjectRangeMapper, error) {
	var spec MapRangeObject
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewMapObjectRangeMapperFromSpec(spec)
}

func NewMapObjectRangeMapperFromSpec(spec MapRangeObject) (*MapObjectRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "map_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	return NewMapObjectRangeMapper(spec.Fields, spec.AllowUnknown)
}

func (m *MapObjectRangeMapper) mapInputValues(value any) (map[string]any, error) {
	out := make(map[string]any)
	switch typed := value.(type) {
	case map[string]any:
		for key, v := range typed {
			if strings.TrimSpace(key) == "" {
				return nil, fmt.Errorf("librangemap: object field names must be non-empty")
			}
			out[key] = v
		}
	case []MapObjectInputField:
		for _, item := range typed {
			if strings.TrimSpace(item.Name) == "" {
				return nil, fmt.Errorf("librangemap: object field names must be non-empty")
			}
			if _, ok := out[item.Name]; ok {
				return nil, fmt.Errorf("librangemap: duplicate field %q", item.Name)
			}
			out[item.Name] = item.Value
		}
	default:
		return nil, fmt.Errorf("librangemap: unsupported object value type")
	}
	return out, nil
}

func (m *MapObjectRangeMapper) Map(value any) ([]float64, error) {
	entries, err := m.mapInputValues(value)
	if err != nil {
		return nil, err
	}
	for name := range entries {
		found := false
		for _, field := range m.fields {
			if field.name == name {
				found = true
				break
			}
		}
		if !found && !m.allowUnknown {
			return nil, fmt.Errorf("librangemap: unknown field %q", name)
		}
	}
	sorted := make([]mapObjectFieldRuntime, len(m.fields))
	copy(sorted, m.fields)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i].name < sorted[j].name })
	output := make([]float64, 0, len(sorted))
	for _, field := range sorted {
		v, ok := entries[field.name]
		if !ok {
			if field.allowMissing {
				if field.missingValue == nil {
					return nil, fmt.Errorf("librangemap: missing required field %q", field.name)
				}
				output = append(output, *field.missingValue)
				continue
			}
			return nil, fmt.Errorf("librangemap: missing required field %q", field.name)
		}
		mapped, err := field.mapper.mapValue(v)
		if err != nil {
			return nil, err
		}
		output = append(output, mapped)
	}
	return output, nil
}

func (m *MapObjectRangeMapper) toJSON() (string, error) {
	fields := make([]MapObjectField, 0, len(m.fields))
	for _, field := range m.fields {
		fields = append(fields, MapObjectField{
			Name:         field.name,
			AllowMissing: field.allowMissing,
			MissingValue: field.missingValue,
			Family:       m.fieldFamily(field.mapper),
			MapperJSON:   mustToJSON(field.mapper),
		})
	}
	spec := MapRangeObject{
		SpecVersion: SpecVersion,
		MapperType:  "map_range",
		AllowUnknown: m.allowUnknown,
		Fields:      fields,
	}
	data, err := json.Marshal(spec)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

func (m *MapObjectRangeMapper) ToJSON() (string, error) {
	return m.toJSON()
}

func (m *MapObjectRangeMapper) fieldFamily(mapper mapObjectValueMapper) string {
	switch mapper.(type) {
	case *objectIntValueMapper:
		return "integer_range"
	case *objectFloatValueMapper:
		return "float_range"
	case *objectBoolValueMapper:
		return "boolean_range"
	case *objectTextValueMapper:
		return "text_range"
	case *objectCategoricalValueMapper:
		return "categorical_range"
	case *objectTemporalValueMapper:
		return "temporal_range"
	case *objectImageValueMapper:
		return "image_range"
	case *objectMapValueMapper:
		return "map_range"
	case *objectSequenceValueMapper:
		return "sequence_range"
	default:
		return "unknown"
	}
}

func mustToJSON(mapper mapObjectValueMapper) string {
	data, err := mapper.toJSON()
	if err != nil {
		return ""
	}
	return data
}

func NewSequenceRangeMapper[T any, R any](elementMapper func(T) (R, error), allowEmpty bool) (*SequenceRangeMapper[T, R], error) {
	if elementMapper == nil {
		return nil, fmt.Errorf("librangemap: element mapper is required")
	}
	return &SequenceRangeMapper[T, R]{
		elementMapper: elementMapper,
		allowEmpty:    allowEmpty,
	}, nil
}

func (m *SequenceRangeMapper[T, R]) MapValue(value []T) ([]R, error) {
	if len(value) == 0 && !m.allowEmpty {
		return nil, fmt.Errorf("librangemap: empty sequence input is invalid by default")
	}
	output := make([]R, 0, len(value))
	for _, item := range value {
		mapped, err := m.elementMapper(item)
		if err != nil {
			return nil, err
		}
		output = append(output, mapped)
	}
	return output, nil
}

func (m *SequenceRangeMapper[T, R]) Map(value []T) ([]R, error) {
	return m.MapValue(value)
}

func (m *SequenceRangeMapper[T, R]) Spec() (SequenceMapperSpec, error) {
	return SequenceMapperSpec{
		SpecVersion: SpecVersion,
		MapperType:  "sequence_range",
		AllowEmpty:  m.allowEmpty,
	}, nil
}

func (m *SequenceRangeMapper[T, R]) ToJSON() (string, error) {
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

type FloatRangeMapper struct {
	inputMin     float64
	inputMax     float64
	outputMin    float64
	outputMax    float64
	clip         bool
	allowInteger bool
}

func NewFloatRangeMapper(inputMin, inputMax, outputMin, outputMax float64, clip, allowInteger bool) (*FloatRangeMapper, error) {
	if err := validateRange(inputMin, inputMax); err != nil {
		return nil, err
	}
	if err := validateRange(outputMin, outputMax); err != nil {
		return nil, err
	}
	return &FloatRangeMapper{
		inputMin:     inputMin,
		inputMax:     inputMax,
		outputMin:    outputMin,
		outputMax:    outputMax,
		clip:         clip,
		allowInteger: allowInteger,
	}, nil
}

func NewDefaultFloatRangeMapper(inputMin, inputMax float64) (*FloatRangeMapper, error) {
	return NewFloatRangeMapper(inputMin, inputMax, -1.0, 1.0, false, true)
}

func (m *FloatRangeMapper) MapValue(value float64) (float64, error) {
	if err := ensureFinite(value); err != nil {
		return 0, err
	}
	return m.mapScalar(value)
}

func (m *FloatRangeMapper) MapIntValue(value int64) (float64, error) {
	if !m.allowInteger {
		return 0, fmt.Errorf("librangemap: integer input is disabled by policy")
	}
	return m.mapScalar(float64(value))
}

func (m *FloatRangeMapper) Map(value float64) (float64, error) {
	return m.MapValue(value)
}

func (m *FloatRangeMapper) Spec() (FloatMapperSpec, error) {
	return FloatMapperSpec{
		SpecVersion:  SpecVersion,
		MapperType:   "float_range",
		InputRange:   [2]float64{m.inputMin, m.inputMax},
		OutputRange:  [2]float64{m.outputMin, m.outputMax},
		Clip:         m.clip,
		AllowInteger: m.allowInteger,
	}, nil
}

func (m *FloatRangeMapper) ToJSON() (string, error) {
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

func NewFloatRangeMapperFromJSON(text string) (*FloatRangeMapper, error) {
	var spec FloatMapperSpec
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewFloatRangeMapperFromSpec(spec)
}

func NewFloatRangeMapperFromSpec(spec FloatMapperSpec) (*FloatRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "float_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	return NewFloatRangeMapper(
		spec.InputRange[0],
		spec.InputRange[1],
		spec.OutputRange[0],
		spec.OutputRange[1],
		spec.Clip,
		spec.AllowInteger,
	)
}

func (m *FloatRangeMapper) mapScalar(value float64) (float64, error) {
	if value < m.inputMin || value > m.inputMax {
		if !m.clip {
			return 0, ErrOutOfRange
		}
		if value < m.inputMin {
			value = m.inputMin
		}
		if value > m.inputMax {
			value = m.inputMax
		}
	}
	return m.outputMin + ((value-m.inputMin)/(m.inputMax-m.inputMin))*(m.outputMax-m.outputMin), nil
}

type BooleanRangeMapper struct {
	falseValue float64
	trueValue  float64
}

func NewBooleanRangeMapper(falseValue, trueValue float64) (*BooleanRangeMapper, error) {
	if err := ensureFinite(falseValue); err != nil {
		return nil, err
	}
	if err := ensureFinite(trueValue); err != nil {
		return nil, err
	}
	return &BooleanRangeMapper{falseValue: falseValue, trueValue: trueValue}, nil
}

func NewDefaultBooleanRangeMapper() (*BooleanRangeMapper, error) {
	return NewBooleanRangeMapper(-1.0, 1.0)
}

func (m *BooleanRangeMapper) MapValue(value bool) float64 {
	if value {
		return m.trueValue
	}
	return m.falseValue
}

func (m *BooleanRangeMapper) Map(value bool) float64 {
	return m.MapValue(value)
}

func (m *BooleanRangeMapper) Spec() BooleanMapperSpec {
	return BooleanMapperSpec{
		SpecVersion: SpecVersion,
		MapperType:  "boolean_range",
		FalseValue:  m.falseValue,
		TrueValue:   m.trueValue,
	}
}

func (m *BooleanRangeMapper) ToJSON() (string, error) {
	data, err := json.Marshal(m.Spec())
	if err != nil {
		return "", err
	}
	return string(data), nil
}

func NewBooleanRangeMapperFromJSON(text string) (*BooleanRangeMapper, error) {
	var spec BooleanMapperSpec
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewBooleanRangeMapperFromSpec(spec)
}

func NewBooleanRangeMapperFromSpec(spec BooleanMapperSpec) (*BooleanRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "boolean_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	return NewBooleanRangeMapper(spec.FalseValue, spec.TrueValue)
}

func NewCategoricalRangeMapper(vocabulary []any, outputMin, outputMax float64, name string) (*CategoricalRangeMapper, error) {
	if err := validateRange(outputMin, outputMax); err != nil {
		return nil, err
	}
	if len(vocabulary) == 0 {
		return nil, fmt.Errorf("librangemap: vocabulary must not be empty")
	}
	if strings.TrimSpace(name) == "" && name != "" {
		return nil, fmt.Errorf("librangemap: name must not be empty")
	}

	mapping := make(map[string]int, len(vocabulary))
	encoded := make([]string, 0, len(vocabulary))
	for i, token := range vocabulary {
		key, err := categoricalTokenKey(token)
		if err != nil {
			return nil, err
		}
		if _, ok := mapping[key]; ok {
			return nil, fmt.Errorf("librangemap: vocabulary contains duplicate token: %s", key)
		}
		mapping[key] = i
		encoded = append(encoded, key)
	}

	return &CategoricalRangeMapper{
		vocabulary: encoded,
		index:      mapping,
		outputMin:  outputMin,
		outputMax:  outputMax,
		name:       name,
	}, nil
}

func NewDefaultCategoricalRangeMapper(vocabulary []any) (*CategoricalRangeMapper, error) {
	return NewCategoricalRangeMapper(vocabulary, -1.0, 1.0, "")
}

func (m *CategoricalRangeMapper) MapValue(value any) (float64, error) {
	key, err := categoricalTokenKey(value)
	if err != nil {
		return 0, err
	}
	index, ok := m.index[key]
	if !ok {
		return 0, fmt.Errorf("librangemap: unknown token: %s", key)
	}
	if len(m.vocabulary) == 1 {
		return m.outputMin, nil
	}
	return m.outputMin + (float64(index)/float64(len(m.vocabulary)-1))*(m.outputMax-m.outputMin), nil
}

func (m *CategoricalRangeMapper) Map(value any) (float64, error) {
	return m.MapValue(value)
}

func (m *CategoricalRangeMapper) Spec() (CategoricalMapperSpec, error) {
	return CategoricalMapperSpec{
		SpecVersion: SpecVersion,
		MapperType:  "categorical_range",
		Vocabulary:  append([]string(nil), m.vocabulary...),
		OutputRange: [2]float64{m.outputMin, m.outputMax},
		Name:        m.name,
	}, nil
}

func (m *CategoricalRangeMapper) ToJSON() (string, error) {
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

func NewCategoricalRangeMapperFromJSON(text string) (*CategoricalRangeMapper, error) {
	var spec CategoricalMapperSpec
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewCategoricalRangeMapperFromSpec(spec)
}

func NewCategoricalRangeMapperFromSpec(spec CategoricalMapperSpec) (*CategoricalRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "categorical_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	if len(spec.Vocabulary) == 0 {
		return nil, fmt.Errorf("librangemap: vocabulary must not be empty")
	}

	decoded := make([]any, 0, len(spec.Vocabulary))
	for _, token := range spec.Vocabulary {
		value, err := decodeCategoricalToken(token)
		if err != nil {
			return nil, err
		}
		decoded = append(decoded, value)
	}

	return NewCategoricalRangeMapper(decoded, spec.OutputRange[0], spec.OutputRange[1], spec.Name)
}

func NewTextRangeMapper(mode, alphabet string, outputMin, outputMax float64, clip, allowEmpty bool, name string) (*TextRangeMapper, error) {
	if err := validateRange(outputMin, outputMax); err != nil {
		return nil, err
	}
	switch mode {
	case "codepoint":
		if alphabet != "" {
			return nil, fmt.Errorf("librangemap: alphabet must be empty for codepoint mode")
		}
	case "alphabet":
		if err := validateAlphabet(alphabet); err != nil {
			return nil, err
		}
	case "byte":
		if alphabet != "" {
			return nil, fmt.Errorf("librangemap: alphabet must be empty for byte mode")
		}
	default:
		return nil, fmt.Errorf("librangemap: unsupported mode %q", mode)
	}

	inputMin, inputMax := textInputRange(mode, alphabet)
	return &TextRangeMapper{
		mode:       mode,
		alphabet:   alphabet,
		inputMin:   inputMin,
		inputMax:   inputMax,
		outputMin:  outputMin,
		outputMax:  outputMax,
		clip:       clip,
		allowEmpty: allowEmpty,
		name:       name,
	}, nil
}

func NewDefaultTextRangeMapper(mode, alphabet string) (*TextRangeMapper, error) {
	return NewTextRangeMapper(mode, alphabet, -1.0, 1.0, false, false, "")
}

func (m *TextRangeMapper) MapValue(value string) ([]float64, error) {
	if m.mode == "byte" {
		return nil, fmt.Errorf("librangemap: use MapBytes for byte mode")
	}
	if len(value) == 0 && !m.allowEmpty {
		return nil, fmt.Errorf("librangemap: empty text input is invalid by default")
	}
	output := make([]float64, 0, len(value))
	for _, r := range value {
		mapped, err := m.mapRune(r)
		if err != nil {
			return nil, err
		}
		output = append(output, mapped)
	}
	return output, nil
}

func (m *TextRangeMapper) MapBytes(value []byte) ([]float64, error) {
	if m.mode != "byte" {
		return nil, fmt.Errorf("librangemap: MapBytes is only available in byte mode")
	}
	if len(value) == 0 && !m.allowEmpty {
		return nil, fmt.Errorf("librangemap: empty text input is invalid by default")
	}
	output := make([]float64, len(value))
	for i, b := range value {
		output[i] = m.outputMin + ((float64(b) / 255.0) * (m.outputMax - m.outputMin))
	}
	return output, nil
}

func (m *TextRangeMapper) Map(value string) ([]float64, error) {
	return m.MapValue(value)
}

func (m *TextRangeMapper) Spec() (TextMapperSpec, error) {
	return TextMapperSpec{
		SpecVersion: SpecVersion,
		MapperType:  "text_range",
		Mode:        m.mode,
		Alphabet:    m.alphabet,
		InputRange:  [2]int64{m.inputMin, m.inputMax},
		OutputRange: [2]float64{m.outputMin, m.outputMax},
		Clip:        m.clip,
		AllowEmpty:  m.allowEmpty,
		Name:        m.name,
	}, nil
}

func (m *TextRangeMapper) ToJSON() (string, error) {
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

func NewTextRangeMapperFromJSON(text string) (*TextRangeMapper, error) {
	var spec TextMapperSpec
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewTextRangeMapperFromSpec(spec)
}

func NewTextRangeMapperFromSpec(spec TextMapperSpec) (*TextRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "text_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	inputMin, inputMax := textInputRange(spec.Mode, spec.Alphabet)
	if spec.InputRange != [2]int64{inputMin, inputMax} {
		return nil, fmt.Errorf("librangemap: unsupported input_range %v", spec.InputRange)
	}
	return NewTextRangeMapper(spec.Mode, spec.Alphabet, spec.OutputRange[0], spec.OutputRange[1], spec.Clip, spec.AllowEmpty, spec.Name)
}

func (m *TextRangeMapper) mapRune(r rune) (float64, error) {
	switch m.mode {
	case "codepoint":
		if int64(r) < m.inputMin || int64(r) > m.inputMax {
			if !m.clip {
				return 0, ErrOutOfRange
			}
			if int64(r) < m.inputMin {
				r = rune(m.inputMin)
			}
			if int64(r) > m.inputMax {
				r = rune(m.inputMax)
			}
		}
		return m.outputMin + ((float64(r)-float64(m.inputMin))/float64(m.inputMax-m.inputMin))*(m.outputMax-m.outputMin), nil
	case "alphabet":
		index := strings.IndexRune(m.alphabet, r)
		if index < 0 {
			return 0, fmt.Errorf("librangemap: unknown token %q", string(r))
		}
		if len([]rune(m.alphabet)) == 1 {
			return (m.outputMin + m.outputMax) / 2.0, nil
		}
		return m.outputMin + ((float64(index)/float64(len([]rune(m.alphabet))-1))*(m.outputMax-m.outputMin)), nil
	default:
		return 0, fmt.Errorf("librangemap: unsupported mode %q", m.mode)
	}
}

func textInputRange(mode, alphabet string) (int64, int64) {
	switch mode {
	case "codepoint":
		return 0, 0x10FFFF
	case "alphabet":
		return 0, int64(len([]rune(alphabet)) - 1)
	case "byte":
		return 0, 255
	default:
		return 0, 0
	}
}

func validateAlphabet(alphabet string) error {
	runes := []rune(alphabet)
	if len(runes) < 2 {
		return fmt.Errorf("librangemap: alphabet must contain at least 2 unique characters")
	}
	seen := make(map[rune]struct{}, len(runes))
	for _, r := range runes {
		if _, ok := seen[r]; ok {
			return fmt.Errorf("librangemap: alphabet contains duplicate character %q", r)
		}
		seen[r] = struct{}{}
	}
	return nil
}

func NewTemporalRangeMapper(inputMin, inputMax int64, outputMin, outputMax float64, clip bool) (*TemporalRangeMapper, error) {
	if inputMax <= inputMin {
		return nil, fmt.Errorf("librangemap: invalid range")
	}
	if err := validateRange(outputMin, outputMax); err != nil {
		return nil, err
	}
	return &TemporalRangeMapper{
		inputMin:  inputMin,
		inputMax:  inputMax,
		outputMin: outputMin,
		outputMax: outputMax,
		clip:      clip,
	}, nil
}

func NewDefaultTemporalRangeMapper(inputMin, inputMax int64) (*TemporalRangeMapper, error) {
	return NewTemporalRangeMapper(inputMin, inputMax, -1.0, 1.0, false)
}

func (m *TemporalRangeMapper) MapValue(value int64) (float64, error) {
	return m.mapScalar(value)
}

func (m *TemporalRangeMapper) MapTime(value time.Time) (float64, error) {
	if value.IsZero() {
		return 0, fmt.Errorf("librangemap: value must be a valid time")
	}
	return m.mapScalar(value.UTC().UnixMilli())
}

func (m *TemporalRangeMapper) Map(value int64) (float64, error) {
	return m.MapValue(value)
}

func (m *TemporalRangeMapper) Spec() (TemporalMapperSpec, error) {
	return TemporalMapperSpec{
		SpecVersion: SpecVersion,
		MapperType:  "temporal_range",
		InputUnit:   "unix_milliseconds",
		InputRange:  [2]int64{m.inputMin, m.inputMax},
		OutputRange: [2]float64{m.outputMin, m.outputMax},
		Clip:        m.clip,
	}, nil
}

func (m *TemporalRangeMapper) ToJSON() (string, error) {
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

func NewTemporalRangeMapperFromJSON(text string) (*TemporalRangeMapper, error) {
	var spec TemporalMapperSpec
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewTemporalRangeMapperFromSpec(spec)
}

func NewTemporalRangeMapperFromSpec(spec TemporalMapperSpec) (*TemporalRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "temporal_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	if spec.InputUnit != "unix_milliseconds" {
		return nil, fmt.Errorf("librangemap: unsupported input_unit %q", spec.InputUnit)
	}
	return NewTemporalRangeMapper(
		spec.InputRange[0],
		spec.InputRange[1],
		spec.OutputRange[0],
		spec.OutputRange[1],
		spec.Clip,
	)
}

func (m *TemporalRangeMapper) mapScalar(value int64) (float64, error) {
	v := value
	if value < m.inputMin || value > m.inputMax {
		if !m.clip {
			return 0, ErrOutOfRange
		}
		if value < m.inputMin {
			v = m.inputMin
		}
		if value > m.inputMax {
			v = m.inputMax
		}
	}
	return m.outputMin + ((float64(v)-float64(m.inputMin))/float64(m.inputMax-m.inputMin))*(m.outputMax-m.outputMin), nil
}

func NewBytesRangeMapper(outputMin, outputMax float64, clip, allowEmpty bool) (*BytesRangeMapper, error) {
	if err := validateRange(outputMin, outputMax); err != nil {
		return nil, err
	}
	return &BytesRangeMapper{
		outputMin:  outputMin,
		outputMax:  outputMax,
		clip:       clip,
		allowEmpty: allowEmpty,
	}, nil
}

func NewDefaultBytesRangeMapper() (*BytesRangeMapper, error) {
	return NewBytesRangeMapper(-1.0, 1.0, false, false)
}

func NewImageRangeMapper(outputMin, outputMax float64, clip, allowEmpty bool) (*ImageRangeMapper, error) {
	bytesMapper, err := NewBytesRangeMapper(outputMin, outputMax, clip, allowEmpty)
	if err != nil {
		return nil, err
	}
	return &ImageRangeMapper{bytesMapper: bytesMapper}, nil
}

func NewDefaultImageRangeMapper() (*ImageRangeMapper, error) {
	return NewImageRangeMapper(-1.0, 1.0, false, false)
}

func (m *ImageRangeMapper) MapValue(value []byte) ([]float64, error) {
	return m.bytesMapper.MapValue(value)
}

func (m *ImageRangeMapper) MapRows(value [][]byte) ([][]float64, error) {
	if len(value) == 0 && !m.bytesMapper.allowEmpty {
		return nil, fmt.Errorf("librangemap: empty image input is invalid by default")
	}
	output := make([][]float64, 0, len(value))
	for _, row := range value {
		mapped, err := m.bytesMapper.MapValue(row)
		if err != nil {
			return nil, err
		}
		output = append(output, mapped)
	}
	return output, nil
}

func (m *ImageRangeMapper) Spec() (ImageMapperSpec, error) {
	return ImageMapperSpec{
		SpecVersion: SpecVersion,
		MapperType:  "image_range",
		OutputRange: [2]float64{m.bytesMapper.outputMin, m.bytesMapper.outputMax},
		Clip:        m.bytesMapper.clip,
		AllowEmpty:  m.bytesMapper.allowEmpty,
	}, nil
}

func (m *ImageRangeMapper) ToJSON() (string, error) {
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

func NewImageRangeMapperFromJSON(text string) (*ImageRangeMapper, error) {
	var spec ImageMapperSpec
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewImageRangeMapperFromSpec(spec)
}

func NewImageRangeMapperFromSpec(spec ImageMapperSpec) (*ImageRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "image_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	return NewImageRangeMapper(spec.OutputRange[0], spec.OutputRange[1], spec.Clip, spec.AllowEmpty)
}

func (m *BytesRangeMapper) MapValue(value []byte) ([]float64, error) {
	return m.mapBytes(value)
}

func (m *BytesRangeMapper) MapString(value string) ([]float64, error) {
	return m.mapBytes([]byte(value))
}

func (m *BytesRangeMapper) Map(value []byte) ([]float64, error) {
	return m.MapValue(value)
}

func (m *BytesRangeMapper) Spec() (BytesMapperSpec, error) {
	return BytesMapperSpec{
		SpecVersion: SpecVersion,
		MapperType:  "bytes_range",
		OutputRange: [2]float64{m.outputMin, m.outputMax},
		Clip:        m.clip,
		AllowEmpty:  m.allowEmpty,
	}, nil
}

func (m *BytesRangeMapper) ToJSON() (string, error) {
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

func NewBytesRangeMapperFromJSON(text string) (*BytesRangeMapper, error) {
	var spec BytesMapperSpec
	if err := json.Unmarshal([]byte(text), &spec); err != nil {
		return nil, err
	}
	return NewBytesRangeMapperFromSpec(spec)
}

func NewBytesRangeMapperFromSpec(spec BytesMapperSpec) (*BytesRangeMapper, error) {
	if spec.SpecVersion != SpecVersion {
		return nil, fmt.Errorf("librangemap: unsupported spec_version %q", spec.SpecVersion)
	}
	if spec.MapperType != "bytes_range" {
		return nil, fmt.Errorf("librangemap: unsupported mapper_type %q", spec.MapperType)
	}
	return NewBytesRangeMapper(spec.OutputRange[0], spec.OutputRange[1], spec.Clip, spec.AllowEmpty)
}

func (m *BytesRangeMapper) mapBytes(value []byte) ([]float64, error) {
	if len(value) == 0 && !m.allowEmpty {
		return nil, fmt.Errorf("librangemap: empty bytes input is invalid by default")
	}
	output := make([]float64, len(value))
	for i, b := range value {
		output[i] = m.outputMin + ((float64(b) / 255.0) * (m.outputMax - m.outputMin))
	}
	return output, nil
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

func categoricalTokenKey(value any) (string, error) {
	if value == nil {
		return "null", nil
	}
	switch v := value.(type) {
	case string:
		return "str:" + v, nil
	case bool:
		if v {
			return "bool:true", nil
		}
		return "bool:false", nil
	case int:
		return fmt.Sprintf("num:%d", v), nil
	case int8:
		return fmt.Sprintf("num:%d", v), nil
	case int16:
		return fmt.Sprintf("num:%d", v), nil
	case int32:
		return fmt.Sprintf("num:%d", v), nil
	case int64:
		return fmt.Sprintf("num:%d", v), nil
	case uint:
		return fmt.Sprintf("num:%d", v), nil
	case uint16:
		return fmt.Sprintf("num:%d", v), nil
	case uint32:
		return fmt.Sprintf("num:%d", v), nil
	case uint64:
		return fmt.Sprintf("num:%d", v), nil
	case float32:
		if math.IsNaN(float64(v)) || math.IsInf(float64(v), 0) {
			return "", fmt.Errorf("librangemap: vocabulary tokens must be finite numbers")
		}
		return "num:" + formatCategoricalNumber(float64(v)), nil
	case float64:
		if math.IsNaN(v) || math.IsInf(v, 0) {
			return "", fmt.Errorf("librangemap: vocabulary tokens must be finite numbers")
		}
		return "num:" + formatCategoricalNumber(v), nil
	default:
		return "", fmt.Errorf("librangemap: unsupported vocabulary token type %T", value)
	}
}

func decodeCategoricalToken(encoded string) (any, error) {
	if encoded == "null" {
		return nil, nil
	}
	if len(encoded) < 4 {
		return encoded, nil
	}
	sep := -1
	for i := 0; i < len(encoded); i++ {
		if encoded[i] == ':' {
			sep = i
			break
		}
	}
	if sep < 0 {
		return encoded, nil
	}
	prefix := encoded[:sep]
	raw := encoded[sep+1:]
	switch prefix {
	case "str":
		return raw, nil
	case "bool":
		switch raw {
		case "true":
			return true, nil
		case "false":
			return false, nil
		default:
			return nil, fmt.Errorf("librangemap: invalid boolean token encoding")
		}
	case "char":
		var n int32
		if _, err := fmt.Sscanf(raw, "%d", &n); err != nil {
			return nil, err
		}
		return n, nil
	case "num":
		var f float64
		if _, err := fmt.Sscanf(raw, "%f", &f); err != nil {
			return nil, err
		}
		if math.IsNaN(f) || math.IsInf(f, 0) {
			return nil, fmt.Errorf("librangemap: vocabulary tokens must be finite numbers")
		}
		if f == float64(int64(f)) {
			return int64(f), nil
		}
		return f, nil
	default:
		return nil, fmt.Errorf("librangemap: unsupported token encoding %q", encoded)
	}
}

func formatCategoricalNumber(value float64) string {
	return fmt.Sprintf("%.17g", value)
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

func ensureFinite(value float64) error {
	if math.IsNaN(value) || math.IsInf(value, 0) {
		return fmt.Errorf("librangemap: value must be finite")
	}
	return nil
}

func validateRange(minValue, maxValue float64) error {
	if err := ensureFinite(minValue); err != nil {
		return err
	}
	if err := ensureFinite(maxValue); err != nil {
		return err
	}
	if !(maxValue > minValue) {
		return fmt.Errorf("librangemap: invalid range")
	}
	return nil
}
