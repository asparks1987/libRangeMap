using System;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class TextRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "text_range";

    public string Mode { get; }
    public long InputMin { get; }
    public long InputMax { get; }
    public double OutputMin { get; }
    public double OutputMax { get; }
    public bool Clip { get; }
    public bool AllowEmpty { get; }
    public string? Alphabet { get; }
    public string? Name { get; }

    public TextRangeMapper(
        string mode = "codepoint",
        string? alphabet = null,
        double outputMin = -1.0,
        double outputMax = 1.0,
        bool clip = false,
        bool allowEmpty = false,
        string? name = null)
    {
        ValidateFinite(nameof(outputMin), outputMin);
        ValidateFinite(nameof(outputMax), outputMax);

        if (outputMax <= outputMin)
        {
            throw new ArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (name is not null && name.Length == 0)
        {
            throw new ArgumentException("name must not be empty.", nameof(name));
        }
        if (mode != "codepoint" && mode != "alphabet" && mode != "byte")
        {
            throw new ArgumentException("mode must be one of 'codepoint', 'alphabet', or 'byte'.");
        }

        Mode = mode;
        Clip = clip;
        AllowEmpty = allowEmpty;
        Alphabet = mode == "alphabet" ? NormalizeAlphabet(alphabet) : null;
        OutputMin = outputMin;
        OutputMax = outputMax;
        Name = name;

        if (Mode == "alphabet")
        {
            if (Alphabet is null)
            {
                throw new ArgumentException("alphabet is required for alphabet mode.");
            }

            if (Alphabet.Length < 2)
            {
                throw new ArgumentException("alphabet mode requires at least 2 symbols.");
            }

            InputMin = 0;
            InputMax = Alphabet.Length - 1;
            return;
        }

        if (Mode == "byte")
        {
            InputMin = 0;
            InputMax = 255;
            return;
        }

        InputMin = 0;
        InputMax = 0x10FFFF;
    }

    public double MapValue(char value)
    {
        if (Mode == "alphabet")
        {
            return MapSymbol(new string(value, 1));
        }

        return MapCodePoint((long)value);
    }

    public double[] Map(string value)
    {
        if (value is null)
        {
            throw new ArgumentNullException(nameof(value), "text payload must not be null.");
        }
        if (value.Length == 0 && !AllowEmpty)
        {
            throw new ArgumentException("text payload must not be empty unless allow_empty is true.");
        }

        if (Mode == "byte")
        {
            var bytes = Encoding.UTF8.GetBytes(value);
            var output = new double[bytes.Length];
            for (var i = 0; i < bytes.Length; i++)
            {
                output[i] = MapUnit(bytes[i]);
            }
            return output;
        }

        if (Mode == "alphabet")
        {
            var output = new double[value.Length];
            for (var i = 0; i < value.Length; i++)
            {
                output[i] = MapSymbol(value[i].ToString());
            }
            return output;
        }

        var units = new int[value.Length];
        var idx = 0;
        var runeCount = 0;
        while (idx < value.Length)
        {
            var rune = Rune.GetRuneAt(value, idx);
            units[runeCount++] = rune.Value;
            idx += rune.Utf16SequenceLength;
        }

        var mapped = new double[runeCount];
        for (var i = 0; i < runeCount; i++)
        {
            mapped[i] = MapUnit(units[i]);
        }

        return mapped;
    }

    public string ToJson() => JsonSerializer.Serialize(ToSpec(), JsonOptions);

    public static TextRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<TextMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static TextRangeMapper FromSpec(TextMapperSpec spec)
    {
        if (spec.SpecVersion != SpecVersion)
        {
            throw new ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", nameof(spec));
        }
        if (spec.MapperType != SpecType)
        {
            throw new ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", nameof(spec));
        }
        if (spec.OutputRange is null || spec.OutputRange.Length != 2)
        {
            throw new ArgumentException("output_range must contain exactly two values.", nameof(spec));
        }
        if (spec.Mode is null)
        {
            throw new ArgumentException("mode is required.", nameof(spec));
        }
        if (spec.InputRange is null || spec.InputRange.Length != 2)
        {
            throw new ArgumentException("input_range must contain exactly two values.", nameof(spec));
        }
        if (spec.Mode == "alphabet")
        {
            if (spec.Alphabet is null || spec.Alphabet.Length < 2)
            {
                throw new ArgumentException("alphabet mode requires an alphabet with at least 2 symbols.", nameof(spec));
            }
            if (spec.InputRange[0] != 0 || spec.InputRange[1] != spec.Alphabet.Length - 1)
            {
                throw new ArgumentException("input_range does not match alphabet length.", nameof(spec));
            }
        }
        if (spec.Mode == "byte" && (spec.InputRange[0] != 0 || spec.InputRange[1] != 255))
        {
            throw new ArgumentException("input_range must be [0,255] for byte mode.", nameof(spec));
        }
        if (spec.Mode == "codepoint" && (spec.InputRange[0] != 0 || spec.InputRange[1] != 0x10FFFF))
        {
            throw new ArgumentException("input_range must be [0,1114111] for codepoint mode.", nameof(spec));
        }
        if (spec.Mode != "codepoint" && spec.Mode != "alphabet" && spec.Mode != "byte")
        {
            throw new ArgumentException("mode must be one of 'codepoint', 'alphabet', or 'byte'.", nameof(spec));
        }

        return new TextRangeMapper(
            spec.Mode,
            spec.Alphabet,
            spec.OutputRange[0],
            spec.OutputRange[1],
            spec.Clip,
            spec.AllowEmpty,
            spec.Name);
    }

    private double MapSymbol(string symbol)
    {
        if (Alphabet is null)
        {
            throw new InvalidOperationException("alphabet is not configured.");
        }

        var index = Alphabet.IndexOf(symbol, StringComparison.Ordinal);
        if (index < 0)
        {
            throw new KeyNotFoundException($"unknown symbol '{symbol}' for alphabet mode.");
        }

        return MapUnit(index);
    }

    private double MapCodePoint(long value)
    {
        return MapUnit(value);
    }

    private double MapUnit(long value)
    {
        var v = (double)value;

        if (value < InputMin)
        {
            if (!Clip)
            {
                throw new ArgumentOutOfRangeException(nameof(value), $"value {v} is below input_range lower bound {InputMin}; enable clip to clamp.");
            }
            v = InputMin;
        }
        else if (value > InputMax)
        {
            if (!Clip)
            {
                throw new ArgumentOutOfRangeException(nameof(value), $"value {v} is above input_range upper bound {InputMax}; enable clip to clamp.");
            }
            v = InputMax;
        }

        return OutputMin + ((v - InputMin) / (InputMax - InputMin)) * (OutputMax - OutputMin);
    }

    private static string? NormalizeAlphabet(string? alphabet)
    {
        if (alphabet is not null && alphabet.Length == 0)
        {
            throw new ArgumentException("alphabet must not be empty.", nameof(alphabet));
        }

        return alphabet;
    }

    private static void ValidateFinite(string label, double value)
    {
        if (double.IsNaN(value) || double.IsInfinity(value))
        {
            throw new ArgumentException($"{label} must be a finite number.");
        }
    }

    private TextMapperSpec ToSpec()
    {
        return new TextMapperSpec
        {
            SpecVersion = SpecVersion,
            MapperType = SpecType,
            Mode = Mode,
            InputRange = new[] { InputMin, InputMax },
            OutputRange = new[] { OutputMin, OutputMax },
            Clip = Clip,
            AllowEmpty = AllowEmpty,
            Alphabet = Alphabet,
            Name = Name
        };
    }
}

public sealed class TextMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "text_range";

    [JsonPropertyName("mode")]
    public string? Mode { get; init; }

    [JsonPropertyName("input_range")]
    public long[] InputRange { get; init; } = new long[2];

    [JsonPropertyName("output_range")]
    public double[] OutputRange { get; init; } = new double[2];

    [JsonPropertyName("clip")]
    public bool Clip { get; init; }

    [JsonPropertyName("allow_empty")]
    public bool AllowEmpty { get; init; }

    [JsonPropertyName("alphabet")]
    public string? Alphabet { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }
}
