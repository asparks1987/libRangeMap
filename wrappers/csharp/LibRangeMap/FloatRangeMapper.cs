using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class FloatRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "float_range";

    public double InputMin { get; }
    public double InputMax { get; }
    public double OutputMin { get; }
    public double OutputMax { get; }
    public bool Clip { get; }
    public string? Name { get; }

    public FloatRangeMapper(double inputMin, double inputMax, double outputMin = -1.0, double outputMax = 1.0, bool clip = false, string? name = null)
    {
        ValidateFinite(nameof(inputMin), inputMin);
        ValidateFinite(nameof(inputMax), inputMax);
        ValidateFinite(nameof(outputMin), outputMin);
        ValidateFinite(nameof(outputMax), outputMax);

        if (inputMax <= inputMin)
        {
            throw new ArgumentException("input_range must be ordered from lower value to higher value.");
        }
        if (outputMax <= outputMin)
        {
            throw new ArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (name is not null && name.Length == 0)
        {
            throw new ArgumentException("name must not be empty.", nameof(name));
        }

        InputMin = inputMin;
        InputMax = inputMax;
        OutputMin = outputMin;
        OutputMax = outputMax;
        Clip = clip;
        Name = name;
    }

    public double MapValue(double value)
    {
        ValidateFinite(nameof(value), value);
        if (value < InputMin)
        {
            if (!Clip)
            {
                throw new ArgumentOutOfRangeException(nameof(value), $"value {value} is below input_range lower bound {InputMin}; enable clip to clamp.");
            }
            value = InputMin;
        }
        else if (value > InputMax)
        {
            if (!Clip)
            {
                throw new ArgumentOutOfRangeException(nameof(value), $"value {value} is above input_range upper bound {InputMax}; enable clip to clamp.");
            }
            value = InputMax;
        }

        return MapLinear(value);
    }

    public double Map(double value) => MapValue(value);

    public string ToJson() => JsonSerializer.Serialize(ToSpec(), JsonOptions);

    public FloatMapperSpec ToSpec() => new FloatMapperSpec
    {
        SpecVersion = SpecVersion,
        MapperType = SpecType,
        InputRange = new[] { InputMin, InputMax },
        OutputRange = new[] { OutputMin, OutputMax },
        Clip = Clip,
    };

    public static FloatRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<FloatMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static FloatRangeMapper FromSpec(FloatMapperSpec spec)
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

        return new FloatRangeMapper(
            spec.InputRange[0],
            spec.InputRange[1],
            spec.OutputRange[0],
            spec.OutputRange[1],
            spec.Clip);
    }

    private double MapLinear(double value)
    {
        return OutputMin + ((value - InputMin) / (InputMax - InputMin)) * (OutputMax - OutputMin);
    }

    private static void ValidateFinite(string label, double value)
    {
        if (double.IsNaN(value) || double.IsInfinity(value))
        {
            throw new ArgumentException($"{label} must be a finite number.");
        }
    }
}

public sealed class FloatMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "float_range";

    [JsonPropertyName("input_range")]
    public double[] InputRange { get; init; } = new double[2];

    [JsonPropertyName("output_range")]
    public double[] OutputRange { get; init; } = new double[2];

    [JsonPropertyName("clip")]
    public bool Clip { get; init; }
}
