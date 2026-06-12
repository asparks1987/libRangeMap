package librangemap;

public final class ImageRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "image_range";

    private final double outputMin;
    private final double outputMax;
    private final boolean clip;
    private final boolean allowEmpty;
    private final String name;

    public ImageRangeMapper() {
        this(-1.0, 1.0, false, false, null);
    }

    public ImageRangeMapper(double outputMin, double outputMax) {
        this(outputMin, outputMax, false, false, null);
    }

    public ImageRangeMapper(double outputMin, double outputMax, boolean clip) {
        this(outputMin, outputMax, clip, false, null);
    }

    public ImageRangeMapper(double outputMin, double outputMax, boolean clip, boolean allowEmpty) {
        this(outputMin, outputMax, clip, allowEmpty, null);
    }

    public ImageRangeMapper(double outputMin, double outputMax, boolean clip, boolean allowEmpty, String name) {
        requireFiniteNumber(outputMin, "output_min");
        requireFiniteNumber(outputMax, "output_max");
        if (outputMax <= outputMin) {
            throw new IllegalArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (name != null && name.isEmpty()) {
            throw new IllegalArgumentException("name must not be empty");
        }
        this.outputMin = outputMin;
        this.outputMax = outputMax;
        this.clip = clip;
        this.allowEmpty = allowEmpty;
        this.name = name;
    }

    public double mapValue(double value) {
        return mapScalar(value, "value");
    }

    public double mapValue(int value) {
        return mapScalar(value, "value");
    }

    public double[] mapValue(byte[] value) {
        if (value == null) {
            throw new IllegalArgumentException("value must not be null.");
        }
        if (!allowEmpty && value.length == 0) {
            throw new IllegalArgumentException("empty image-like value is invalid by default; set allowEmpty=true to map empty inputs.");
        }
        double[] output = new double[value.length];
        for (int i = 0; i < value.length; i++) {
            output[i] = mapScalar(value[i] & 0xff, "value[" + i + "]");
        }
        return output;
    }

    public double[] mapValue(int[] value) {
        if (value == null) {
            throw new IllegalArgumentException("value must not be null.");
        }
        if (!allowEmpty && value.length == 0) {
            throw new IllegalArgumentException("empty image-like value is invalid by default; set allowEmpty=true to map empty inputs.");
        }
        double[] output = new double[value.length];
        for (int i = 0; i < value.length; i++) {
            output[i] = mapScalar(value[i], "value[" + i + "]");
        }
        return output;
    }

    public double[] mapValue(double[] value) {
        if (value == null) {
            throw new IllegalArgumentException("value must not be null.");
        }
        if (!allowEmpty && value.length == 0) {
            throw new IllegalArgumentException("empty image-like value is invalid by default; set allowEmpty=true to map empty inputs.");
        }
        double[] output = new double[value.length];
        for (int i = 0; i < value.length; i++) {
            output[i] = mapScalar(value[i], "value[" + i + "]");
        }
        return output;
    }

    public Object[] mapValue(Object[] value) {
        if (value == null) {
            throw new IllegalArgumentException("value must not be null.");
        }
        if (!allowEmpty && value.length == 0) {
            throw new IllegalArgumentException("empty image-like value is invalid by default; set allowEmpty=true to map empty inputs.");
        }
        Object[] output = new Object[value.length];
        for (int i = 0; i < value.length; i++) {
            output[i] = mapNode(value[i], "value[" + i + "]");
        }
        return output;
    }

    public Object mapValue(Object value) {
        if (value instanceof byte[] byteArray) {
            return mapValue(byteArray);
        }
        if (value instanceof int[] intArray) {
            return mapValue(intArray);
        }
        if (value instanceof double[] doubleArray) {
            return mapValue(doubleArray);
        }
        if (value instanceof Object[] objectArray) {
            return mapValue(objectArray);
        }
        if (value instanceof Number number && !(value instanceof Boolean)) {
            return mapScalar(number.doubleValue(), "value");
        }
        throw new IllegalArgumentException("value must be a byte array, int array, double array, object array, or numeric scalar.");
    }

    public Object map(Object value) {
        return mapValue(value);
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append('{');
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append("\",");
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append("\",");
        sb.append("\"input_range\":[0,255],");
        sb.append("\"output_range\":[").append(outputMin).append(',').append(outputMax).append("],");
        sb.append("\"clip\":").append(clip).append(',');
        sb.append("\"allow_empty\":").append(allowEmpty);
        if (name != null) {
            sb.append(',').append("\"name\":\"").append(escape(name)).append('"');
        }
        sb.append('}');
        return sb.toString();
    }

    public static ImageRangeMapper fromJson(String json) {
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
        int[] inputRange = extractIntPairOrNull(json, "input_range");
        if (inputRange != null && (inputRange.length != 2 || inputRange[0] != 0 || inputRange[1] != 255)) {
            throw new IllegalArgumentException("unsupported input_range [" + inputRange[0] + "," + inputRange[1] + "]");
        }
        double[] outputRange = extractDoublePair(json, "output_range");
        Boolean clip = extractBooleanOrNull(json, "clip");
        Boolean allowEmpty = extractBooleanOrNull(json, "allow_empty");
        String name = extractStringOrNull(json, "name");
        return new ImageRangeMapper(
                outputRange[0],
                outputRange[1],
                clip != null && clip,
                allowEmpty != null && allowEmpty,
                name
        );
    }

    private Object mapNode(Object value, String label) {
        if (value == null) {
            throw new IllegalArgumentException(label + " must not be null.");
        }
        if (value instanceof byte[] byteArray) {
            return mapValue(byteArray);
        }
        if (value instanceof int[] intArray) {
            return mapValue(intArray);
        }
        if (value instanceof double[] doubleArray) {
            return mapValue(doubleArray);
        }
        if (value instanceof Object[] objectArray) {
            return mapValue(objectArray);
        }
        if (value instanceof Number number && !(value instanceof Boolean)) {
            return mapScalar(number.doubleValue(), label);
        }
        throw new IllegalArgumentException(label + " must be a numeric pixel value, byte array, numeric array, or nested object array.");
    }

    private double mapScalar(double value, String label) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(label + " must be a finite number.");
        }
        double current = value;
        if (current < 0.0) {
            if (!clip) {
                throw new IllegalArgumentException(label + " is below input_range lower bound 0; enable clip to clamp.");
            }
            current = 0.0;
        } else if (current > 255.0) {
            if (!clip) {
                throw new IllegalArgumentException(label + " is above input_range upper bound 255; enable clip to clamp.");
            }
            current = 255.0;
        }
        return outputMin + ((current / 255.0) * (outputMax - outputMin));
    }

    private static void requireFiniteNumber(double value, String label) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(label + " must be a finite number.");
        }
    }

    private static String extractString(String json, String key) {
        String needle = "\"" + key + "\":\"";
        int start = json.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = json.indexOf('"', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated string for " + key);
        }
        return json.substring(start, end);
    }

    private static String extractStringOrNull(String json, String key) {
        String needle = "\"" + key + "\":\"";
        int start = json.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        int end = json.indexOf('"', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated string for " + key);
        }
        return json.substring(start, end);
    }

    private static int[] extractIntPairOrNull(String json, String key) {
        String needle = "\"" + key + "\":";
        int start = json.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        int end = json.indexOf(']', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated array for " + key);
        }
        String body = json.substring(start + 1, end);
        String[] parts = body.split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException(key + " must contain two values");
        }
        return new int[] { Integer.parseInt(parts[0].trim()), Integer.parseInt(parts[1].trim()) };
    }

    private static double[] extractDoublePair(String json, String key) {
        String needle = "\"" + key + "\":";
        int start = json.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = json.indexOf(']', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated array for " + key);
        }
        String body = json.substring(start + 1, end);
        String[] parts = body.split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException(key + " must contain two values");
        }
        return new double[] { Double.parseDouble(parts[0].trim()), Double.parseDouble(parts[1].trim()) };
    }

    private static Boolean extractBooleanOrNull(String json, String key) {
        String needle = "\"" + key + "\":";
        int start = json.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        if (json.startsWith("true", start)) {
            return true;
        }
        if (json.startsWith("false", start)) {
            return false;
        }
        throw new IllegalArgumentException("invalid boolean for " + key);
    }

    private static String escape(String text) {
        return text.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
