using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class BooleanRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "boolean_range";

    public double OutputMin { get; }
    public double OutputMax { get; }
    public double FalseValue { get; }
    public double TrueValue { get; }
    public string? Name { get; }

    public BooleanRangeMapper(
        double outputMin = -1.0,
        double outputMax = 1.0,
        double? falseValue = null,
        double? trueValue = null,
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

        OutputMin = outputMin;
        OutputMax = outputMax;
        FalseValue = falseValue ?? outputMin;
        TrueValue = trueValue ?? outputMax;
        Name = name;
    }

    public double MapValue(bool value) => value ? TrueValue : FalseValue;

    public double Map(bool value) => MapValue(value);

    public string ToJson() => JsonSerializer.Serialize(ToSpec(), JsonOptions);

    private BooleanMapperSpec ToSpec() => new()
    {
        SpecVersion = SpecVersion,
        MapperType = SpecType,
        OutputRange = new[] { OutputMin, OutputMax },
        FalseValue = FalseValue,
        TrueValue = TrueValue,
        Name = Name,
    };

    public static BooleanRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<BooleanMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static BooleanRangeMapper FromSpec(BooleanMapperSpec spec)
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
        if (double.IsNaN(spec.FalseValue) || double.IsInfinity(spec.FalseValue)
            || double.IsNaN(spec.TrueValue) || double.IsInfinity(spec.TrueValue))
        {
            throw new ArgumentException("false_value and true_value must be finite.");
        }

        return new BooleanRangeMapper(
            spec.OutputRange[0],
            spec.OutputRange[1],
            spec.FalseValue,
            spec.TrueValue,
            spec.Name);
    }

    private static void ValidateFinite(string label, double value)
    {
        if (double.IsNaN(value) || double.IsInfinity(value))
        {
            throw new ArgumentException($"{label} must be a finite number.");
        }
    }
}

public sealed class BooleanMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "boolean_range";

    [JsonPropertyName("output_range")]
    public double[] OutputRange { get; init; } = new double[2];

    [JsonPropertyName("false_value")]
    public double FalseValue { get; init; }

    [JsonPropertyName("true_value")]
    public double TrueValue { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }
}
