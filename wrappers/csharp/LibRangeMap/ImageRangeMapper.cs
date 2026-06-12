using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class ImageRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "image_range";

    public double OutputMin { get; }
    public double OutputMax { get; }
    public bool Clip { get; }
    public bool AllowEmpty { get; }
    public string? Name { get; }

    public ImageRangeMapper(
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

        OutputMin = outputMin;
        OutputMax = outputMax;
        Clip = clip;
        AllowEmpty = allowEmpty;
        Name = name;
    }

    public double MapValue(long value)
    {
        return MapScalar(value, nameof(value));
    }

    public double MapValue(double value)
    {
        return MapScalar(value, nameof(value));
    }

    public double[] Map(byte[] value)
    {
        if (value is null)
        {
            throw new ArgumentNullException(nameof(value), "image payload must not be null.");
        }
        if (value.Length == 0 && !AllowEmpty)
        {
            throw new ArgumentException("image payload must not be empty unless allow_empty is true.");
        }

        var output = new double[value.Length];
        for (var i = 0; i < value.Length; i++)
        {
            output[i] = MapScalar(value[i] & 0xff, $"value[{i}]");
        }

        return output;
    }

    public double[] Map(ReadOnlySpan<byte> value)
    {
        if (value.Length == 0 && !AllowEmpty)
        {
            throw new ArgumentException("image payload must not be empty unless allow_empty is true.");
        }

        var output = new double[value.Length];
        for (var i = 0; i < value.Length; i++)
        {
            output[i] = MapScalar(value[i] & 0xff, $"value[{i}]");
        }

        return output;
    }

    public object Map(object value)
    {
        return MapNested(value);
    }

    public object MapNested(object value)
    {
        if (value is null)
        {
            throw new ArgumentNullException(nameof(value), "image payload must not be null.");
        }

        if (value is string)
        {
            throw new ArgumentException("string payloads are not supported for image mapping; use bytes or nested numeric containers.");
        }

        if (value is byte[] byteArray)
        {
            return Map(byteArray);
        }

        if (value is IEnumerable enumerable)
        {
            return MapEnumerable(enumerable);
        }

        if (IsNumericScalar(value))
        {
            return MapScalar(Convert.ToDouble(value), "value");
        }

        throw new InvalidOperationException($"unsupported value type '{value.GetType().FullName}'.");
    }

    public string ToJson()
    {
        return JsonSerializer.Serialize(ToSpec(), JsonOptions);
    }

    public static ImageRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<ImageMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static ImageRangeMapper FromSpec(ImageMapperSpec spec)
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
        if (spec.InputRange[0] != 0 || spec.InputRange[1] != 255)
        {
            throw new ArgumentException("image input_range must be [0, 255].", nameof(spec));
        }
        if (spec.OutputRange is null || spec.OutputRange.Length != 2)
        {
            throw new ArgumentException("output_range must contain exactly two values.", nameof(spec));
        }

        return new ImageRangeMapper(
            spec.OutputRange[0],
            spec.OutputRange[1],
            spec.Clip,
            spec.AllowEmpty,
            spec.Name);
    }

    private object MapEnumerable(IEnumerable enumerable)
    {
        var items = new List<object?>();
        foreach (var item in enumerable)
        {
            items.Add(MapNested(item!));
        }

        if (items.Count == 0 && !AllowEmpty)
        {
            throw new ArgumentException("image payload must not be empty unless allow_empty is true.");
        }

        return items.ToArray()!;
    }

    private double MapScalar(double value, string label)
    {
        if (double.IsNaN(value) || double.IsInfinity(value))
        {
            throw new ArgumentException($"{label} must be a finite number.");
        }

        var mapped = value;
        if (mapped < 0)
        {
            if (!Clip)
            {
                throw new ArgumentOutOfRangeException(label, $"value {mapped} is below input_range lower bound 0; enable clip to clamp.");
            }
            mapped = 0;
        }
        else if (mapped > 255)
        {
            if (!Clip)
            {
                throw new ArgumentOutOfRangeException(label, $"value {mapped} is above input_range upper bound 255; enable clip to clamp.");
            }
            mapped = 255;
        }

        return OutputMin + ((mapped / 255.0) * (OutputMax - OutputMin));
    }

    private static bool IsNumericScalar(object value)
    {
        return value is sbyte or byte or short or ushort or int or uint or long or ulong or float or double or decimal;
    }

    private ImageMapperSpec ToSpec()
    {
        return new ImageMapperSpec
        {
            SpecVersion = SpecVersion,
            MapperType = SpecType,
            InputRange = new long[] { 0, 255 },
            OutputRange = new[] { OutputMin, OutputMax },
            Clip = Clip,
            AllowEmpty = AllowEmpty,
            Name = Name,
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

public sealed class ImageMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "image_range";

    [JsonPropertyName("input_range")]
    public long[] InputRange { get; init; } = new long[] { 0, 255 };

    [JsonPropertyName("output_range")]
    public double[] OutputRange { get; init; } = new double[2];

    [JsonPropertyName("clip")]
    public bool Clip { get; init; }

    [JsonPropertyName("allow_empty")]
    public bool AllowEmpty { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }
}
