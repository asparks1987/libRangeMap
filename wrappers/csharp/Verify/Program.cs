using LibRangeMap;

static void AssertEqual(double actual, double expected, string label)
{
    if (actual != expected)
    {
        throw new InvalidOperationException($"{label} = {actual}, expected {expected}");
    }
}

var mapper = new IntegerRangeMapper(0, 100);

AssertEqual(mapper.MapValue(0), -1.0, "MapValue(0)");
AssertEqual(mapper.MapValue(50), 0.0, "MapValue(50)");
AssertEqual(mapper.MapValue(100), 1.0, "MapValue(100)");

var spec = mapper.Spec();
if (spec.SpecVersion != MapperSpec.CurrentSpecVersion)
{
    throw new InvalidOperationException($"SpecVersion = {spec.SpecVersion}");
}

var json = mapper.ToJson();
var roundTrip = IntegerRangeMapper.FromJson(json);
AssertEqual(roundTrip.MapValue(50), 0.0, "RoundTrip.MapValue(50)");

var clipped = new IntegerRangeMapper(0, 10, -1.0, 1.0, true);
AssertEqual(clipped.MapValue(-5), -1.0, "Clipped.MapValue(-5)");

var floatMapper = new FloatRangeMapper(0.0, 10.0);
AssertEqual(floatMapper.MapValue(0.0), -1.0, "Float.MapValue(0.0)");
AssertEqual(floatMapper.MapValue(5.0), 0.0, "Float.MapValue(5.0)");
AssertEqual(floatMapper.MapValue(10.0), 1.0, "Float.MapValue(10.0)");

var floatRoundTrip = FloatRangeMapper.FromJson(floatMapper.ToJson());
AssertEqual(floatRoundTrip.MapValue(5.0), 0.0, "Float.RoundTrip.MapValue(5.0)");

var boolMapper = new BooleanRangeMapper();
AssertEqual(boolMapper.MapValue(false), -1.0, "Boolean.MapValue(false)");
AssertEqual(boolMapper.MapValue(true), 1.0, "Boolean.MapValue(true)");

var customBool = new BooleanRangeMapper(-1.0, 2.0, 0.25, 1.75);
AssertEqual(customBool.MapValue(false), 0.25, "Boolean.Custom.MapValue(false)");
AssertEqual(customBool.MapValue(true), 1.75, "Boolean.Custom.MapValue(true)");

var boolRoundTrip = BooleanRangeMapper.FromJson(customBool.ToJson());
AssertEqual(boolRoundTrip.MapValue(false), 0.25, "Boolean.RoundTrip.MapValue(false)");

Console.WriteLine("C# wrapper verification passed.");
