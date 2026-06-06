//go:build windows && cgo

package librangemap

import "testing"

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
