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

Console.WriteLine("C# wrapper verification passed.");
