package librangemap;

public final class BooleanRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "boolean_range";

    private final double outputMin;
    private final double outputMax;
    private final double falseValue;
    private final double trueValue;
    private final String name;

    public BooleanRangeMapper() {
        this(-1.0, 1.0, null, null, null);
    }

    public BooleanRangeMapper(double outputMin, double outputMax) {
        this(outputMin, outputMax, null, null, null);
    }

    public BooleanRangeMapper(double outputMin, double outputMax, Double falseValue, Double trueValue) {
        this(outputMin, outputMax, falseValue, trueValue, null);
    }

    public BooleanRangeMapper(
            double outputMin,
            double outputMax,
            Double falseValue,
            Double trueValue,
            String name) {
        requireFiniteNumber(outputMin, "outputMin");
        requireFiniteNumber(outputMax, "outputMax");

        if (outputMax <= outputMin) {
            throw new IllegalArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (name != null && name.isEmpty()) {
            throw new IllegalArgumentException("name must not be empty");
        }

        this.outputMin = outputMin;
        this.outputMax = outputMax;
        this.falseValue = falseValue == null ? outputMin : falseValue;
        this.trueValue = trueValue == null ? outputMax : trueValue;
        this.name = name;
    }

    public double mapValue(boolean value) {
        return value ? trueValue : falseValue;
    }

    public double map(boolean value) {
        return mapValue(value);
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append("\",");
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append("\",");
        sb.append("\"output_range\":[").append(outputMin).append(",").append(outputMax).append("],");
        sb.append("\"false_value\":").append(falseValue).append(",");
        sb.append("\"true_value\":").append(trueValue);
        if (name != null) {
            sb.append(",\"name\":\"").append(escape(name)).append("\"");
        }
        sb.append("}");
        return sb.toString();
    }

    public static BooleanRangeMapper fromJson(String json) {
        if (json == null) {
            throw new IllegalArgumentException("mapper json must not be null");
        }

        String specVersion = extractString(json, "spec_version");
        if (!SPEC_VERSION.equals(specVersion)) {
            throw new IllegalArgumentException("unsupported spec_version " + specVersion);
        }
        String mapperType = extractString(json, "mapper_type");
        if (!MAPPER_TYPE.equals(mapperType)) {
            throw new IllegalArgumentException("unsupported mapper_type " + mapperType);
        }

        double[] outputRange = extractDoublePair(json, "output_range");
        Double falseValue = extractDoubleOrNull(json, "false_value");
        Double trueValue = extractDoubleOrNull(json, "true_value");
        String name = extractStringOrNull(json, "name");
        return new BooleanRangeMapper(
                outputRange[0],
                outputRange[1],
                falseValue,
                trueValue,
                name
        );
    }

    private static String escape(String text) {
        return text.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static void requireFiniteNumber(double value, String label) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(label + " must be a finite number.");
        }
    }

    private static String extractString(String text, String key) {
        String needle = "\"" + key + "\":\"";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = text.indexOf('"', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated string for " + key);
        }
        return text.substring(start, end);
    }

    private static String extractStringOrNull(String text, String key) {
        String needle = "\"" + key + "\":\"";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        int end = text.indexOf('"', start);
        if (end < 0) {
            return null;
        }
        return text.substring(start, end);
    }

    private static double[] extractDoublePair(String text, String key) {
        String needle = "\"" + key + "\":[";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = text.indexOf(']', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated array for " + key);
        }
        String[] parts = text.substring(start, end).split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException(key + " must contain two values");
        }
        return new double[] {
            Double.parseDouble(parts[0].trim()),
            Double.parseDouble(parts[1].trim()),
        };
    }

    private static Double extractDoubleOrNull(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        int end = text.indexOf(',', start);
        if (end < 0) {
            end = text.indexOf('}', start);
        }
        if (end < 0) {
            throw new IllegalArgumentException("unterminated numeric field for " + key);
        }
        return Double.parseDouble(text.substring(start, end).trim());
    }
}
