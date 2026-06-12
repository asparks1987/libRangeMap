using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class TemporalRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "temporal_range";
    private const string InputUnit = "unix_milliseconds";

    public long InputMin { get; }
    public long InputMax { get; }
    public double OutputMin { get; }
    public double OutputMax { get; }
    public bool Clip { get; }
    public string? Name { get; }

    public TemporalRangeMapper(
        long inputMinUnixMilliseconds,
        long inputMaxUnixMilliseconds,
        double outputMin = -1.0,
        double outputMax = 1.0,
        bool clip = false,
        string? name = null)
    {
        ValidateFinite(nameof(outputMin), outputMin);
        ValidateFinite(nameof(outputMax), outputMax);

        if (outputMax <= outputMin)
        {
            throw new ArgumentException("output_range must be ordered from lower value to higher value.");
        }

        if (inputMaxUnixMilliseconds <= inputMinUnixMilliseconds)
        {
            throw new ArgumentException("input_range must be ordered from lower value to higher value.");
        }

        if (name is not null && name.Length == 0)
        {
            throw new ArgumentException("name must not be empty.", nameof(name));
        }

        InputMin = inputMinUnixMilliseconds;
        InputMax = inputMaxUnixMilliseconds;
        OutputMin = outputMin;
        OutputMax = outputMax;
        Clip = clip;
        Name = name;
    }

    public double MapValue(long unixMilliseconds) => MapUnixMilliseconds(unixMilliseconds);

    public double Map(long unixMilliseconds) => MapValue(unixMilliseconds);

    public double MapValue(DateTimeOffset value) => MapUnixMilliseconds(value.ToUnixTimeMilliseconds());

    public double Map(DateTimeOffset value) => MapValue(value);

    public double MapValue(DateTime value)
    {
        if (value.Kind == DateTimeKind.Unspecified)
        {
            throw new ArgumentException("DateTime with Kind=Unspecified is not supported; use UTC, Local, or DateTimeOffset.", nameof(value));
        }

        var utc = value.Kind == DateTimeKind.Utc ? value : value.ToUniversalTime();
        return MapValue(new DateTimeOffset(utc, TimeSpan.Zero));
    }

    public double Map(DateTime value) => MapValue(value);

    public TemporalMapperSpec Spec() => ToSpec();

    public string ToJson() => JsonSerializer.Serialize(ToSpec(), JsonOptions);

    public static TemporalRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<TemporalMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static TemporalRangeMapper FromSpec(TemporalMapperSpec spec)
    {
        if (spec.SpecVersion != SpecVersion)
        {
            throw new ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", nameof(spec));
        }

        if (spec.MapperType != SpecType)
        {
            throw new ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", nameof(spec));
        }

        if (spec.InputUnit != InputUnit)
        {
            throw new ArgumentException($"unsupported input_unit '{spec.InputUnit}'.", nameof(spec));
        }

        if (spec.InputRange is null || spec.InputRange.Length != 2)
        {
            throw new ArgumentException("input_range must contain exactly two values.", nameof(spec));
        }

        if (spec.OutputRange is null || spec.OutputRange.Length != 2)
        {
            throw new ArgumentException("output_range must contain exactly two values.", nameof(spec));
        }

        return new TemporalRangeMapper(
            spec.InputRange[0],
            spec.InputRange[1],
            spec.OutputRange[0],
            spec.OutputRange[1],
            spec.Clip,
            spec.Name);
    }

    private double MapUnixMilliseconds(long value)
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

    private static void ValidateFinite(string label, double value)
    {
        if (double.IsNaN(value) || double.IsInfinity(value))
        {
            throw new ArgumentException($"{label} must be a finite number.");
        }
    }

    private TemporalMapperSpec ToSpec()
    {
        return new TemporalMapperSpec
        {
            SpecVersion = SpecVersion,
            MapperType = SpecType,
            InputUnit = InputUnit,
            InputRange = new[] { InputMin, InputMax },
            OutputRange = new[] { OutputMin, OutputMax },
            Clip = Clip,
            Name = Name
        };
    }
}

public sealed class TemporalMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "temporal_range";

    [JsonPropertyName("input_unit")]
    public string InputUnit { get; init; } = "unix_milliseconds";

    [JsonPropertyName("input_range")]
    public long[] InputRange { get; init; } = new long[2];

    [JsonPropertyName("output_range")]
    public double[] OutputRange { get; init; } = new double[2];

    [JsonPropertyName("clip")]
    public bool Clip { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }
}
