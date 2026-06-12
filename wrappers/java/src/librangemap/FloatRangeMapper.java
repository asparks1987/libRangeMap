package librangemap;

public final class FloatRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "float_range";

    private final double inputMin;
    private final double inputMax;
    private final double outputMin;
    private final double outputMax;
    private final boolean clip;
    private final String name;

    public FloatRangeMapper(double inputMin, double inputMax) {
        this(inputMin, inputMax, -1.0, 1.0, false, null);
    }

    public FloatRangeMapper(
            double inputMin,
            double inputMax,
            double outputMin,
            double outputMax,
            boolean clip) {
        this(inputMin, inputMax, outputMin, outputMax, clip, null);
    }

    public FloatRangeMapper(
            double inputMin,
            double inputMax,
            double outputMin,
            double outputMax,
            boolean clip,
            String name) {
        requireFiniteNumber(inputMin, "inputMin");
        requireFiniteNumber(inputMax, "inputMax");
        requireFiniteNumber(outputMin, "outputMin");
        requireFiniteNumber(outputMax, "outputMax");

        if (inputMax <= inputMin) {
            throw new IllegalArgumentException("input_range must be ordered from lower value to higher value.");
        }
        if (outputMax <= outputMin) {
            throw new IllegalArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (name != null && name.isEmpty()) {
            throw new IllegalArgumentException("name must not be empty");
        }

        this.inputMin = inputMin;
        this.inputMax = inputMax;
        this.outputMin = outputMin;
        this.outputMax = outputMax;
        this.clip = clip;
        this.name = name;
    }

    public double mapValue(double value) {
        requireFiniteNumber(value, "value");

        double current = value;
        if (current < inputMin) {
            if (!clip) {
                throw new IllegalArgumentException("value " + current + " is below input_range lower bound " + inputMin
                        + "; enable clip to clamp.");
            }
            current = inputMin;
        } else if (current > inputMax) {
            if (!clip) {
                throw new IllegalArgumentException("value " + current + " is above input_range upper bound " + inputMax
                        + "; enable clip to clamp.");
            }
            current = inputMax;
        }
        return mapLinear(current, inputMin, inputMax, outputMin, outputMax);
    }

    public double map(double value) {
        return mapValue(value);
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append("\",");
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append("\",");
        sb.append("\"input_range\":[").append(inputMin).append(",").append(inputMax).append("],");
        sb.append("\"output_range\":[").append(outputMin).append(",").append(outputMax).append("],");
        sb.append("\"clip\":").append(clip);
        if (name != null) {
            sb.append(",\"name\":\"").append(escape(name)).append("\"");
        }
        sb.append("}");
        return sb.toString();
    }

    public static FloatRangeMapper fromJson(String json) {
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
        double[] inputRange = extractDoublePair(json, "input_range");
        double[] outputRange = extractDoublePair(json, "output_range");
        Boolean clip = extractBooleanOrNull(json, "clip");
        String name = extractStringOrNull(json, "name");
        return new FloatRangeMapper(
                inputRange[0],
                inputRange[1],
                outputRange[0],
                outputRange[1],
                clip != null && clip,
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

    private static double mapLinear(double value, double inMin, double inMax, double outMin, double outMax) {
        return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
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

    private static Boolean parseBooleanValue(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        if (text.startsWith("true", start)) {
            return true;
        }
        if (text.startsWith("false", start)) {
            return false;
        }
        throw new IllegalArgumentException("invalid boolean for " + key);
    }

    private static Boolean extractBooleanOrNull(String text, String key) {
        Boolean value = parseBooleanValue(text, key);
        if (value == null) {
            return null;
        }
        return value;
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

}
