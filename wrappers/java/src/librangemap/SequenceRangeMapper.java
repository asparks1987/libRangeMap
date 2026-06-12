package librangemap;

import java.util.ArrayList;
import java.util.List;

public final class SequenceRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "sequence_range";

    private final Object elementMapper;
    private final boolean allowEmpty;
    private final String name;

    public SequenceRangeMapper(Object elementMapper) {
        this(elementMapper, false, null);
    }

    public SequenceRangeMapper(Object elementMapper, boolean allowEmpty) {
        this(elementMapper, allowEmpty, null);
    }

    public SequenceRangeMapper(Object elementMapper, boolean allowEmpty, String name) {
        if (elementMapper == null) {
            throw new IllegalArgumentException("elementMapper must not be null.");
        }
        validateElementMapper(elementMapper);
        if (name != null && name.isEmpty()) {
            throw new IllegalArgumentException("name must not be empty");
        }
        this.elementMapper = elementMapper;
        this.allowEmpty = allowEmpty;
        this.name = name;
    }

    public Object mapValue(Object value) {
        if (value == null) {
            throw new IllegalArgumentException("value must not be null.");
        }

        if (value instanceof List<?>) {
            List<?> items = (List<?>) value;
            if (!allowEmpty && items.isEmpty()) {
                throw new IllegalArgumentException(
                        "empty sequence is invalid by default; set allowEmpty=true to map empty containers."
                );
            }
            List<Object> mapped = new ArrayList<>(items.size());
            for (Object item : items) {
                mapped.add(mapValueElement(item));
            }
            return mapped;
        }

        if (value.getClass().isArray()) {
            int length = java.lang.reflect.Array.getLength(value);
            if (!allowEmpty && length == 0) {
                throw new IllegalArgumentException(
                        "empty sequence is invalid by default; set allowEmpty=true to map empty containers."
                );
            }
            Object[] mapped = new Object[length];
            for (int i = 0; i < length; i++) {
                mapped[i] = mapValueElement(java.lang.reflect.Array.get(value, i));
            }
            return mapped;
        }

        return mapScalar(value);
    }

    private Object mapValueElement(Object value) {
        if (elementMapper instanceof CategoricalRangeMapper categoricalMapper) {
            return categoricalMapper.mapValue(value);
        }
        if (elementMapper instanceof TextRangeMapper textMapper) {
            if (!(value instanceof String)) {
                return mapScalar(value);
            }
            return textMapper.mapValue((String) value);
        }
        if (elementMapper instanceof BytesRangeMapper bytesMapper) {
            if (value instanceof String || value instanceof byte[] || value instanceof int[]) {
                return bytesMapper.mapValue(value);
            }
            return mapScalar(value);
        }
        if (elementMapper instanceof SequenceRangeMapper nestedMapper) {
            return nestedMapper.mapValue(value);
        }
        if (elementMapper instanceof ObjectRangeMapper objectMapper) {
            return objectMapper.mapValue(value);
        }
        if (elementMapper instanceof TemporalRangeMapper temporalMapper) {
            return temporalMapper.mapValue(value);
        }
        if (value == null) {
            return mapScalar(value);
        }
        Class<?> valueType = value.getClass();
        if (valueType.isArray()) {
            return mapValue(value);
        }
        if (value instanceof List<?>) {
            return mapValue(value);
        }
        return mapScalar(value);
    }

    public Object map(Object value) {
        return mapValue(value);
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append('{');
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append("\",");
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append("\",");
        sb.append("\"element_mapper\":").append(mapperToJson(elementMapper)).append(',');
        sb.append("\"allow_empty\":").append(allowEmpty);
        if (name != null) {
            sb.append(",\"name\":\"").append(escape(name)).append("\"");
        }
        sb.append('}');
        return sb.toString();
    }

    public static SequenceRangeMapper fromJson(String json) {
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

        String elementMapperText = extractObject(json, "element_mapper");
        Object elementMapper = mapperFromJson(elementMapperText);
        Boolean allowEmpty = extractBoolean(json, "allow_empty");
        String name = extractStringOrNull(json, "name");

        return new SequenceRangeMapper(elementMapper, allowEmpty != null && allowEmpty, name);
    }

    private Object mapScalar(Object value) {
        if (elementMapper instanceof IntegerRangeMapper integerMapper) {
            if (!(value instanceof Number)) {
                throw new IllegalArgumentException("value must be a finite integer.");
            }
            return integerMapper.mapValue(((Number) value).longValue());
        }

        if (elementMapper instanceof FloatRangeMapper floatMapper) {
            if (!(value instanceof Number)) {
                throw new IllegalArgumentException("value must be a finite number.");
            }
            return floatMapper.mapValue(((Number) value).doubleValue());
        }

        if (elementMapper instanceof BooleanRangeMapper boolMapper) {
            if (!(value instanceof Boolean)) {
                throw new IllegalArgumentException("value must be a boolean.");
            }
            return boolMapper.mapValue((Boolean) value);
        }
        if (elementMapper instanceof CategoricalRangeMapper categoricalMapper) {
            return categoricalMapper.mapValue(value);
        }

        if (elementMapper instanceof TextRangeMapper textMapper) {
            if (!(value instanceof String)) {
                throw new IllegalArgumentException("value must be a string.");
            }
            return textMapper.mapValue((String) value);
        }

        if (elementMapper instanceof BytesRangeMapper bytesMapper) {
            if (value instanceof byte[] bytes) {
                return bytesMapper.mapValue(bytes);
            }
            if (value instanceof int[] bytes) {
                return bytesMapper.mapValue(bytes);
            }
            if (value instanceof String text) {
                return bytesMapper.mapValue(text);
            }
            throw new IllegalArgumentException("value must be a byte[] int[] or string.");
        }

        if (elementMapper instanceof SequenceRangeMapper sequenceMapper) {
            return sequenceMapper.mapValue(value);
        }

        if (elementMapper instanceof TemporalRangeMapper temporalMapper) {
            return temporalMapper.mapValue(value);
        }

        throw new IllegalArgumentException("unsupported element mapper type " + elementMapper.getClass().getName());
    }

    private static Object mapperFromJson(String json) {
        String mapperType = extractString(json, "mapper_type");
        return switch (mapperType) {
            case "integer_range" -> IntegerRangeMapper.fromJson(json);
            case "float_range" -> FloatRangeMapper.fromJson(json);
            case "boolean_range" -> BooleanRangeMapper.fromJson(json);
            case "categorical_range" -> CategoricalRangeMapper.fromJson(json);
            case "text_range" -> TextRangeMapper.fromJson(json);
            case "bytes_range" -> BytesRangeMapper.fromJson(json);
            case "sequence_range" -> SequenceRangeMapper.fromJson(json);
            case "map_range" -> ObjectRangeMapper.fromJson(json);
            case "temporal_range" -> TemporalRangeMapper.fromJson(json);
            default -> throw new IllegalArgumentException("unsupported mapper_type " + mapperType);
        };
    }

    private static String mapperToJson(Object mapper) {
        if (mapper instanceof IntegerRangeMapper integerMapper) {
            return integerMapper.toJson();
        }
        if (mapper instanceof FloatRangeMapper floatMapper) {
            return floatMapper.toJson();
        }
        if (mapper instanceof BooleanRangeMapper boolMapper) {
            return boolMapper.toJson();
        }
        if (mapper instanceof TextRangeMapper textMapper) {
            return textMapper.toJson();
        }
        if (mapper instanceof BytesRangeMapper bytesMapper) {
            return bytesMapper.toJson();
        }
        if (mapper instanceof CategoricalRangeMapper categoricalMapper) {
            return categoricalMapper.toJson();
        }
        if (mapper instanceof SequenceRangeMapper sequenceMapper) {
            return sequenceMapper.toJson();
        }
        if (mapper instanceof ObjectRangeMapper objectMapper) {
            return objectMapper.toJson();
        }
        if (mapper instanceof TemporalRangeMapper temporalMapper) {
            return temporalMapper.toJson();
        }
        throw new IllegalArgumentException("unsupported element mapper type " + mapper.getClass().getName());
    }

    private static void validateElementMapper(Object elementMapper) {
        if (elementMapper instanceof IntegerRangeMapper
                || elementMapper instanceof FloatRangeMapper
                || elementMapper instanceof BooleanRangeMapper
                || elementMapper instanceof CategoricalRangeMapper
                || elementMapper instanceof TextRangeMapper
                || elementMapper instanceof BytesRangeMapper
                || elementMapper instanceof SequenceRangeMapper
                || elementMapper instanceof ObjectRangeMapper
                || elementMapper instanceof TemporalRangeMapper) {
            return;
        }
        throw new IllegalArgumentException("elementMapper must be a recognized mapper instance.");
    }

    private static String extractObject(String json, String key) {
        String needle = "\"" + key + "\":";
        int start = json.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        while (start < json.length() && Character.isWhitespace(json.charAt(start))) {
            start++;
        }
        if (start >= json.length() || json.charAt(start) != '{') {
            throw new IllegalArgumentException("expected object for " + key);
        }

        int depth = 0;
        boolean inString = false;
        boolean escape = false;
        int end = start;
        for (; end < json.length(); end++) {
            char c = json.charAt(end);
            if (escape) {
                escape = false;
                continue;
            }
            if (c == '\\') {
                escape = true;
                continue;
            }
            if (c == '"') {
                inString = !inString;
                continue;
            }
            if (inString) {
                continue;
            }
            if (c == '{') {
                depth++;
            } else if (c == '}') {
                depth--;
                if (depth == 0) {
                    return json.substring(start, end + 1);
                }
            }
        }
        throw new IllegalArgumentException("unterminated object for " + key);
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

    private static Boolean extractBoolean(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        if (text.startsWith("true", start)) {
            return Boolean.TRUE;
        }
        if (text.startsWith("false", start)) {
            return Boolean.FALSE;
        }
        throw new IllegalArgumentException("invalid boolean for " + key);
    }

    private static String escape(String text) {
        return text.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
