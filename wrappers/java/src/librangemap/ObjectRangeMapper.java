package librangemap;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

public final class ObjectRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "map_range";

    private final Map<String, Object> schema;
    private final boolean allowUnknown;
    private final boolean allowEmpty;
    private final boolean hasMissingValue;
    private final Object missingValue;
    private final String name;

    public ObjectRangeMapper(Map<String, Object> schema) {
        this(schema, false, false, false, null, null);
    }

    public ObjectRangeMapper(Map<String, Object> schema, boolean allowUnknown, boolean allowEmpty) {
        this(schema, allowUnknown, allowEmpty, false, null, null);
    }

    public ObjectRangeMapper(
            Map<String, Object> schema,
            boolean allowUnknown,
            boolean allowEmpty,
            boolean hasMissingValue,
            Object missingValue,
            String name) {
        if (schema == null) {
            throw new IllegalArgumentException("schema must not be null.");
        }

        if (!nameIsValid(name)) {
            throw new IllegalArgumentException("name must not be empty.");
        }

        if (!allowEmpty && schema.isEmpty()) {
            throw new IllegalArgumentException("schema is empty by default; set allowEmpty=true to allow empty schemas.");
        }

        this.schema = validateSchema(schema);
        this.allowUnknown = allowUnknown;
        this.allowEmpty = allowEmpty;
        this.hasMissingValue = hasMissingValue;
        this.missingValue = missingValue;
        this.name = name;
    }

    public Map<String, Object> mapValue(Object value) {
        return map(value);
    }

    public Map<String, Object> map(Object value) {
        if (value == null) {
            throw new IllegalArgumentException("value must not be null.");
        }

        if (value instanceof Map<?, ?> valueMap) {
            return mapFromMap(valueMap);
        }

        return mapFromObject(value);
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append("\",");
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append("\",");
        sb.append("\"schema\":{");
        boolean first = true;
        for (Map.Entry<String, Object> entry : schema.entrySet()) {
            if (!first) {
                sb.append(',');
            }
            first = false;
            sb.append("\"").append(escape(entry.getKey())).append("\":")
                .append(mapperToJson(entry.getValue()));
        }
        sb.append("},");
        sb.append("\"allow_unknown\":").append(allowUnknown).append(",");
        sb.append("\"allow_empty\":").append(allowEmpty).append(",");
        sb.append("\"has_missing_value\":").append(hasMissingValue);
        if (hasMissingValue) {
            sb.append(",\"missing_value\":").append(missingToJson(missingValue));
        }
        if (name != null) {
            sb.append(",\"name\":\"").append(escape(name)).append("\"");
        }
        sb.append("}");
        return sb.toString();
    }

    public static ObjectRangeMapper fromJson(String json) {
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

        boolean allowEmpty = extractBooleanOrFalse(json, "allow_empty");
        String schemaText = extractObject(json, "schema");
        Map<String, Object> parsedSchema = parseSchema(schemaText, allowEmpty);
        boolean allowUnknown = extractBooleanOrFalse(json, "allow_unknown");
        boolean hasMissingValue = extractBooleanOrFalse(json, "has_missing_value");
        String missingText = extractRawValue(json, "missing_value");
        String name = extractStringOrNull(json, "name");

        Object missingValue = null;
        if (hasMissingValue) {
            if (missingText == null) {
                throw new IllegalArgumentException("missing_value is required when has_missing_value=true.");
            }
            missingValue = parsePrimitiveValue(missingText);
        }

        return new ObjectRangeMapper(
            parsedSchema,
            allowUnknown,
            allowEmpty,
            hasMissingValue,
            missingValue,
            name
        );
    }

    private Map<String, Object> mapFromMap(Map<?, ?> valueMap) {
        Map<String, Object> mapped = new LinkedHashMap<>(schema.size());
        Map<String, Object> input = new LinkedHashMap<>();

        for (Map.Entry<?, ?> entry : valueMap.entrySet()) {
            if (!(entry.getKey() instanceof String key)) {
                throw new IllegalArgumentException("map keys must be non-empty strings.");
            }
            if (key.isEmpty()) {
                throw new IllegalArgumentException("map keys must be non-empty strings.");
            }
            input.put(key, entry.getValue());
        }

        if (!allowEmpty && input.isEmpty()) {
            throw new IllegalArgumentException(
                    "empty map payload is invalid by default; set allowEmpty=true to map empty maps."
            );
        }

        if (!allowUnknown) {
            List<String> unknownFields = new ArrayList<>();
            for (String key : input.keySet()) {
                if (!schema.containsKey(key)) {
                    unknownFields.add(key);
                }
            }
            if (!unknownFields.isEmpty()) {
                throw new IllegalArgumentException(
                        "unknown schema fields: " + String.join(", ", unknownFields)
                            + "; set allowUnknown=true to ignore extra fields."
                );
            }
        }

        for (Map.Entry<String, Object> schemaEntry : schema.entrySet()) {
            String fieldName = schemaEntry.getKey();
            Object mapper = schemaEntry.getValue();
            if (input.containsKey(fieldName)) {
                mapped.put(fieldName, mapField(fieldName, mapper, input.get(fieldName)));
            } else if (hasMissingValue) {
                mapped.put(fieldName, missingValue);
            } else {
                throw new IllegalArgumentException("missing required field '" + fieldName + "' in map input.");
            }
        }

        return mapped;
    }

    private Map<String, Object> mapFromObject(Object value) {
        Map<String, Object> mapped = new LinkedHashMap<>(schema.size());
        if (!allowUnknown) {
            List<String> unknownFields = unexpectedObjectFields(value);
            if (!unknownFields.isEmpty()) {
                throw new IllegalArgumentException(
                        "unknown schema fields: " + String.join(", ", unknownFields)
                                + "; set allowUnknown=true to ignore extra fields."
                );
            }
        }

        boolean mappedAtLeastOne = false;

        for (Map.Entry<String, Object> schemaEntry : schema.entrySet()) {
            String fieldName = schemaEntry.getKey();
            Object mapper = schemaEntry.getValue();
            if (tryGetMember(value, fieldName)) {
                mapped.put(fieldName, mapField(fieldName, mapper, getMemberValue(value, fieldName)));
                mappedAtLeastOne = true;
            } else if (hasMissingValue) {
                mapped.put(fieldName, missingValue);
            } else {
                throw new IllegalArgumentException("missing required field '" + fieldName + "' in object input.");
            }
        }

        if (!allowEmpty && !mappedAtLeastOne) {
            throw new IllegalArgumentException("empty object payload is invalid by default; set allowEmpty=true to map empty objects.");
        }

        return mapped;
    }

    private List<String> unexpectedObjectFields(Object value) {
        Set<String> members = collectReadableMembers(value.getClass());
        List<String> unknown = new ArrayList<>();
        for (String member : members) {
            if (!schema.containsKey(member)) {
                unknown.add(member);
            }
        }
        return unknown;
    }

    private static Set<String> collectReadableMembers(Class<?> type) {
        Set<String> members = new HashSet<>();
        for (var field : type.getFields()) {
            if (field.getName() != null && !field.getName().isEmpty()) {
                members.add(field.getName());
            }
        }
        for (var method : type.getMethods()) {
            if (method.getParameterCount() != 0 || method.getReturnType() == void.class) {
                continue;
            }
            String methodName = method.getName();
            if (methodName.equals("getClass")) {
                continue;
            }
            if (methodName.startsWith("get") && methodName.length() > 3) {
                members.add(decapitalize(methodName.substring(3)));
                continue;
            }
            if (methodName.startsWith("is") && methodName.length() > 2 && method.getReturnType() == boolean.class) {
                members.add(decapitalize(methodName.substring(2)));
            }
        }
        return members;
    }

    private static String decapitalize(String input) {
        if (input.isEmpty()) {
            return input;
        }
        return input.substring(0, 1).toLowerCase(Locale.ROOT) + input.substring(1);
    }

    private static Map<String, Object> parseSchema(String text, boolean allowEmpty) {
        String schemaContent = stripOuterObject(text);
        Map<String, Object> schema = new LinkedHashMap<>();
        int index = 0;
        while (index < schemaContent.length()) {
            index = skipWhitespace(schemaContent, index);
            if (index >= schemaContent.length()) {
                break;
            }
            if (schemaContent.charAt(index) == '}') {
                break;
            }
            if (schemaContent.charAt(index) != '"') {
                throw new IllegalArgumentException("invalid schema json key.");
            }

            int keyStart = index + 1;
            int keyEnd = findEndOfQuoted(schemaContent, keyStart);
            String key = schemaContent.substring(keyStart, keyEnd);
            if (key.isEmpty()) {
                throw new IllegalArgumentException("schema field names must be non-empty strings.");
            }
            index = keyEnd + 1;
            index = skipWhitespace(schemaContent, index);
            if (index >= schemaContent.length() || schemaContent.charAt(index) != ':') {
                throw new IllegalArgumentException("expected ':' after schema key '" + key + "'.");
            }
            index++;
            index = skipWhitespace(schemaContent, index);
            int valueStart = index;
            if (schemaContent.charAt(index) != '{') {
                throw new IllegalArgumentException("schema field '" + key + "' expects a mapper object.");
            }
            String mapperJson = extractObjectFromIndex(schemaContent, index);
            schema.put(key, mapperFromJson(mapperJson));
            index = valueStart + mapperJson.length();

            index = skipWhitespace(schemaContent, index);
            if (index < schemaContent.length() && schemaContent.charAt(index) == ',') {
                index++;
            }
        }

        if (!allowEmpty && !allowEmptySchema(schema)) {
            throw new IllegalArgumentException("schema is empty by default; set allowEmpty=true to allow empty schemas.");
        }
        return schema;
    }

    private static Map<String, Object> validateSchema(Map<String, Object> value) {
        Map<String, Object> normalized = new LinkedHashMap<>(value.size());
        for (Map.Entry<String, Object> entry : value.entrySet()) {
            if (entry.getKey() == null || entry.getKey().isEmpty()) {
                throw new IllegalArgumentException("schema field names must be non-empty strings.");
            }
            Object mapper = entry.getValue();
            if (mapper == null) {
                throw new IllegalArgumentException("schema field '" + entry.getKey() + "' mapper must not be null.");
            }
            validateMapper(mapper);
            normalized.put(entry.getKey(), mapper);
        }
        return normalized;
    }

    private Object mapField(String fieldName, Object mapper, Object value) {
        if (mapper instanceof IntegerRangeMapper integerMapper) {
            return integerMapper.mapValue(toLong(fieldName, value));
        }
        if (mapper instanceof FloatRangeMapper floatMapper) {
            return floatMapper.mapValue(toDouble(fieldName, value));
        }
        if (mapper instanceof BooleanRangeMapper boolMapper) {
            if (!(value instanceof Boolean boolValue)) {
                throw new IllegalArgumentException("field '" + fieldName + "' expects a boolean.");
            }
            return boolMapper.mapValue(boolValue);
        }
        if (mapper instanceof CategoricalRangeMapper categoricalMapper) {
            return categoricalMapper.mapValue(value);
        }
        if (mapper instanceof TextRangeMapper textMapper) {
            return textMapper.mapValue(toSingleCharacter(fieldName, value));
        }
        if (mapper instanceof BytesRangeMapper bytesMapper) {
            if (value instanceof byte[] byteValue) {
                return bytesMapper.mapValue(byteValue);
            }
            if (value instanceof int[] intValue) {
                return bytesMapper.mapValue(intValue);
            }
            if (value instanceof String stringValue) {
                return bytesMapper.mapValue(stringValue);
            }
            throw new IllegalArgumentException(
                    "field '" + fieldName + "' expects bytes policy-compatible input (byte[], int[], or string)."
            );
        }
        if (mapper instanceof SequenceRangeMapper sequenceMapper) {
            return sequenceMapper.mapValue(value);
        }
        if (mapper instanceof ObjectRangeMapper objectMapper) {
            return objectMapper.mapValue(value);
        }
        if (mapper instanceof TemporalRangeMapper temporalMapper) {
            return temporalMapper.mapValue(value);
        }
        throw new IllegalArgumentException(
                "unsupported schema mapper type for field '" + fieldName + "': " + mapper.getClass().getName()
        );
    }

    private static long toLong(String fieldName, Object value) {
        if (value instanceof Byte v) {
            return v;
        }
        if (value instanceof Short v) {
            return v;
        }
        if (value instanceof Integer v) {
            return v;
        }
        if (value instanceof Long v) {
            return v;
        }
        throw new IllegalArgumentException("field '" + fieldName + "' expects integer values.");
    }

    private static double toDouble(String fieldName, Object value) {
        if (!(value instanceof Float || value instanceof Double)) {
            throw new IllegalArgumentException("field '" + fieldName + "' expects float values.");
        }
        return ((Number) value).doubleValue();
    }

    private static String toSingleCharacter(String fieldName, Object value) {
        if (value instanceof Character ch) {
            return String.valueOf(ch);
        }
        if (value instanceof String text) {
            if (text.codePointCount(0, text.length()) != 1) {
                throw new IllegalArgumentException("field '" + fieldName + "' expects exactly one character.");
            }
            return text;
        }
        throw new IllegalArgumentException("field '" + fieldName + "' expects a single character.");
    }

    private boolean tryGetMember(Object value, String fieldName) {
        return tryGetField(value, fieldName) || tryGetGetter(value, fieldName);
    }

    private Object getMemberValue(Object value, String fieldName) {
        try {
            if (tryGetField(value, fieldName)) {
                try {
                    return value.getClass().getField(fieldName).get(value);
                } catch (ReflectiveOperationException e) {
                    throw new IllegalArgumentException(
                            "field '" + fieldName + "' is not accessible in object input."
                    );
                }
            }
            return tryGetGetterValue(value, fieldName);
        } catch (ReflectiveOperationException e) {
            throw new IllegalArgumentException("failed to read field '" + fieldName + "' from object input.");
        }
    }

    private static boolean tryGetField(Object value, String fieldName) {
        try {
            value.getClass().getField(fieldName);
            return true;
        } catch (NoSuchFieldException e) {
            return false;
        }
    }

    private static boolean tryGetGetter(Object value, String fieldName) {
        String upper = fieldName.substring(0, 1).toUpperCase(Locale.ROOT) + fieldName.substring(1);
        try {
            value.getClass().getMethod("get" + upper);
            return true;
        } catch (NoSuchMethodException e) {
            try {
                value.getClass().getMethod("is" + upper);
                return true;
            } catch (NoSuchMethodException e2) {
                return false;
            }
        }
    }

    private static Object tryGetGetterValue(Object value, String fieldName) throws ReflectiveOperationException {
        String upper = fieldName.substring(0, 1).toUpperCase(Locale.ROOT) + fieldName.substring(1);
        try {
            var method = value.getClass().getMethod("get" + upper);
            return method.invoke(value);
        } catch (NoSuchMethodException e) {
            var method = value.getClass().getMethod("is" + upper);
            return method.invoke(value);
        }
    }

    private static Object parsePrimitiveValue(String json) {
        if (json == null) {
            return null;
        }
        String normalized = json.strip();
        if (normalized.isEmpty()) {
            throw new IllegalArgumentException("missing_value cannot be empty.");
        }
        if ("null".equals(normalized)) {
            return null;
        }
        if ("true".equals(normalized) || "false".equals(normalized)) {
            return Boolean.parseBoolean(normalized);
        }
        if (normalized.startsWith("\"") && normalized.endsWith("\"") && normalized.length() >= 2) {
            return unescape(normalized.substring(1, normalized.length() - 1));
        }
        try {
            if (normalized.contains(".") || normalized.contains("e") || normalized.contains("E")) {
                return Double.parseDouble(normalized);
            }
            return Long.parseLong(normalized);
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("missing_value must be a JSON primitive.");
        }
    }

    private static String missingToJson(Object value) {
        if (value == null) {
            return "null";
        }
        if (value instanceof Number number) {
            return Double.toString(number.doubleValue());
        }
        if (value instanceof Boolean bool) {
            return bool.toString();
        }
        return "\"" + escape(String.valueOf(value)) + "\"";
    }

    private static void validateMapper(Object mapper) {
        if (mapper instanceof IntegerRangeMapper
                || mapper instanceof FloatRangeMapper
                || mapper instanceof BooleanRangeMapper
                || mapper instanceof BytesRangeMapper
                || mapper instanceof CategoricalRangeMapper
                || mapper instanceof TextRangeMapper
                || mapper instanceof SequenceRangeMapper
                || mapper instanceof ObjectRangeMapper
                || mapper instanceof TemporalRangeMapper) {
            return;
        }
        throw new IllegalArgumentException("schema values must be supported mapper instances.");
    }

    private static Object mapperFromJson(String json) {
        String mapperType = extractString(json, "mapper_type");
        return switch (mapperType) {
            case "integer_range" -> IntegerRangeMapper.fromJson(json);
            case "float_range" -> FloatRangeMapper.fromJson(json);
            case "boolean_range" -> BooleanRangeMapper.fromJson(json);
            case "bytes_range" -> BytesRangeMapper.fromJson(json);
            case "categorical_range" -> CategoricalRangeMapper.fromJson(json);
            case "text_range" -> TextRangeMapper.fromJson(json);
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
        throw new IllegalArgumentException("unsupported mapper type " + mapper.getClass().getName());
    }

    private static boolean allowEmptySchema(Map<String, Object> schema) {
        return !schema.isEmpty();
    }

    private static boolean nameIsValid(String name) {
        return name == null || !name.isEmpty();
    }

    private static int findEndOfQuoted(String text, int start) {
        boolean escape = false;
        for (int i = start; i < text.length(); i++) {
            char c = text.charAt(i);
            if (escape) {
                escape = false;
                continue;
            }
            if (c == '\\') {
                escape = true;
                continue;
            }
            if (c == '"') {
                return i;
            }
        }
        throw new IllegalArgumentException("unterminated string in schema.");
    }

    private static String stripOuterObject(String text) {
        if (text == null || text.isEmpty()) {
            return "";
        }
        if (text.charAt(0) != '{' || text.charAt(text.length() - 1) != '}') {
            throw new IllegalArgumentException("expected object.");
        }
        return text.substring(1, text.length() - 1).trim();
    }

    private static String extractObject(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        while (start < text.length() && Character.isWhitespace(text.charAt(start))) {
            start++;
        }
        if (start >= text.length() || text.charAt(start) != '{') {
            throw new IllegalArgumentException("expected object for " + key);
        }
        return extractObjectFromIndex(text, start);
    }

    private static String extractObjectFromIndex(String text, int start) {
        if (start >= text.length() || text.charAt(start) != '{') {
            throw new IllegalArgumentException("expected object");
        }
        int depth = 0;
        boolean inString = false;
        boolean escape = false;
        for (int i = start; i < text.length(); i++) {
            char c = text.charAt(i);
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
                    return text.substring(start, i + 1);
                }
            }
        }
        throw new IllegalArgumentException("unterminated object");
    }

    private static String extractRawValue(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        while (start < text.length() && Character.isWhitespace(text.charAt(start))) {
            start++;
        }
        if (start >= text.length()) {
            return null;
        }

        int end = start;
        if (text.charAt(start) == '"' || text.charAt(start) == '{' || text.charAt(start) == '[') {
            end = indexAfterComplexValue(text, start);
        } else {
            while (end < text.length() && text.charAt(end) != ',' && text.charAt(end) != '}') {
                end++;
            }
        }
        if (end < start) {
            return null;
        }
        return text.substring(start, end).trim();
    }

    private static int indexAfterComplexValue(String text, int start) {
        if (text.charAt(start) == '"') {
            int end = start + 1;
            boolean escape = false;
            while (end < text.length()) {
                char c = text.charAt(end);
                if (escape) {
                    escape = false;
                    end++;
                    continue;
                }
                if (c == '\\') {
                    escape = true;
                } else if (c == '"') {
                    return end + 1;
                }
                end++;
            }
            throw new IllegalArgumentException("unterminated string");
        }

        if (text.charAt(start) == '{' || text.charAt(start) == '[') {
            boolean inString = false;
            boolean escape = false;
            int depth = 0;
            char closing = text.charAt(start) == '{' ? '}' : ']';
            for (int i = start; i < text.length(); i++) {
                char c = text.charAt(i);
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
                if (c == text.charAt(start)) {
                    depth++;
                } else if (c == closing) {
                    depth--;
                    if (depth == 0) {
                        return i + 1;
                    }
                }
            }
            throw new IllegalArgumentException("unterminated collection value");
        }
        return start;
    }

    private static boolean extractBooleanOrFalse(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return false;
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

    private static int skipWhitespace(String text, int index) {
        while (index < text.length() && Character.isWhitespace(text.charAt(index))) {
            index++;
        }
        return index;
    }

    private static String unescape(String value) {
        return value.replace("\\\"", "\"").replace("\\\\", "\\");
    }

    private static String escape(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
