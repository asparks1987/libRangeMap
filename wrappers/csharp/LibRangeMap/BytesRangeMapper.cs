using System;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class BytesRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "bytes_range";

    public long InputMin { get; }
    public long InputMax { get; }
    public double OutputMin { get; }
    public double OutputMax { get; }
    public bool Clip { get; }
    public bool AllowEmpty { get; }

    public BytesRangeMapper(
        long inputMin = 0,
        long inputMax = 255,
        double outputMin = -1.0,
        double outputMax = 1.0,
        bool clip = false,
        bool allowEmpty = false)
    {
        ValidateFinite(nameof(outputMin), outputMin);
        ValidateFinite(nameof(outputMax), outputMax);

        if (outputMax <= outputMin)
        {
            throw new ArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (inputMax <= inputMin)
        {
            throw new ArgumentException("input_range must be ordered from lower value to higher value.");
        }

        InputMin = inputMin;
        InputMax = inputMax;
        OutputMin = outputMin;
        OutputMax = outputMax;
        Clip = clip;
        AllowEmpty = allowEmpty;
    }

    public double MapValue(long value)
    {
        var clamped = ClampValue(value, nameof(value));
        return MapLinear(clamped);
    }

    public double[] Map(byte[] value)
    {
        if (value is null)
        {
            throw new ArgumentNullException(nameof(value), "bytes payload must not be null.");
        }
        if (value.Length == 0 && !AllowEmpty)
        {
            throw new ArgumentException("bytes payload must not be empty unless allow_empty is true.");
        }

        var output = new double[value.Length];
        for (var i = 0; i < value.Length; i++)
        {
            output[i] = MapValue(value[i]);
        }

        return output;
    }

    public double[] Map(ReadOnlySpan<byte> value)
    {
        if (value.Length == 0 && !AllowEmpty)
        {
            throw new ArgumentException("bytes payload must not be empty unless allow_empty is true.");
        }

        var output = new double[value.Length];
        for (var i = 0; i < value.Length; i++)
        {
            output[i] = MapValue(value[i]);
        }

        return output;
    }

    public double[] Map(string value)
    {
        if (value is null)
        {
            throw new ArgumentNullException(nameof(value), "string payload must not be null.");
        }
        return Map(Encoding.UTF8.GetBytes(value));
    }

    public string ToJson() => JsonSerializer.Serialize(ToSpec(), JsonOptions);

    public static BytesRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<BytesMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static BytesRangeMapper FromSpec(BytesMapperSpec spec)
    {
        if (spec.SpecVersion != SpecVersion)
        {
            throw new ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", nameof(spec));
        }
        if (spec.MapperType != SpecType)
        {
            throw new ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", nameof(spec));
        }
        if (spec.InputRange is null || spec.InputRange.Length != 2)
        {
            throw new ArgumentException("input_range must contain exactly two values.", nameof(spec));
        }
        if (spec.OutputRange is null || spec.OutputRange.Length != 2)
        {
            throw new ArgumentException("output_range must contain exactly two values.", nameof(spec));
        }

        return new BytesRangeMapper(
            spec.InputRange[0],
            spec.InputRange[1],
            spec.OutputRange[0],
            spec.OutputRange[1],
            spec.Clip,
            spec.AllowEmpty);
    }

    private long ClampValue(long value, string label)
    {
        if (value < InputMin)
        {
            if (!Clip)
            {
                throw new ArgumentOutOfRangeException(label, $"value {value} is below input_range lower bound {InputMin}; enable clip to clamp.");
            }
            value = InputMin;
        }
        else if (value > InputMax)
        {
            if (!Clip)
            {
                throw new ArgumentOutOfRangeException(label, $"value {value} is above input_range upper bound {InputMax}; enable clip to clamp.");
            }
            value = InputMax;
        }

        return value;
    }

    private double MapLinear(long value)
    {
        return OutputMin + ((value - InputMin) / (double)(InputMax - InputMin)) * (OutputMax - OutputMin);
    }

    private BytesMapperSpec ToSpec()
    {
        return new BytesMapperSpec
        {
            SpecVersion = SpecVersion,
            MapperType = SpecType,
            InputRange = new[] { InputMin, InputMax },
            OutputRange = new[] { OutputMin, OutputMax },
            Clip = Clip,
            AllowEmpty = AllowEmpty,
        };
    }

    private static void ValidateFinite(string label, double value)
    {
        if (double.IsNaN(value) || double.IsInfinity(value))
        {
            throw new ArgumentException($"{label} must be a finite number.");
        }
    }
}

public sealed class BytesMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "bytes_range";

    [JsonPropertyName("input_range")]
    public long[] InputRange { get; init; } = new long[2];

    [JsonPropertyName("output_range")]
    public double[] OutputRange { get; init; } = new double[2];

    [JsonPropertyName("clip")]
    public bool Clip { get; init; }

    [JsonPropertyName("allow_empty")]
    public bool AllowEmpty { get; init; }
}
