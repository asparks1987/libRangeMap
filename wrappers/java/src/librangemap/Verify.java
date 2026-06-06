package librangemap;

public final class Verify {
    public static void main(String[] args) {
        try (IntegerRangeMapper mapper = new IntegerRangeMapper(0, 100)) {
            assertEqual(mapper.mapValue(0), -1.0, "mapValue(0)");
            assertEqual(mapper.mapValue(50), 0.0, "mapValue(50)");
            assertEqual(mapper.mapValue(100), 1.0, "mapValue(100)");

            MapperSpec spec = mapper.spec();
            if (!"1.0-alpha".equals(spec.getSpecVersion())) {
                throw new IllegalStateException("unexpected spec version");
            }

            IntegerRangeMapper restored = IntegerRangeMapper.fromJson(mapper.toJson());
            assertEqual(restored.mapValue(50), 0.0, "restored.mapValue(50)");
            restored.close();
        }

        try (IntegerRangeMapper clipped = new IntegerRangeMapper(0, 10, -1.0, 1.0, true)) {
            assertEqual(clipped.mapValue(-5), -1.0, "clipped.mapValue(-5)");
        }

        boolean threw = false;
        try (IntegerRangeMapper strict = new IntegerRangeMapper(0, 10, -1.0, 1.0, false)) {
            strict.mapValue(11);
        } catch (IllegalArgumentException expected) {
            threw = true;
        }

        if (!threw) {
            throw new IllegalStateException("strict out-of-range mapping should fail");
        }

        System.out.println("Java wrapper verification passed.");
    }

    private static void assertEqual(double actual, double expected, String label) {
        if (actual != expected) {
            throw new IllegalStateException(label + " = " + actual + ", expected " + expected);
        }
    }
}
