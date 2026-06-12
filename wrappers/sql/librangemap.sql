-- libRangeMap SQL integer mapping reference for Alpha v1.
-- This routine is dependency-free and mirrors the shared linear mapping contract.

CREATE OR REPLACE FUNCTION libRangeMap_map_integer(
  p_value BIGINT,
  p_input_min BIGINT,
  p_input_max BIGINT,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_clip BOOLEAN DEFAULT FALSE
) RETURNS DOUBLE PRECISION AS
$$
DECLARE
  v_value BIGINT;
  v_span BIGINT;
  v_out_span DOUBLE PRECISION;
BEGIN
  IF p_input_min >= p_input_max THEN
    RAISE EXCEPTION 'input_min must be less than input_max';
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;

  v_value := p_value;
  IF p_clip THEN
    IF v_value < p_input_min THEN
      v_value := p_input_min;
    ELSIF v_value > p_input_max THEN
      v_value := p_input_max;
    END IF;
  ELSE
    IF v_value < p_input_min OR v_value > p_input_max THEN
      RAISE EXCEPTION 'value out of range';
    END IF;
  END IF;

  v_span := p_input_max - p_input_min;
  v_out_span := p_output_max - p_output_min;
  RETURN p_output_min + ((v_value - p_input_min)::double precision / v_span::double precision) * v_out_span;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_categorical(
  p_value TEXT,
  p_vocabulary TEXT[],
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0
) RETURNS DOUBLE PRECISION AS
$$
DECLARE
  v_index INTEGER := -1;
  v_length INTEGER;
  v_token TEXT;
  v_seen TEXT[] := ARRAY[]::TEXT[];
  i INTEGER;
BEGIN
  IF p_value IS NULL THEN
    RAISE EXCEPTION 'value must be a non-null token';
  END IF;
  IF p_vocabulary IS NULL THEN
    RAISE EXCEPTION 'vocabulary must be provided';
  END IF;
  IF array_length(p_vocabulary, 1) IS NULL THEN
    RAISE EXCEPTION 'vocabulary must not be empty';
  END IF;
  IF p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION 'output range endpoints must be finite';
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;

  v_length := array_length(p_vocabulary, 1);
  FOR i IN 1 .. v_length LOOP
    v_token := p_vocabulary[i];
    IF v_token IS NULL THEN
      RAISE EXCEPTION 'vocabulary tokens must be non-null text';
    END IF;
    IF v_token = ANY(v_seen) THEN
      RAISE EXCEPTION 'duplicate vocabulary token %', v_token;
    END IF;
    v_seen := array_append(v_seen, v_token);
    IF v_token = p_value THEN
      v_index := i - 1;
    END IF;
  END LOOP;

  IF v_index < 0 THEN
    RAISE EXCEPTION 'unknown categorical token %', p_value;
  END IF;

  IF v_length = 1 THEN
    RETURN (p_output_min + p_output_max) / 2.0;
  END IF;

  RETURN p_output_min + ((v_index::DOUBLE PRECISION) / ((v_length - 1)::DOUBLE PRECISION)) * (p_output_max - p_output_min);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_float(
  p_value DOUBLE PRECISION,
  p_input_min DOUBLE PRECISION,
  p_input_max DOUBLE PRECISION,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_clip BOOLEAN DEFAULT FALSE
) RETURNS DOUBLE PRECISION AS
$$
DECLARE
  v_value DOUBLE PRECISION;
  v_span DOUBLE PRECISION;
  v_out_span DOUBLE PRECISION;
BEGIN
  IF p_value <> p_value OR p_input_min <> p_input_min OR p_input_max <> p_input_max OR p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION 'value and range endpoints must be finite';
  END IF;

  IF p_input_min >= p_input_max THEN
    RAISE EXCEPTION 'input_min must be less than input_max';
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;

  v_value := p_value;
  IF p_clip THEN
    IF v_value < p_input_min THEN
      v_value := p_input_min;
    ELSIF v_value > p_input_max THEN
      v_value := p_input_max;
    END IF;
  ELSE
    IF v_value < p_input_min OR v_value > p_input_max THEN
      RAISE EXCEPTION 'value out of range';
    END IF;
  END IF;

  v_span := p_input_max - p_input_min;
  v_out_span := p_output_max - p_output_min;
  RETURN p_output_min + ((v_value - p_input_min) / v_span) * v_out_span;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_boolean(
  p_value BOOLEAN,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_false_value DOUBLE PRECISION DEFAULT NULL,
  p_true_value DOUBLE PRECISION DEFAULT NULL
) RETURNS DOUBLE PRECISION AS
$$
DECLARE
  v_false_value DOUBLE PRECISION;
  v_true_value DOUBLE PRECISION;
BEGIN
  IF p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION 'output range endpoints must be finite';
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;

  v_false_value := COALESCE(p_false_value, p_output_min);
  v_true_value := COALESCE(p_true_value, p_output_max);

  IF v_false_value <> v_false_value OR v_true_value <> v_true_value THEN
    RAISE EXCEPTION 'false_value and true_value must be finite';
  END IF;

  IF v_false_value < p_output_min OR v_false_value > p_output_max OR v_true_value < p_output_min OR v_true_value > p_output_max THEN
    RAISE EXCEPTION 'false_value/true_value must be within output range';
  END IF;

  IF v_false_value = v_true_value THEN
    RAISE EXCEPTION 'false_value and true_value must differ';
  END IF;

  IF p_value THEN
    RETURN v_true_value;
  END IF;
  RETURN v_false_value;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_text(
  p_value TEXT,
  p_mode TEXT DEFAULT ''codepoint'',
  p_alphabet TEXT DEFAULT NULL,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0
) RETURNS DOUBLE PRECISION[] AS
$$
DECLARE
  v_mode TEXT := lower(coalesce(p_mode, ''codepoint''));
  v_length INTEGER;
  v_index INTEGER;
  v_char TEXT;
  v_output DOUBLE PRECISION[] := ARRAY[]::DOUBLE PRECISION[];
BEGIN
  IF p_value IS NULL THEN
    RAISE EXCEPTION ''value must be a non-null string'';
  END IF;
  IF p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION ''output range endpoints must be finite'';
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION ''output_min must be less than output_max'';
  END IF;

  v_length := char_length(p_value);
  IF v_length = 0 THEN
    RAISE EXCEPTION ''empty text input is invalid by default'';
  END IF;

  IF v_mode = ''alphabet'' THEN
    IF p_alphabet IS NULL OR char_length(p_alphabet) = 0 THEN
      RAISE EXCEPTION ''alphabet must not be empty'';
    END IF;
    FOR v_index IN 1 .. char_length(p_alphabet) LOOP
      v_char := substr(p_alphabet, v_index, 1);
      IF position(v_char in substr(p_alphabet, v_index + 1)) > 0 THEN
        RAISE EXCEPTION ''alphabet must be unique'';
      END IF;
    END LOOP;
  ELSIF v_mode NOT IN (''codepoint'', ''byte'') THEN
    RAISE EXCEPTION ''unknown text mode'';
  END IF;

  FOR v_index IN 1 .. v_length LOOP
    v_char := substr(p_value, v_index, 1);
    IF v_mode = ''alphabet'' THEN
      v_index := position(v_char in p_alphabet);
      IF v_index = 0 THEN
        RAISE EXCEPTION ''unknown text token %'', v_char;
      END IF;
      IF char_length(p_alphabet) = 1 THEN
        v_output := array_append(v_output, (p_output_min + p_output_max) / 2.0);
      ELSE
        v_output := array_append(
          v_output,
          p_output_min + (((v_index - 1)::DOUBLE PRECISION) / ((char_length(p_alphabet) - 1)::DOUBLE PRECISION)) * (p_output_max - p_output_min)
        );
      END IF;
    ELSE
      v_output := array_append(
        v_output,
        p_output_min + ((get_byte(convert_to(v_char, ''UTF8''), 0)::DOUBLE PRECISION / 255.0) * (p_output_max - p_output_min))
      );
    END IF;
  END LOOP;

  RETURN v_output;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_temporal(
  p_value TIMESTAMP WITH TIME ZONE,
  p_input_min DOUBLE PRECISION,
  p_input_max DOUBLE PRECISION,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_clip BOOLEAN DEFAULT FALSE
) RETURNS DOUBLE PRECISION AS
$$
DECLARE
  v_value DOUBLE PRECISION;
  v_span DOUBLE PRECISION;
  v_out_span DOUBLE PRECISION;
BEGIN
  IF p_input_min <> p_input_min OR p_input_max <> p_input_max OR p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION 'range endpoints must be finite';
  END IF;
  IF p_input_min >= p_input_max THEN
    RAISE EXCEPTION 'input_min must be less than input_max';
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;

  v_value := EXTRACT(EPOCH FROM p_value);
  IF v_value <> v_value THEN
    RAISE EXCEPTION 'temporal value must resolve to a finite epoch';
  END IF;

  IF p_clip THEN
    IF v_value < p_input_min THEN
      v_value := p_input_min;
    ELSIF v_value > p_input_max THEN
      v_value := p_input_max;
    END IF;
  ELSE
    IF v_value < p_input_min OR v_value > p_input_max THEN
      RAISE EXCEPTION 'value out of range';
    END IF;
  END IF;

  v_span := p_input_max - p_input_min;
  v_out_span := p_output_max - p_output_min;
  RETURN p_output_min + ((v_value - p_input_min) / v_span) * v_out_span;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_bytes(
  p_value BYTEA,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_clip BOOLEAN DEFAULT FALSE
) RETURNS DOUBLE PRECISION[] AS
$$
DECLARE
  v_length INTEGER;
  v_index INTEGER;
  v_byte INTEGER;
  v_result DOUBLE PRECISION[] := ARRAY[]::DOUBLE PRECISION[];
BEGIN
  IF p_value IS NULL THEN
    RAISE EXCEPTION 'value must be a bytea payload';
  END IF;
  IF p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION 'output range endpoints must be finite';
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;

  v_length := octet_length(p_value);
  IF v_length = 0 THEN
    RAISE EXCEPTION 'empty bytes input is invalid by default';
  END IF;

  FOR v_index IN 0 .. v_length - 1 LOOP
    v_byte := get_byte(p_value, v_index);
    v_result := array_append(v_result, p_output_min + ((v_byte::DOUBLE PRECISION / 255.0) * (p_output_max - p_output_min)));
  END LOOP;

  RETURN v_result;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_sequence(
  p_values DOUBLE PRECISION[],
  p_input_min DOUBLE PRECISION,
  p_input_max DOUBLE PRECISION,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_clip BOOLEAN DEFAULT FALSE
) RETURNS DOUBLE PRECISION[] AS
$$
DECLARE
  v_length INTEGER;
  v_index INTEGER;
  v_value DOUBLE PRECISION;
  v_result DOUBLE PRECISION[] := ARRAY[]::DOUBLE PRECISION[];
BEGIN
  IF p_values IS NULL THEN
    RAISE EXCEPTION 'value must be a numeric array';
  END IF;
  IF p_input_min <> p_input_min OR p_input_max <> p_input_max OR p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION 'range endpoints must be finite';
  END IF;
  IF p_input_min >= p_input_max THEN
    RAISE EXCEPTION 'input_min must be less than input_max';
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;

  v_length := array_length(p_values, 1);
  IF v_length IS NULL OR v_length = 0 THEN
    RAISE EXCEPTION 'empty sequence input is invalid by default';
  END IF;

  FOR v_index IN 1 .. v_length LOOP
    v_value := p_values[v_index];
    IF v_value <> v_value THEN
      RAISE EXCEPTION 'sequence elements must be finite';
    END IF;
    IF p_clip THEN
      IF v_value < p_input_min THEN
        v_value := p_input_min;
      ELSIF v_value > p_input_max THEN
        v_value := p_input_max;
      END IF;
    ELSIF v_value < p_input_min OR v_value > p_input_max THEN
      RAISE EXCEPTION 'value out of range';
    END IF;
    v_result := array_append(
      v_result,
      p_output_min + ((v_value - p_input_min) / (p_input_max - p_input_min)) * (p_output_max - p_output_min)
    );
  END LOOP;

  RETURN v_result;
END;
$$ 
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_image_scalar(
  p_value DOUBLE PRECISION,
  p_input_min DOUBLE PRECISION,
  p_input_max DOUBLE PRECISION,
  p_output_min DOUBLE PRECISION,
  p_output_max DOUBLE PRECISION,
  p_clip BOOLEAN
) RETURNS DOUBLE PRECISION AS
$$
DECLARE
  v_value DOUBLE PRECISION := p_value;
BEGIN
  IF p_value <> p_value THEN
    RAISE EXCEPTION 'image values must be finite';
  END IF;
  IF p_input_min >= p_input_max THEN
    RAISE EXCEPTION 'image input_min must be less than input_max';
  END IF;

  IF v_value < p_input_min THEN
    IF p_clip THEN
      v_value := p_input_min;
    ELSE
      RAISE EXCEPTION 'image value out of range';
    END IF;
  ELSIF v_value > p_input_max THEN
    IF p_clip THEN
      v_value := p_input_max;
    ELSE
      RAISE EXCEPTION 'image value out of range';
    END IF;
  END IF;

  RETURN p_output_min + ((v_value - p_input_min) / (p_input_max - p_input_min)) * (p_output_max - p_output_min);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_image_value(
  p_value JSONB,
  p_mode TEXT DEFAULT 'grayscale',
  p_input_min DOUBLE PRECISION DEFAULT 0.0,
  p_input_max DOUBLE PRECISION DEFAULT 255.0,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_allow_empty BOOLEAN DEFAULT FALSE,
  p_clip BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS
$$
DECLARE
  v_mode TEXT := lower(coalesce(p_mode, 'grayscale'));
  v_array_length INTEGER;
  v_index INTEGER;
  v_text TEXT;
  v_bytea BYTEA;
  v_byte_index INTEGER;
  v_byte_values DOUBLE PRECISION[] := ARRAY[]::DOUBLE PRECISION[];
  v_item JSONB;
  v_nested JSONB;
  v_has_scalar BOOLEAN := FALSE;
  v_has_nested BOOLEAN := FALSE;
  v_result JSONB := '[]'::JSONB;
BEGIN
  IF p_output_min <> p_output_min OR p_output_max <> p_output_max OR p_input_min <> p_input_min OR p_input_max <> p_input_max THEN
    RAISE EXCEPTION 'image boundaries must be finite';
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'image output_min must be less than output_max';
  END IF;
  IF p_input_min >= p_input_max THEN
    RAISE EXCEPTION 'image input_min must be less than input_max';
  END IF;

  IF v_mode NOT IN ('grayscale', 'rgb', 'rgba', 'raw_bytes') THEN
    RAISE EXCEPTION 'unknown image mode';
  END IF;

  IF p_value IS NULL THEN
    RAISE EXCEPTION 'image value must not be null';
  END IF;

  IF v_mode = 'raw_bytes' THEN
    IF jsonb_typeof(p_value) <> 'string' THEN
      RAISE EXCEPTION 'raw_bytes mode requires string input';
    END IF;
    v_text := p_value #>> '{}';
    IF substring(v_text, 1, 2) = '\\x' THEN
      IF char_length(v_text) % 2 = 1 THEN
        RAISE EXCEPTION 'raw byte string must have even length after hex prefix';
      END IF;
      BEGIN
        v_bytea := decode(substring(v_text, 3), 'hex');
      EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'invalid raw byte string';
      END;
    ELSE
      v_bytea := convert_to(v_text, 'UTF8');
    END IF;

    IF octet_length(v_bytea) = 0 AND NOT p_allow_empty THEN
      RAISE EXCEPTION 'empty image input is invalid by default; set allow_empty=true to map empty inputs.';
    END IF;

    v_byte_values := libRangeMap_map_bytes(v_bytea, p_output_min, p_output_max, p_clip);
    RETURN to_jsonb(v_byte_values);
  END IF;

  IF jsonb_typeof(p_value) <> 'array' THEN
    RAISE EXCEPTION 'image value must be array or raw byte string in non-raw mode';
  END IF;

  v_array_length := jsonb_array_length(p_value);
  IF v_array_length IS NULL THEN
    RAISE EXCEPTION 'image input must be an array';
  END IF;
  IF v_array_length = 0 AND NOT p_allow_empty THEN
    RAISE EXCEPTION 'empty image input is invalid by default; set allow_empty=true to map empty inputs.';
  END IF;

  FOR v_index IN 0 .. v_array_length - 1 LOOP
    v_item := p_value -> v_index;
    IF jsonb_typeof(v_item) = 'array' THEN
      v_has_nested := TRUE;
    ELSIF jsonb_typeof(v_item) = 'number' THEN
      v_has_scalar := TRUE;
    ELSE
      RAISE EXCEPTION 'image values must be numeric pixels or nested arrays';
    END IF;
  END LOOP;

  IF v_has_scalar AND v_has_nested THEN
    RAISE EXCEPTION 'image arrays cannot mix scalar pixels and nested arrays';
  END IF;

  IF v_has_scalar THEN
    IF v_mode = 'rgb' AND v_array_length <> 3 THEN
      RAISE EXCEPTION 'rgb mode requires channel vectors of length 3';
    END IF;
    IF v_mode = 'rgba' AND v_array_length <> 4 THEN
      RAISE EXCEPTION 'rgba mode requires channel vectors of length 4';
    END IF;
    FOR v_index IN 0 .. v_array_length - 1 LOOP
      v_item := p_value -> v_index;
      v_result := v_result || jsonb_build_array(
        libRangeMap_map_image_scalar(
          (v_item #>> '{}')::DOUBLE PRECISION,
          p_input_min,
          p_input_max,
          p_output_min,
          p_output_max,
          p_clip
        )
      );
    END LOOP;
  ELSE
    FOR v_index IN 0 .. v_array_length - 1 LOOP
      v_nested := p_value -> v_index;
      v_result := v_result || jsonb_build_array(
        libRangeMap_map_image_value(
          v_nested,
          v_mode,
          p_input_min,
          p_input_max,
          p_output_min,
          p_output_max,
          p_allow_empty,
          p_clip
        )
      );
    END LOOP;
  END IF;

  RETURN v_result;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_object_value(
  p_value JSONB,
  p_spec JSONB,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_clip BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS
$$
DECLARE
  v_mapper_type TEXT;
  v_clip BOOLEAN;
  v_output_min DOUBLE PRECISION;
  v_output_max DOUBLE PRECISION;
  v_value BOOLEAN;
  v_text TEXT;
  v_bytea BYTEA;
  v_num DOUBLE PRECISION;
  v_int BIGINT;
  v_input_min BIGINT;
  v_input_max BIGINT;
  v_in_min DOUBLE PRECISION;
  v_in_max DOUBLE PRECISION;
  v_image_mode TEXT;
  v_image_allow_empty BOOLEAN;
  v_false_value DOUBLE PRECISION;
  v_true_value DOUBLE PRECISION;
  v_alphabet TEXT;
  v_vocabulary JSONB;
  v_tokens TEXT[] := ARRAY[]::TEXT[];
  v_token TEXT;
  v_ts_text TEXT;
  v_ts TIMESTAMP WITH TIME ZONE;
  v_index INTEGER;
  v_size INTEGER;
  v_element INTEGER;
  v_element_spec JSONB;
  v_element_value JSONB;
  v_nested_schema JSONB;
  v_result JSONB;
  v_sequence JSONB := '[]'::JSONB;
BEGIN
  IF p_value IS NULL THEN
    RAISE EXCEPTION 'value must be provided for mapped object field';
  END IF;

  IF p_spec IS NULL OR jsonb_typeof(p_spec) <> 'object' THEN
    RAISE EXCEPTION 'spec must be a non-null object';
  END IF;

  v_mapper_type := lower(coalesce(p_spec->>'mapper_type', p_spec->>'family'));
  IF v_mapper_type IS NULL OR length(trim(v_mapper_type)) = 0 THEN
    RAISE EXCEPTION 'spec must include mapper_type or family';
  END IF;

  IF p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION 'output range endpoints must be finite';
  END IF;

  IF p_spec ? 'output_min' THEN
    IF jsonb_typeof(p_spec->'output_min') <> 'number' THEN
      RAISE EXCEPTION 'spec.output_min must be a number';
    END IF;
    v_output_min := (p_spec->>'output_min')::DOUBLE PRECISION;
  ELSE
    v_output_min := p_output_min;
  END IF;

  IF p_spec ? 'output_max' THEN
    IF jsonb_typeof(p_spec->'output_max') <> 'number' THEN
      RAISE EXCEPTION 'spec.output_max must be a number';
    END IF;
    v_output_max := (p_spec->>'output_max')::DOUBLE PRECISION;
  ELSE
    v_output_max := p_output_max;
  END IF;

  IF v_output_min >= v_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;

  IF p_spec ? 'clip' THEN
    IF jsonb_typeof(p_spec->'clip') <> 'boolean' THEN
      RAISE EXCEPTION 'spec.clip must be a boolean';
    END IF;
    v_clip := (p_spec->>'clip')::BOOLEAN;
  ELSE
    v_clip := p_clip;
  END IF;

  IF v_mapper_type = 'integer' THEN
    IF p_value IS NULL OR jsonb_typeof(p_value) <> 'number' THEN
      RAISE EXCEPTION 'integer mapper requires numeric value';
    END IF;
    IF NOT p_spec ? 'input_min' OR NOT p_spec ? 'input_max' THEN
      RAISE EXCEPTION 'integer mapper requires input_min and input_max';
    END IF;
    IF jsonb_typeof(p_spec->'input_min') <> 'number' OR jsonb_typeof(p_spec->'input_max') <> 'number' THEN
      RAISE EXCEPTION 'integer mapper requires numeric input_min and input_max';
    END IF;
    v_input_min := (p_spec->>'input_min')::BIGINT;
    v_input_max := (p_spec->>'input_max')::BIGINT;
    v_num := (p_value #>> '{}')::DOUBLE PRECISION;
    IF v_num <> trunc(v_num) THEN
      RAISE EXCEPTION 'integer mapper requires a whole numeric value';
    END IF;
    v_int := v_num::BIGINT;
    RETURN to_jsonb(libRangeMap_map_integer(v_int, v_input_min, v_input_max, v_output_min, v_output_max, v_clip));
  ELSIF v_mapper_type = 'float' THEN
    IF p_value IS NULL OR jsonb_typeof(p_value) <> 'number' THEN
      RAISE EXCEPTION 'float mapper requires numeric value';
    END IF;
    IF NOT p_spec ? 'input_min' OR NOT p_spec ? 'input_max' THEN
      RAISE EXCEPTION 'float mapper requires input_min and input_max';
    END IF;
    IF jsonb_typeof(p_spec->'input_min') <> 'number' OR jsonb_typeof(p_spec->'input_max') <> 'number' THEN
      RAISE EXCEPTION 'float mapper requires numeric input_min and input_max';
    END IF;
    v_in_min := (p_spec->>'input_min')::DOUBLE PRECISION;
    v_in_max := (p_spec->>'input_max')::DOUBLE PRECISION;
    v_num := (p_value #>> '{}')::DOUBLE PRECISION;
    RETURN to_jsonb(libRangeMap_map_float(v_num, v_in_min, v_in_max, v_output_min, v_output_max, v_clip));
  ELSIF v_mapper_type = 'boolean' THEN
    IF p_value IS NULL OR jsonb_typeof(p_value) <> 'boolean' THEN
      RAISE EXCEPTION 'boolean mapper requires boolean value';
    END IF;
    v_value := (p_value #>> '{}')::BOOLEAN;
    IF p_spec ? 'false_value' THEN
      IF jsonb_typeof(p_spec->'false_value') <> 'number' THEN
        RAISE EXCEPTION 'false_value must be a number';
      END IF;
      v_false_value := (p_spec->>'false_value')::DOUBLE PRECISION;
    ELSE
      v_false_value := NULL;
    END IF;
    IF p_spec ? 'true_value' THEN
      IF jsonb_typeof(p_spec->'true_value') <> 'number' THEN
        RAISE EXCEPTION 'true_value must be a number';
      END IF;
      v_true_value := (p_spec->>'true_value')::DOUBLE PRECISION;
    ELSE
      v_true_value := NULL;
    END IF;
    RETURN to_jsonb(libRangeMap_map_boolean(v_value, v_output_min, v_output_max, v_false_value, v_true_value));
  ELSIF v_mapper_type = 'text' OR v_mapper_type = 'string' THEN
    IF p_value IS NULL OR jsonb_typeof(p_value) <> 'string' THEN
      RAISE EXCEPTION 'text mapper requires string value';
    END IF;
    v_text := p_value #>> '{}';
    IF p_spec ? 'mode' THEN
      IF jsonb_typeof(p_spec->'mode') <> 'string' THEN
        RAISE EXCEPTION 'text mode must be a string';
      END IF;
      IF lower(p_spec->>'mode') NOT IN ('codepoint', 'byte', 'alphabet') THEN
        RAISE EXCEPTION 'unknown text mode';
      END IF;
      v_result := to_jsonb(libRangeMap_map_text(v_text, lower(p_spec->>'mode'), CASE WHEN p_spec ? 'alphabet' THEN p_spec->>'alphabet' ELSE NULL END, v_output_min, v_output_max));
    ELSE
      v_result := to_jsonb(libRangeMap_map_text(v_text, 'codepoint', NULL, v_output_min, v_output_max));
    END IF;
    RETURN v_result;
  ELSIF v_mapper_type = 'categorical' OR v_mapper_type = 'vocabulary' THEN
    IF p_value IS NULL OR jsonb_typeof(p_value) <> 'string' THEN
      RAISE EXCEPTION 'categorical mapper requires string token';
    END IF;
    IF NOT p_spec ? 'vocabulary' THEN
      RAISE EXCEPTION 'categorical mapper requires vocabulary';
    END IF;
    v_vocabulary := p_spec->'vocabulary';
    IF jsonb_typeof(v_vocabulary) <> 'array' OR jsonb_array_length(v_vocabulary) IS NULL THEN
      RAISE EXCEPTION 'vocabulary must be a list';
    END IF;
    v_size := jsonb_array_length(v_vocabulary);
    IF v_size = 0 THEN
      RAISE EXCEPTION 'vocabulary must not be empty';
    END IF;
    FOR v_index IN 0 .. v_size - 1 LOOP
      IF jsonb_typeof(v_vocabulary -> v_index) <> 'string' THEN
        RAISE EXCEPTION 'vocabulary tokens must be strings';
      END IF;
      v_token := v_vocabulary #>> ARRAY[v_index::TEXT];
      v_tokens := array_append(v_tokens, v_token);
    END LOOP;
    v_text := p_value #>> '{}';
    RETURN to_jsonb(libRangeMap_map_categorical(v_text, v_tokens, v_output_min, v_output_max));
  ELSIF v_mapper_type = 'image' OR v_mapper_type = 'image_like' OR v_mapper_type = 'image_range' THEN
    IF p_value IS NULL THEN
      RAISE EXCEPTION 'image mapper requires array or raw byte input';
    END IF;
    IF p_spec ? 'mode' THEN
      IF jsonb_typeof(p_spec->'mode') <> 'string' THEN
        RAISE EXCEPTION 'image mode must be a string';
      END IF;
      v_image_mode := lower(p_spec->>'mode');
      IF v_image_mode NOT IN ('grayscale', 'rgb', 'rgba', 'raw_bytes') THEN
        RAISE EXCEPTION 'unknown image mode';
      END IF;
    ELSE
      v_image_mode := 'grayscale';
    END IF;
    IF p_spec ? 'allow_empty' THEN
      IF jsonb_typeof(p_spec->'allow_empty') <> 'boolean' THEN
        RAISE EXCEPTION 'image allow_empty must be a boolean';
      END IF;
      v_image_allow_empty := (p_spec->>'allow_empty')::BOOLEAN;
    ELSE
      v_image_allow_empty := FALSE;
    END IF;
    IF p_spec ? 'input_min' THEN
      IF jsonb_typeof(p_spec->'input_min') <> 'number' THEN
        RAISE EXCEPTION 'image input_min must be a number';
      END IF;
      v_in_min := (p_spec->>'input_min')::DOUBLE PRECISION;
    ELSE
      v_in_min := 0.0;
    END IF;
    IF p_spec ? 'input_max' THEN
      IF jsonb_typeof(p_spec->'input_max') <> 'number' THEN
        RAISE EXCEPTION 'image input_max must be a number';
      END IF;
      v_in_max := (p_spec->>'input_max')::DOUBLE PRECISION;
    ELSE
      v_in_max := 255.0;
    END IF;
    RETURN libRangeMap_map_image_value(p_value, v_image_mode, v_in_min, v_in_max, v_output_min, v_output_max, v_image_allow_empty, v_clip);
  ELSIF v_mapper_type = 'temporal' THEN
    IF p_value IS NULL OR jsonb_typeof(p_value) <> 'string' THEN
      RAISE EXCEPTION 'temporal mapper requires ISO-8601 timestamp string';
    END IF;
    v_ts_text := p_value #>> '{}';
    IF v_ts_text IS NULL OR length(v_ts_text) = 0 THEN
      RAISE EXCEPTION 'temporal mapper requires non-empty timestamp';
    END IF;
    BEGIN
      v_ts := v_ts_text::TIMESTAMP WITH TIME ZONE;
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'temporal mapper requires ISO-8601 timestamp string';
    END;
    IF NOT p_spec ? 'input_min' OR NOT p_spec ? 'input_max' THEN
      RAISE EXCEPTION 'temporal mapper requires input_min and input_max';
    END IF;
    IF jsonb_typeof(p_spec->'input_min') <> 'number' OR jsonb_typeof(p_spec->'input_max') <> 'number' THEN
      RAISE EXCEPTION 'temporal mapper requires numeric input_min and input_max';
    END IF;
    v_in_min := (p_spec->>'input_min')::DOUBLE PRECISION;
    v_in_max := (p_spec->>'input_max')::DOUBLE PRECISION;
    RETURN to_jsonb(libRangeMap_map_temporal(v_ts, v_in_min, v_in_max, v_output_min, v_output_max, v_clip));
  ELSIF v_mapper_type = 'bytes' THEN
    IF p_value IS NULL OR jsonb_typeof(p_value) <> 'string' THEN
      RAISE EXCEPTION 'bytes mapper requires string value';
    END IF;
    v_text := p_value #>> '{}';
    IF v_text LIKE '\\x%' THEN
      IF char_length(v_text) % 2 = 1 THEN
        RAISE EXCEPTION 'hex bytes value must have even length';
      END IF;
      BEGIN
        v_bytea := decode(substring(v_text, 3), 'hex');
      EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'invalid hex bytes string';
      END;
    ELSE
      v_bytea := convert_to(v_text, 'UTF8');
    END IF;
    v_num := (v_output_min = v_output_min)::DOUBLE PRECISION;
    v_size := octet_length(v_bytea);
    RETURN to_jsonb(libRangeMap_map_bytes(v_bytea, v_output_min, v_output_max, v_clip));
  ELSIF v_mapper_type = 'sequence' THEN
    IF p_value IS NULL OR jsonb_typeof(p_value) <> 'array' THEN
      RAISE EXCEPTION 'sequence mapper requires array';
    END IF;
    IF NOT p_spec ? 'element_mapper' THEN
      RAISE EXCEPTION 'sequence mapper requires element_mapper';
    END IF;
    v_element_spec := p_spec->'element_mapper';
    IF jsonb_typeof(v_element_spec) <> 'object' THEN
      RAISE EXCEPTION 'element_mapper must be an object';
    END IF;
    v_size := jsonb_array_length(p_value);
    IF v_size = 0 THEN
      IF p_spec ? 'allow_empty' THEN
        IF jsonb_typeof(p_spec->'allow_empty') <> 'boolean' THEN
          RAISE EXCEPTION 'allow_empty must be a boolean';
        END IF;
        IF NOT (p_spec->>'allow_empty')::BOOLEAN THEN
          RAISE EXCEPTION 'empty sequence input is invalid by default';
        END IF;
      ELSE
        RAISE EXCEPTION 'empty sequence input is invalid by default';
      END IF;
    END IF;
    FOR v_index IN 0 .. v_size - 1 LOOP
      v_element_value := p_value -> v_index;
      v_result := libRangeMap_map_object_value(v_element_value, v_element_spec, v_output_min, v_output_max, v_clip);
      v_sequence := v_sequence || jsonb_build_array(v_result);
    END LOOP;
    RETURN v_sequence;
  ELSIF v_mapper_type = 'object' OR v_mapper_type = 'map' THEN
    IF jsonb_typeof(p_value) <> 'object' THEN
      RAISE EXCEPTION 'object mapper requires object value';
    END IF;
    IF NOT p_spec ? 'schema' THEN
      RAISE EXCEPTION 'object mapper requires schema';
    END IF;
    v_nested_schema := p_spec->'schema';
    IF jsonb_typeof(v_nested_schema) <> 'object' THEN
      RAISE EXCEPTION 'schema must be an object';
    END IF;
    v_result := libRangeMap_map_object(
      p_value,
      v_nested_schema,
      CASE WHEN p_spec ? 'allow_unknown' AND jsonb_typeof(p_spec->'allow_unknown') = 'boolean' THEN (p_spec->>'allow_unknown')::BOOLEAN ELSE FALSE END,
      CASE WHEN p_spec ? 'allow_empty' AND jsonb_typeof(p_spec->'allow_empty') = 'boolean' THEN (p_spec->>'allow_empty')::BOOLEAN ELSE FALSE END,
      CASE WHEN p_spec ? 'has_missing_value' AND jsonb_typeof(p_spec->'has_missing_value') = 'boolean' THEN (p_spec->>'has_missing_value')::BOOLEAN ELSE FALSE END,
      CASE WHEN p_spec ? 'missing_value' THEN
        CASE WHEN (p_spec->'missing_value') IS NULL THEN NULL ELSE (p_spec->>'missing_value')::DOUBLE PRECISION END
      ELSE NULL END,
      v_output_min,
      v_output_max,
      v_clip
    );
    RETURN v_result;
  ELSE
    RAISE EXCEPTION 'unknown mapper_type %', v_mapper_type;
  END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION libRangeMap_map_object(
  p_value JSONB,
  p_schema JSONB,
  p_allow_unknown BOOLEAN DEFAULT FALSE,
  p_allow_empty BOOLEAN DEFAULT FALSE,
  p_has_missing_value BOOLEAN DEFAULT FALSE,
  p_missing_value DOUBLE PRECISION DEFAULT NULL,
  p_output_min DOUBLE PRECISION DEFAULT -1.0,
  p_output_max DOUBLE PRECISION DEFAULT 1.0,
  p_clip BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS
$$
DECLARE
  v_schema_fields TEXT[];
  v_value_fields TEXT[];
  v_unknown_fields TEXT[] := ARRAY[]::TEXT[];
  v_missing_fields TEXT[] := ARRAY[]::TEXT[];
  v_field TEXT;
  v_spec JSONB;
  v_field_value JSONB;
  v_field_output JSONB;
  v_output JSONB := '{}'::JSONB;
  v_missing_value DOUBLE PRECISION;
  v_has_missing_value BOOLEAN;
  v_source_count INTEGER;
  v_schema_count INTEGER;
  i INTEGER;
BEGIN
  IF p_value IS NULL THEN
    RAISE EXCEPTION 'value must be a non-null object';
  END IF;
  IF p_schema IS NULL OR jsonb_typeof(p_schema) <> 'object' THEN
    RAISE EXCEPTION 'schema must be a non-null object';
  END IF;
  IF p_output_min <> p_output_min OR p_output_max <> p_output_max THEN
    RAISE EXCEPTION 'output range endpoints must be finite';
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE EXCEPTION 'output_min must be less than output_max';
  END IF;
  IF jsonb_object_length(p_schema) IS NULL OR jsonb_object_length(p_schema) = 0 THEN
    IF NOT p_allow_empty THEN
      RAISE EXCEPTION 'schema must include at least one mapped field';
    END IF;
  END IF;

  SELECT array_agg(key ORDER BY key) INTO v_schema_fields
  FROM jsonb_object_keys(p_schema) AS key;

  SELECT array_agg(key ORDER BY key) INTO v_value_fields
  FROM jsonb_object_keys(p_value) AS key;

  v_schema_count := COALESCE(array_length(v_schema_fields, 1), 0);
  v_source_count := COALESCE(array_length(v_value_fields, 1), 0);

  IF v_source_count = 0 AND NOT p_allow_empty THEN
    RAISE EXCEPTION 'object payload must not be empty unless allow_empty is true';
  END IF;

  FOR i IN 1 .. v_schema_count LOOP
    v_field := v_schema_fields[i];
    IF NOT (p_value ? v_field) THEN
      v_missing_fields := array_append(v_missing_fields, v_field);
    END IF;
  END LOOP;

  FOR i IN 1 .. v_source_count LOOP
    v_field := v_value_fields[i];
    IF NOT (v_field = ANY(v_schema_fields)) THEN
      v_unknown_fields := array_append(v_unknown_fields, v_field);
    END IF;
  END LOOP;

  IF array_length(v_missing_fields, 1) IS NOT NULL AND array_length(v_missing_fields, 1) > 0 AND NOT p_has_missing_value THEN
    RAISE EXCEPTION 'missing required field(s): %', array_to_string(v_missing_fields, ', ');
  END IF;

  IF array_length(v_unknown_fields, 1) IS NOT NULL AND array_length(v_unknown_fields, 1) > 0 AND NOT p_allow_unknown THEN
    RAISE EXCEPTION 'unknown field(s): %', array_to_string(v_unknown_fields, ', ');
  END IF;

  v_missing_value := p_missing_value;
  v_has_missing_value := p_has_missing_value;
  IF v_has_missing_value THEN
    IF v_missing_value IS NULL THEN
      RAISE EXCEPTION 'missing_value must be a finite number';
    END IF;
    IF v_missing_value <> v_missing_value OR v_missing_value < p_output_min OR v_missing_value > p_output_max THEN
      RAISE EXCEPTION 'missing_value must be finite and within output range';
    END IF;
  END IF;

  FOR i IN 1 .. v_schema_count LOOP
    v_field := v_schema_fields[i];
    v_spec := p_schema -> v_field;
    IF v_spec IS NULL THEN
      RAISE EXCEPTION 'schema entry for field % is missing', v_field;
    END IF;
    IF p_value ? v_field THEN
      v_field_value := p_value -> v_field;
      v_field_output := libRangeMap_map_object_value(v_field_value, v_spec, p_output_min, p_output_max, p_clip);
      v_output := v_output || jsonb_build_object(v_field, v_field_output);
    ELSIF v_has_missing_value THEN
      v_output := v_output || jsonb_build_object(v_field, to_jsonb(v_missing_value));
    ELSE
      RAISE EXCEPTION 'missing required field: %', v_field;
    END IF;
  END LOOP;

  IF p_allow_unknown THEN
    FOR i IN 1 .. v_source_count LOOP
      v_field := v_value_fields[i];
      IF NOT (v_field = ANY(v_schema_fields)) THEN
        v_output := v_output || jsonb_build_object(v_field, p_value -> v_field);
      END IF;
    END LOOP;
  END IF;

  RETURN v_output;
END;
$$
LANGUAGE plpgsql;

DO $$
DECLARE
  v_object_output JSONB;
  v_missing_output JSONB;
  v_image_output JSONB;
BEGIN
  IF abs(libRangeMap_map_integer(50, 0, 100, -1.0, 1.0, FALSE)) > 1e-12 THEN
    RAISE EXCEPTION 'integer self-check failed';
  END IF;
  IF abs(libRangeMap_map_float(0.5, 0.0, 1.0, -1.0, 1.0, FALSE)) > 1e-12 THEN
    RAISE EXCEPTION 'float self-check failed';
  END IF;
  IF abs(libRangeMap_map_boolean(TRUE, -1.0, 1.0, -1.0, 1.0)) > 1e-12 THEN
    RAISE EXCEPTION 'boolean self-check failed';
  END IF;
  IF abs(libRangeMap_map_temporal('1970-01-01 00:00:00+00'::timestamptz, -10.0, 10.0, -1.0, 1.0, FALSE)) > 1e-12 THEN
    RAISE EXCEPTION 'temporal self-check failed';
  END IF;
  IF libRangeMap_map_bytes(E'\\x00ff'::bytea, -1.0, 1.0, FALSE) <> ARRAY[-1.0, 1.0] THEN
    RAISE EXCEPTION 'bytes self-check failed';
  END IF;
  IF abs(libRangeMap_map_categorical('cat', ARRAY['cat','dog'], -1.0, 1.0) + 1.0) > 1e-12 THEN
    RAISE EXCEPTION 'categorical self-check failed';
  END IF;
  IF libRangeMap_map_sequence(ARRAY[0.0, 50.0, 100.0], 0.0, 100.0, -1.0, 1.0, FALSE) <> ARRAY[-1.0, 0.0, 1.0] THEN
    RAISE EXCEPTION 'sequence self-check failed';
  END IF;
  v_object_output := libRangeMap_map_object(
    '{"age": 34, "active": true, "label": "cat"}'::JSONB,
    '{"age":{"mapper_type":"integer","input_min":0,"input_max":100}, "active":{"mapper_type":"boolean"}, "label":{"mapper_type":"categorical","vocabulary":["cat","dog"]}}'::JSONB,
    FALSE,
    FALSE,
    FALSE,
    NULL,
    -1.0,
    1.0,
    FALSE
  );
  IF abs((v_object_output->>'age')::DOUBLE PRECISION + 0.32) > 1e-12 THEN
    RAISE EXCEPTION 'map/object self-check failed';
  END IF;
  IF (v_object_output->>'active')::DOUBLE PRECISION <> 1.0 THEN
    RAISE EXCEPTION 'map/object self-check failed';
  END IF;
  IF v_object_output->>'label' <> '-1.0' THEN
    RAISE EXCEPTION 'map/object self-check failed';
  END IF;
  v_image_output := libRangeMap_map_image_value('"\\x00ff"'::JSONB, 'raw_bytes', 0.0, 255.0, -1.0, 1.0, FALSE, FALSE);
  IF abs((v_image_output #>> '{0}')::DOUBLE PRECISION + 1.0) > 1e-12 OR abs((v_image_output #>> '{1}')::DOUBLE PRECISION - 1.0) > 1e-12 THEN
    RAISE EXCEPTION 'image raw-bytes self-check failed';
  END IF;
  v_image_output := libRangeMap_map_image_value('[[0,255],[255,0]]'::JSONB, 'grayscale', 0.0, 255.0, -1.0, 1.0, FALSE, FALSE);
  IF jsonb_array_length(v_image_output) <> 2 THEN
    RAISE EXCEPTION 'image nested self-check failed';
  END IF;
  IF jsonb_array_length(v_image_output -> 0) <> 2 OR jsonb_array_length(v_image_output -> 1) <> 2 THEN
    RAISE EXCEPTION 'image nested self-check failed';
  END IF;
  IF abs((v_image_output #>> '{0,0}')::DOUBLE PRECISION + 1.0) > 1e-12 OR abs((v_image_output #>> '{1,0}')::DOUBLE PRECISION - 1.0) > 1e-12 THEN
    RAISE EXCEPTION 'image nested self-check failed';
  END IF;
  v_image_output := libRangeMap_map_object(
    '{"frame":[[0,255],[255,0]]}'::JSONB,
    '{"frame":{"mapper_type":"image","mode":"grayscale","input_min":0.0,"input_max":255.0}}'::JSONB,
    FALSE,
    FALSE,
    FALSE,
    NULL,
    -1.0,
    1.0,
    FALSE
  );
  IF abs(((v_image_output -> 'frame' #>> '{0,0}')::DOUBLE PRECISION) + 1.0) > 1e-12 OR abs(((v_image_output -> 'frame' #>> '{1,0}')::DOUBLE PRECISION) - 1.0) > 1e-12 THEN
    RAISE EXCEPTION 'image map/object self-check failed';
  END IF;
  v_missing_output := libRangeMap_map_object(
      '{"active": true}'::JSONB,
      '{"age":{"mapper_type":"integer","input_min":0,"input_max":100}, "active":{"mapper_type":"boolean"}}'::JSONB,
      FALSE,
      FALSE,
      TRUE,
      -1.0,
      -1.0,
      1.0,
      FALSE
  );
  IF (v_missing_output->>'age')::DOUBLE PRECISION <> -1.0 THEN
    RAISE EXCEPTION 'map/object missing-field fallback failed';
  END IF;
  BEGIN
    PERFORM libRangeMap_map_object(
      '{"age":34, "active":true, "extra":false}'::JSONB,
      '{"age":{"mapper_type":"integer","input_min":0,"input_max":100}, "active":{"mapper_type":"boolean"}}'::JSONB
    );
    RAISE EXCEPTION 'map/object unknown-field hard-fail not raised';
  EXCEPTION WHEN others THEN
    IF SQLSTATE !~ '^22|^23|^42' THEN
      RAISE;
    END IF;
  END;
END;
$$ LANGUAGE plpgsql;

