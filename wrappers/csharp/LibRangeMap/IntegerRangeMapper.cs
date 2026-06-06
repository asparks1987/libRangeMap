using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class IntegerRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private NativeMapper _nativeMapper;

    public IntegerRangeMapper(long inputMin, long inputMax, double outputMin = -1.0, double outputMax = 1.0, bool clip = false)
    {
        var native = new NativeMapper();
        var status = NativeMethods.lrm_integer_range_mapper_init(ref native, inputMin, inputMax, outputMin, outputMax, clip ? 1 : 0);
        if (status != 0)
        {
            throw CreateException("init", status);
        }

        _nativeMapper = native;
    }

    private IntegerRangeMapper(NativeMapper nativeMapper)
    {
        _nativeMapper = nativeMapper;
    }

    public double MapValue(long value)
    {
        var status = NativeMethods.lrm_integer_range_mapper_map_value(ref _nativeMapper, value, out var mapped);
        if (status != 0)
        {
            throw CreateException("map_value", status);
        }

        return mapped;
    }

    public double Map(long value) => MapValue(value);

    public MapperSpec Spec()
    {
        var status = NativeMethods.lrm_integer_range_mapper_get_spec(ref _nativeMapper, out var nativeSpec);
        if (status != 0)
        {
            throw CreateException("get_spec", status);
        }

        return new MapperSpec
        {
            SpecVersion = MapperSpec.CurrentSpecVersion,
            MapperType = "integer_range",
            InputRange = new[] { nativeSpec.InputMin, nativeSpec.InputMax },
            OutputRange = new[] { nativeSpec.OutputMin, nativeSpec.OutputMax },
            Clip = nativeSpec.Clip != 0
        };
    }

    public string ToJson() => JsonSerializer.Serialize(Spec(), JsonOptions);

    public static IntegerRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<MapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static IntegerRangeMapper FromSpec(MapperSpec spec)
    {
        if (spec.SpecVersion != MapperSpec.CurrentSpecVersion)
        {
            throw new ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", nameof(spec));
        }

        if (spec.MapperType != "integer_range")
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

        return new IntegerRangeMapper(
            spec.InputRange[0],
            spec.InputRange[1],
            spec.OutputRange[0],
            spec.OutputRange[1],
            spec.Clip);
    }

    private static Exception CreateException(string operation, int status)
    {
        return status switch
        {
            1 => new ArgumentException($"librangemap {operation} failed: invalid range."),
            2 => new InvalidOperationException($"librangemap {operation} failed: invalid value."),
            3 => new ArgumentOutOfRangeException(nameof(operation), $"librangemap {operation} failed: out of range."),
            4 => new InvalidOperationException($"librangemap {operation} failed: null pointer."),
            _ => new InvalidOperationException($"librangemap {operation} failed with native status {status}.")
        };
    }
}

public sealed class MapperSpec
{
    public const string CurrentSpecVersion = "1.0-alpha";

    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "integer_range";

    [JsonPropertyName("input_range")]
    public long[] InputRange { get; init; } = new long[2];

    [JsonPropertyName("output_range")]
    public double[] OutputRange { get; init; } = new double[2];

    [JsonPropertyName("clip")]
    public bool Clip { get; init; }
}
