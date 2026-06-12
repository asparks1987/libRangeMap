//go:build windows && cgo

package librangemap

import (
	"encoding/json"
	"math"
	"testing"
	"time"
)

func TestIntegerRangeMapperMapValue(t *testing.T) {
	mapper, err := NewDefaultIntegerRangeMapper(0, 100)
	if err != nil {
		t.Fatalf("NewDefaultIntegerRangeMapper: %v", err)
	}

	cases := map[int64]float64{
		0:   -1.0,
		50:  0.0,
		100: 1.0,
	}

	for input, want := range cases {
		got, err := mapper.MapValue(input)
		if err != nil {
			t.Fatalf("MapValue(%d): %v", input, err)
		}
		if got != want {
			t.Fatalf("MapValue(%d) = %v, want %v", input, got, want)
		}
	}

	first, err := mapper.MapValue(50)
	if err != nil {
		t.Fatalf("MapValue(50) first: %v", err)
	}
	second, err := mapper.MapValue(50)
	if err != nil {
		t.Fatalf("MapValue(50) second: %v", err)
	}
	if first != second {
		t.Fatalf("MapValue(50) repeated = %v, want %v", second, first)
	}
}

func TestIntegerRangeMapperJSONRoundTrip(t *testing.T) {
	mapper, err := NewIntegerRangeMapper(-10, 10, -1.0, 1.0, true)
	if err != nil {
		t.Fatalf("NewIntegerRangeMapper: %v", err)
	}

	text, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}

	restored, err := NewIntegerRangeMapperFromJSON(text)
	if err != nil {
		t.Fatalf("NewIntegerRangeMapperFromJSON: %v", err)
	}

	got, err := restored.MapValue(-10)
	if err != nil {
		t.Fatalf("MapValue: %v", err)
	}
	if got != -1.0 {
		t.Fatalf("MapValue(-10) = %v, want -1.0", got)
	}
}

func TestIntegerRangeMapperOutOfRangeStrict(t *testing.T) {
	mapper, err := NewIntegerRangeMapper(0, 10, -1.0, 1.0, false)
	if err != nil {
		t.Fatalf("NewIntegerRangeMapper: %v", err)
	}

	if _, err := mapper.MapValue(11); err == nil {
		t.Fatal("MapValue(11) expected an error")
	}
}

func TestIntegerRangeMapperRejectsUnsupportedSpec(t *testing.T) {
	if _, err := NewIntegerRangeMapperFromJSON(`{"spec_version":"1.0-alpha","mapper_type":"other","input_range":[0,10],"output_range":[-1,1],"clip":false}`); err == nil {
		t.Fatal("NewIntegerRangeMapperFromJSON expected an error for unsupported mapper_type")
	}

	if _, err := NewIntegerRangeMapperFromJSON(`{"spec_version":"0.9","mapper_type":"integer_range","input_range":[0,10],"output_range":[-1,1],"clip":false}`); err == nil {
		t.Fatal("NewIntegerRangeMapperFromJSON expected an error for unsupported spec_version")
	}

	if _, err := NewIntegerRangeMapperFromJSON(`{"spec_version":"1.0-alpha","mapper_type":"integer_range","input_range":`); err == nil {
		t.Fatal("NewIntegerRangeMapperFromJSON expected an error for malformed JSON")
	}
}

func TestFloatRangeMapper(t *testing.T) {
	mapper, err := NewDefaultFloatRangeMapper(0.0, 10.0)
	if err != nil {
		t.Fatalf("NewDefaultFloatRangeMapper: %v", err)
	}

	got, err := mapper.MapValue(5.0)
	if err != nil {
		t.Fatalf("MapValue: %v", err)
	}
	if got != 0.0 {
		t.Fatalf("MapValue(5.0) = %v, want 0.0", got)
	}

	roundtrip, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}

	restored, err := NewFloatRangeMapperFromJSON(roundtrip)
	if err != nil {
		t.Fatalf("NewFloatRangeMapperFromJSON: %v", err)
	}

	again, err := restored.MapValue(5.0)
	if err != nil {
		t.Fatalf("restored.MapValue: %v", err)
	}
	if again != 0.0 {
		t.Fatalf("restored.MapValue(5.0) = %v, want 0.0", again)
	}

	strict, err := NewFloatRangeMapper(0.0, 1.0, -1.0, 1.0, false, true)
	if err != nil {
		t.Fatalf("NewFloatRangeMapper: %v", err)
	}
	if _, err := strict.MapValue(1.5); err == nil {
		t.Fatal("MapValue(1.5) expected an error")
	}
	if _, err := strict.MapValue(math.Inf(1)); err == nil {
		t.Fatal("MapValue(+Inf) expected an error")
	}

	if _, err := mapper.MapIntValue(5); err != nil {
		t.Fatalf("MapIntValue: %v", err)
	}
}

func TestBooleanRangeMapper(t *testing.T) {
	mapper, err := NewDefaultBooleanRangeMapper()
	if err != nil {
		t.Fatalf("NewDefaultBooleanRangeMapper: %v", err)
	}

	if got := mapper.MapValue(false); got != -1.0 {
		t.Fatalf("MapValue(false) = %v, want -1.0", got)
	}
	if got := mapper.MapValue(true); got != 1.0 {
		t.Fatalf("MapValue(true) = %v, want 1.0", got)
	}

	text, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}

	restored, err := NewBooleanRangeMapperFromJSON(text)
	if err != nil {
		t.Fatalf("NewBooleanRangeMapperFromJSON: %v", err)
	}
	if got := restored.MapValue(true); got != 1.0 {
		t.Fatalf("restored.MapValue(true) = %v, want 1.0", got)
	}
}

func TestBytesRangeMapper(t *testing.T) {
	mapper, err := NewDefaultBytesRangeMapper()
	if err != nil {
		t.Fatalf("NewDefaultBytesRangeMapper: %v", err)
	}

	got, err := mapper.MapValue([]byte{0, 127, 255})
	if err != nil {
		t.Fatalf("MapValue: %v", err)
	}
	if len(got) != 3 {
		t.Fatalf("MapValue length = %d, want 3", len(got))
	}
	if got[0] != -1.0 {
		t.Fatalf("MapValue[0] = %v, want -1.0", got[0])
	}
	if got[2] != 1.0 {
		t.Fatalf("MapValue[2] = %v, want 1.0", got[2])
	}

	fromString, err := mapper.MapString("A")
	if err != nil {
		t.Fatalf("MapString: %v", err)
	}
	if len(fromString) != 1 {
		t.Fatalf("MapString length = %d, want 1", len(fromString))
	}

	text, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}
	restored, err := NewBytesRangeMapperFromJSON(text)
	if err != nil {
		t.Fatalf("NewBytesRangeMapperFromJSON: %v", err)
	}
	again, err := restored.MapValue([]byte{0, 255})
	if err != nil {
		t.Fatalf("restored.MapValue: %v", err)
	}
	if len(again) != 2 || again[0] != -1.0 || again[1] != 1.0 {
		t.Fatalf("restored.MapValue = %v, want [-1 1]", again)
	}

	if _, err := mapper.MapValue([]byte{}); err == nil {
		t.Fatal("MapValue(empty) expected an error")
	}
}

func TestImageRangeMapper(t *testing.T) {
	mapper, err := NewDefaultImageRangeMapper()
	if err != nil {
		t.Fatalf("NewDefaultImageRangeMapper: %v", err)
	}

	row, err := mapper.MapValue([]byte{0, 127, 255})
	if err != nil {
		t.Fatalf("MapValue: %v", err)
	}
	if len(row) != 3 || row[0] != -1.0 || row[2] != 1.0 {
		t.Fatalf("MapValue = %v, want [-1 ... 1]", row)
	}

	image, err := mapper.MapRows([][]byte{{0, 127}, {255}})
	if err != nil {
		t.Fatalf("MapRows: %v", err)
	}
	if len(image) != 2 || len(image[0]) != 2 || image[1][0] != 1.0 {
		t.Fatalf("MapRows = %v, want shape-preserving output", image)
	}

	first, err := mapper.MapValue([]byte{127})
	if err != nil {
		t.Fatalf("MapValue first: %v", err)
	}
	second, err := mapper.MapValue([]byte{127})
	if err != nil {
		t.Fatalf("MapValue second: %v", err)
	}
	if len(first) != len(second) || first[0] != second[0] {
		t.Fatalf("determinism changed output: %v vs %v", first, second)
	}

	text, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}
	restored, err := NewImageRangeMapperFromJSON(text)
	if err != nil {
		t.Fatalf("NewImageRangeMapperFromJSON: %v", err)
	}
	if restoredRow, err := restored.MapValue([]byte{0, 255}); err != nil || len(restoredRow) != 2 || restoredRow[0] != -1.0 || restoredRow[1] != 1.0 {
		t.Fatalf("restored.MapValue = %v, %v; want [-1 1], nil", restoredRow, err)
	}

	if _, err := mapper.MapRows([][]byte{}); err == nil {
		t.Fatal("MapRows(empty) expected an error")
	}
}

func TestCategoricalRangeMapper(t *testing.T) {
	mapper, err := NewDefaultCategoricalRangeMapper([]any{"cat", int64(1), true, 'x', 2.5, nil})
	if err != nil {
		t.Fatalf("NewDefaultCategoricalRangeMapper: %v", err)
	}

	cases := []struct {
		value any
		want  float64
	}{
		{"cat", -1.0},
		{int64(1), -0.6},
		{true, -0.2},
		{'x', 0.2},
		{2.5, 0.6},
		{nil, 1.0},
	}

	for _, tc := range cases {
		got, err := mapper.MapValue(tc.value)
		if err != nil {
			t.Fatalf("MapValue(%v): %v", tc.value, err)
		}
		if got != tc.want {
			t.Fatalf("MapValue(%v) = %v, want %v", tc.value, got, tc.want)
		}
	}

	repeatedFirst, err := mapper.MapValue("cat")
	if err != nil {
		t.Fatalf("MapValue(cat) first: %v", err)
	}
	repeatedSecond, err := mapper.MapValue("cat")
	if err != nil {
		t.Fatalf("MapValue(cat) second: %v", err)
	}
	if repeatedFirst != repeatedSecond {
		t.Fatalf("MapValue(cat) repeated = %v, want %v", repeatedSecond, repeatedFirst)
	}

	text, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}
	restored, err := NewCategoricalRangeMapperFromJSON(text)
	if err != nil {
		t.Fatalf("NewCategoricalRangeMapperFromJSON: %v", err)
	}
	if got, err := restored.MapValue(true); err != nil || got != -0.2 {
		t.Fatalf("restored.MapValue(true) = %v, %v; want -0.2, nil", got, err)
	}

	if _, err := mapper.MapValue("wolf"); err == nil {
		t.Fatal("MapValue(unknown) expected an error")
	}

	if _, err := NewDefaultCategoricalRangeMapper([]any{"cat", "cat"}); err == nil {
		t.Fatal("duplicate vocabulary expected an error")
	}
}

func TestTemporalRangeMapper(t *testing.T) {
	mapper, err := NewDefaultTemporalRangeMapper(1_700_000_000_000, 1_700_000_100_000)
	if err != nil {
		t.Fatalf("NewDefaultTemporalRangeMapper: %v", err)
	}

	if got, err := mapper.MapValue(1_700_000_000_000); err != nil || got != -1.0 {
		t.Fatalf("MapValue(lower) = %v, %v; want -1.0, nil", got, err)
	}
	if got, err := mapper.MapValue(1_700_000_050_000); err != nil || got != 0.0 {
		t.Fatalf("MapValue(mid) = %v, %v; want 0.0, nil", got, err)
	}

	text, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}

	restored, err := NewTemporalRangeMapperFromJSON(text)
	if err != nil {
		t.Fatalf("NewTemporalRangeMapperFromJSON: %v", err)
	}

	if got, err := restored.MapTime(time.UnixMilli(1_700_000_050_000)); err != nil || got != 0.0 {
		t.Fatalf("restored.MapTime(mid) = %v, %v; want 0.0, nil", got, err)
	}

	strict, err := NewTemporalRangeMapper(1_700_000_000_000, 1_700_000_100_000, -1.0, 1.0, false)
	if err != nil {
		t.Fatalf("NewTemporalRangeMapper: %v", err)
	}

	if _, err := strict.MapValue(1_700_000_200_000); err == nil {
		t.Fatal("MapValue(out of range) expected an error")
	}
}

func TestSequenceRangeMapper(t *testing.T) {
	integerMapper, err := NewDefaultIntegerRangeMapper(0, 100)
	if err != nil {
		t.Fatalf("NewDefaultIntegerRangeMapper: %v", err)
	}

	sequenceMapper, err := NewSequenceRangeMapper(integerMapper.MapValue, false)
	if err != nil {
		t.Fatalf("NewSequenceRangeMapper: %v", err)
	}

	got, err := sequenceMapper.MapValue([]int64{0, 50, 100})
	if err != nil {
		t.Fatalf("MapValue: %v", err)
	}
	if len(got) != 3 || got[0] != -1.0 || got[1] != 0.0 || got[2] != 1.0 {
		t.Fatalf("MapValue = %v, want [-1 0 1]", got)
	}

	repeated, err := sequenceMapper.MapValue([]int64{0, 50, 100})
	if err != nil {
		t.Fatalf("MapValue repeated: %v", err)
	}
	if len(repeated) != len(got) || repeated[0] != got[0] || repeated[1] != got[1] || repeated[2] != got[2] {
		t.Fatalf("repeated mapping changed output: %v vs %v", repeated, got)
	}

	nestedMapper, err := NewSequenceRangeMapper(sequenceMapper.MapValue, false)
	if err != nil {
		t.Fatalf("nested NewSequenceRangeMapper: %v", err)
	}

	nested, err := nestedMapper.MapValue([][]int64{{0, 50}, {100}})
	if err != nil {
		t.Fatalf("nested MapValue: %v", err)
	}
	if len(nested) != 2 || len(nested[0]) != 2 || nested[0][1] != 0.0 || nested[1][0] != 1.0 {
		t.Fatalf("nested MapValue = %v, want [[-1 0] [1]]", nested)
	}

	if _, err := sequenceMapper.MapValue([]int64{}); err == nil {
		t.Fatal("empty sequence expected an error")
	}

	text, err := sequenceMapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}
	restoredSpec := SequenceMapperSpec{}
	if err := json.Unmarshal([]byte(text), &restoredSpec); err != nil {
		t.Fatalf("json.Unmarshal: %v", err)
	}
	if restoredSpec.MapperType != "sequence_range" || restoredSpec.SpecVersion != SpecVersion || restoredSpec.AllowEmpty {
		t.Fatalf("unexpected spec round-trip: %#v", restoredSpec)
	}
}

func TestTextRangeMapper(t *testing.T) {
	mapper, err := NewDefaultTextRangeMapper("alphabet", "ABC")
	if err != nil {
		t.Fatalf("NewDefaultTextRangeMapper: %v", err)
	}

	got, err := mapper.MapValue("CA")
	if err != nil {
		t.Fatalf("MapValue: %v", err)
	}
	if len(got) != 2 || got[0] != 1.0 || got[1] != -1.0 {
		t.Fatalf("MapValue = %v, want [1 -1]", got)
	}

	roundtrip, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}

	restored, err := NewTextRangeMapperFromJSON(roundtrip)
	if err != nil {
		t.Fatalf("NewTextRangeMapperFromJSON: %v", err)
	}
	if mapped, err := restored.MapValue("B"); err != nil || len(mapped) != 1 || mapped[0] != 0.0 {
		t.Fatalf("restored.MapValue(B) = %v, %v; want [0], nil", mapped, err)
	}

	bytesMapper, err := NewDefaultTextRangeMapper("byte", "")
	if err != nil {
		t.Fatalf("NewDefaultTextRangeMapper(byte): %v", err)
	}
	bytes, err := bytesMapper.MapBytes([]byte{0, 127, 255})
	if err != nil {
		t.Fatalf("MapBytes: %v", err)
	}
	if len(bytes) != 3 || bytes[0] != -1.0 || bytes[2] != 1.0 {
		t.Fatalf("MapBytes = %v, want [-1 ... 1]", bytes)
	}

	if _, err := mapper.MapValue("Z"); err == nil {
		t.Fatal("MapValue(unknown) expected an error")
	}

	if _, err := NewTextRangeMapper("alphabet", "AAB", -1.0, 1.0, false, false, ""); err == nil {
		t.Fatal("duplicate alphabet expected an error")
	}
}

func TestMapObjectRangeMapper(t *testing.T) {
	integerMapper, err := NewDefaultIntegerRangeMapper(0, 100)
	if err != nil {
		t.Fatalf("NewDefaultIntegerRangeMapper: %v", err)
	}
	integerSpec, err := integerMapper.ToJSON()
	if err != nil {
		t.Fatalf("integerMapper.ToJSON: %v", err)
	}

	textMapper, err := NewDefaultTextRangeMapper("alphabet", "AB")
	if err != nil {
		t.Fatalf("NewDefaultTextRangeMapper: %v", err)
	}
	textSpec, err := textMapper.ToJSON()
	if err != nil {
		t.Fatalf("textMapper.ToJSON: %v", err)
	}

	profileMapper, err := NewMapObjectRangeMapper([]MapObjectField{
		{
			Name:       "tier",
			Family:     "integer_range",
			MapperJSON: integerSpec,
		},
	}, false)
	if err != nil {
		t.Fatalf("profileMapper: %v", err)
	}
	profileSpec, err := profileMapper.ToJSON()
	if err != nil {
		t.Fatalf("profileMapper.ToJSON: %v", err)
	}

	sequenceSpec, err := json.Marshal(map[string]any{
		"spec_version": SpecVersion,
		"mapper_type":  "sequence_range",
		"allow_empty":  false,
		"mapper_json":  integerSpec,
	})
	if err != nil {
		t.Fatalf("json.Marshal(sequenceSpec): %v", err)
	}
	sequenceSpecText := string(sequenceSpec)

	mapper, err := NewMapObjectRangeMapper([]MapObjectField{
		{
			Name:       "name",
			Family:     "text_range",
			MapperJSON: textSpec,
		},
		{
			Name:       "score",
			Family:     "integer_range",
			MapperJSON: integerSpec,
		},
		{
			Name:         "samples",
			Family:       "sequence_range",
			MapperJSON:   sequenceSpecText,
			AllowMissing: true,
			MissingValue: func() *float64 {
				value := 0.0
				return &value
			}(),
		},
		{
			Name:       "profile",
			Family:     "map_range",
			MapperJSON: profileSpec,
		},
	}, false)
	if err != nil {
		t.Fatalf("NewMapObjectRangeMapper: %v", err)
	}

	record := map[string]any{
		"name":    "BA",
		"score":   int64(100),
		"profile": map[string]any{"tier": int64(50)},
		"samples": []any{int64(0), int64(50), int64(100)},
	}

	mapped, err := mapper.Map(record)
	if err != nil {
		t.Fatalf("Map: %v", err)
	}
	if len(mapped) != 4 {
		t.Fatalf("len(Map) = %d, want 4", len(mapped))
	}

	repeat, err := mapper.Map(record)
	if err != nil {
		t.Fatalf("Map(repeat): %v", err)
	}
	if len(repeat) != len(mapped) {
		t.Fatalf("len(Map(repeat)) = %d, want %d", len(repeat), len(mapped))
	}
	for i := range mapped {
		if mapped[i] != repeat[i] {
			t.Fatalf("determinism mismatch at %d: %v != %v", i, repeat[i], mapped[i])
		}
	}

	expectedName, err := textMapper.MapValue("BA")
	if err != nil {
		t.Fatalf("expected text value: %v", err)
	}
	expectedProfile, err := profileMapper.Map(map[string]any{"tier": int64(50)})
	if err != nil {
		t.Fatalf("expected profile value: %v", err)
	}
	expectedSamples, err := NewSequenceRangeMapper(integerMapper.MapValue, false)
	if err != nil {
		t.Fatalf("expected sample mapper: %v", err)
	}
	expectedSamplesValue, err := expectedSamples.MapValue([]int64{0, 50, 100})
	if err != nil {
		t.Fatalf("expected sample values: %v", err)
	}
	expectedScore, err := integerMapper.MapValue(100)
	if err != nil {
		t.Fatalf("expected score value: %v", err)
	}
	expected := []float64{
		mean(expectedName),
		mean(expectedProfile),
		mean(expectedSamplesValue),
		expectedScore,
	}
	if len(expected) != len(mapped) {
		t.Fatalf("len(expected) = %d, want %d", len(expected), len(mapped))
	}
	for i := range expected {
		if mapped[i] != expected[i] {
			t.Fatalf("mapped[%d] = %v, want %v", i, mapped[i], expected[i])
		}
	}

	specText, err := mapper.ToJSON()
	if err != nil {
		t.Fatalf("ToJSON: %v", err)
	}
	restored, err := NewMapObjectRangeMapperFromJSON(specText)
	if err != nil {
		t.Fatalf("NewMapObjectRangeMapperFromJSON: %v", err)
	}
	restoredMapped, err := restored.Map(record)
	if err != nil {
		t.Fatalf("restored.Map: %v", err)
	}
	if len(restoredMapped) != len(mapped) {
		t.Fatalf("len(restored.Map) = %d, want %d", len(restoredMapped), len(mapped))
	}

	if _, err := mapper.Map(map[string]any{
		"name":    "A",
		"score":   int64(1),
		"profile": map[string]any{"tier": int64(1)},
		"unknown": int64(1),
	}); err == nil {
		t.Fatal("unknown field should fail in strict mode")
	}

	if _, err := mapper.Map(map[string]any{
		"name": int64(1),
		"score": int64(1),
		"profile": map[string]any{"tier": int64(1)},
	}); err == nil {
		t.Fatal("type mismatch should fail")
	}

	if _, err := mapper.Map(map[string]any{
		"score":  int64(1),
		"profile": map[string]any{"tier": int64(1)},
	}); err == nil {
		t.Fatal("missing required field should fail")
	}

	permissive, err := NewMapObjectRangeMapper([]MapObjectField{
		{
			Name:       "score",
			Family:     "integer_range",
			MapperJSON: integerSpec,
		},
	}, true)
	if err != nil {
		t.Fatalf("permissive mapper: %v", err)
	}
	if permissiveOutput, err := permissive.Map(map[string]any{
		"score":   int64(1),
		"unknown": int64(2),
	}); err != nil {
		t.Fatalf("permissive.Map: %v", err)
	} else if expectedPermissiveScore, scoreErr := integerMapper.MapValue(1); scoreErr != nil {
		t.Fatalf("expectedPermissiveScore: %v", scoreErr)
	} else if len(permissiveOutput) != 1 || permissiveOutput[0] != expectedPermissiveScore {
		t.Fatalf("permissive.Map output: %v", permissiveOutput)
	}
}
