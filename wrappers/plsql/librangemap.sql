CREATE OR REPLACE FUNCTION libRangeMap_map_integer(
  p_value IN NUMBER,
  p_input_min IN NUMBER,
  p_input_max IN NUMBER,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_clip IN BOOLEAN DEFAULT FALSE
) RETURN NUMBER
IS
  v_value NUMBER := p_value;
BEGIN
  IF p_input_min >= p_input_max THEN
    RAISE_APPLICATION_ERROR(-20001, 'input_min must be less than input_max');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  IF p_clip THEN
    IF v_value < p_input_min THEN
      v_value := p_input_min;
    ELSIF v_value > p_input_max THEN
      v_value := p_input_max;
    END IF;
  ELSE
    IF v_value < p_input_min OR v_value > p_input_max THEN
      RAISE_APPLICATION_ERROR(-20003, 'value out of range');
    END IF;
  END IF;

  RETURN p_output_min + ((v_value - p_input_min) / (p_input_max - p_input_min)) * (p_output_max - p_output_min);
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_float(
  p_value IN NUMBER,
  p_input_min IN NUMBER,
  p_input_max IN NUMBER,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_clip IN BOOLEAN DEFAULT FALSE
) RETURN NUMBER
IS
  v_value NUMBER := p_value;
BEGIN
  IF p_value IS NULL OR p_input_min IS NULL OR p_input_max IS NULL OR p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'value and range endpoints must be finite');
  END IF;

  IF p_input_min >= p_input_max THEN
    RAISE_APPLICATION_ERROR(-20001, 'input_min must be less than input_max');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  IF p_clip THEN
    IF v_value < p_input_min THEN
      v_value := p_input_min;
    ELSIF v_value > p_input_max THEN
      v_value := p_input_max;
    END IF;
  ELSE
    IF v_value < p_input_min OR v_value > p_input_max THEN
      RAISE_APPLICATION_ERROR(-20003, 'value out of range');
    END IF;
  END IF;

  RETURN p_output_min + ((v_value - p_input_min) / (p_input_max - p_input_min)) * (p_output_max - p_output_min);
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_boolean(
  p_value IN BOOLEAN,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_false_value IN NUMBER DEFAULT NULL,
  p_true_value IN NUMBER DEFAULT NULL
) RETURN NUMBER
IS
  v_false_value NUMBER := NVL(p_false_value, p_output_min);
  v_true_value NUMBER := NVL(p_true_value, p_output_max);
BEGIN
  IF p_output_min IS NULL OR p_output_max IS NULL OR v_false_value IS NULL OR v_true_value IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'output values must be finite');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  IF v_false_value < p_output_min OR v_false_value > p_output_max OR v_true_value < p_output_min OR v_true_value > p_output_max THEN
    RAISE_APPLICATION_ERROR(-20004, 'false_value/true_value must be within output range');
  END IF;

  IF v_false_value = v_true_value THEN
    RAISE_APPLICATION_ERROR(-20005, 'false_value and true_value must differ');
  END IF;

  IF p_value THEN
    RETURN v_true_value;
  END IF;
  RETURN v_false_value;
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_categorical(
  p_value IN VARCHAR2,
  p_tokens IN SYS.ODCIVARCHAR2LIST,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1
) RETURN NUMBER
IS
  v_index PLS_INTEGER := NULL;
BEGIN
  IF p_value IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'value must not be null');
  END IF;

  IF p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'output values must be finite');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  IF p_tokens.COUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20006, 'tokens must not be empty');
  END IF;

  FOR i IN 1 .. p_tokens.COUNT LOOP
    IF p_tokens(i) IS NULL THEN
      RAISE_APPLICATION_ERROR(-20007, 'tokens must not contain nulls');
    END IF;
    FOR j IN i + 1 .. p_tokens.COUNT LOOP
      IF p_tokens(i) = p_tokens(j) THEN
        RAISE_APPLICATION_ERROR(-20008, 'tokens must be unique');
      END IF;
    END LOOP;
    IF p_tokens(i) = p_value THEN
      v_index := i;
    END IF;
  END LOOP;

  IF v_index IS NULL THEN
    RAISE_APPLICATION_ERROR(-20009, 'unknown categorical token');
  END IF;

  IF p_tokens.COUNT = 1 THEN
    RETURN (p_output_min + p_output_max) / 2;
  END IF;

  RETURN p_output_min
    + ((v_index - 1) / (p_tokens.COUNT - 1)) * (p_output_max - p_output_min);
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_bytes(
  p_value IN RAW,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_clip IN BOOLEAN DEFAULT FALSE,
  p_allow_empty IN BOOLEAN DEFAULT FALSE
) RETURN SYS.ODCINUMBERLIST
IS
  v_length PLS_INTEGER;
  v_result SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
  v_byte NUMBER;
BEGIN
  IF p_value IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'value must not be null');
  END IF;

  IF p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'output values must be finite');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  v_length := UTL_RAW.LENGTH(p_value);
  IF v_length = 0 AND NOT p_allow_empty THEN
    RAISE_APPLICATION_ERROR(-20011, 'empty bytes payload is invalid by default');
  END IF;

  v_result.EXTEND(v_length);

  FOR i IN 1 .. v_length LOOP
    v_byte := TO_NUMBER(RAWTOHEX(UTL_RAW.SUBSTR(p_value, i, 1)), 'XX');
    v_result(i) := p_output_min + (v_byte / 255) * (p_output_max - p_output_min);
  END LOOP;

  RETURN v_result;
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_sequence(
  p_values IN SYS.ODCINUMBERLIST,
  p_input_min IN NUMBER,
  p_input_max IN NUMBER,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_clip IN BOOLEAN DEFAULT FALSE,
  p_allow_empty IN BOOLEAN DEFAULT FALSE
) RETURN SYS.ODCINUMBERLIST
IS
  v_result SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
BEGIN
  IF p_values.COUNT = 0 AND NOT p_allow_empty THEN
    RAISE_APPLICATION_ERROR(-20011, 'empty sequence input is invalid by default');
  END IF;

  IF p_input_min IS NULL OR p_input_max IS NULL OR p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'value and range endpoints must be finite');
  END IF;

  IF p_input_min >= p_input_max THEN
    RAISE_APPLICATION_ERROR(-20001, 'input_min must be less than input_max');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  v_result.EXTEND(p_values.COUNT);

  FOR i IN 1 .. p_values.COUNT LOOP
    IF p_values(i) IS NULL THEN
      RAISE_APPLICATION_ERROR(-20010, 'sequence elements must not be null');
    END IF;

    v_result(i) := libRangeMap_map_float(
      p_values(i),
      p_input_min,
      p_input_max,
      p_output_min,
      p_output_max,
      p_clip
    );
  END LOOP;

  RETURN v_result;
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_text(
  p_value IN VARCHAR2,
  p_mode IN VARCHAR2 DEFAULT ''codepoint'',
  p_alphabet IN VARCHAR2 DEFAULT NULL,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1
) RETURN SYS.ODCINUMBERLIST
IS
  v_mode VARCHAR2(30) := LOWER(NVL(p_mode, ''codepoint''));
  v_result SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
  v_index PLS_INTEGER;
  v_char VARCHAR2(1);
  v_alphabet_char VARCHAR2(1);
BEGIN
  IF p_value IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'value must not be null');
  END IF;

  IF LENGTH(p_value) = 0 THEN
    RAISE_APPLICATION_ERROR(-20011, 'empty text input is invalid by default');
  END IF;

  IF p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'output values must be finite');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  IF v_mode = 'alphabet' THEN
    IF p_alphabet IS NULL OR LENGTH(p_alphabet) = 0 THEN
      RAISE_APPLICATION_ERROR(-20012, 'alphabet must not be empty');
    END IF;

    FOR i IN 1 .. LENGTH(p_alphabet) LOOP
      v_alphabet_char := SUBSTR(p_alphabet, i, 1);
      FOR j IN i + 1 .. LENGTH(p_alphabet) LOOP
        IF v_alphabet_char = SUBSTR(p_alphabet, j, 1) THEN
          RAISE_APPLICATION_ERROR(-20013, 'alphabet must be unique');
        END IF;
      END LOOP;
    END LOOP;
  ELSIF v_mode NOT IN ('codepoint', 'byte') THEN
    RAISE_APPLICATION_ERROR(-20014, 'unknown text mode');
  END IF;

  v_result.EXTEND(LENGTH(p_value));

  FOR i IN 1 .. LENGTH(p_value) LOOP
    v_char := SUBSTR(p_value, i, 1);

    IF v_mode = 'alphabet' THEN
      v_index := INSTR(p_alphabet, v_char);
      IF v_index = 0 THEN
        RAISE_APPLICATION_ERROR(-20015, 'unknown text token');
      END IF;

      IF LENGTH(p_alphabet) = 1 THEN
        v_result(i) := (p_output_min + p_output_max) / 2;
      ELSE
        v_result(i) := p_output_min
          + ((v_index - 1) / (LENGTH(p_alphabet) - 1)) * (p_output_max - p_output_min);
      END IF;
    ELSE
      v_index := ASCII(v_char);
      v_result(i) := p_output_min + (v_index / 255) * (p_output_max - p_output_min);
    END IF;
  END LOOP;

  RETURN v_result;
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_temporal(
  p_value IN NUMBER,
  p_input_min IN NUMBER,
  p_input_max IN NUMBER,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_clip IN BOOLEAN DEFAULT FALSE
) RETURN NUMBER
IS
  v_value NUMBER := p_value;
BEGIN
  IF p_value IS NULL OR p_input_min IS NULL OR p_input_max IS NULL OR p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'value and range endpoints must be finite');
  END IF;

  IF p_input_min >= p_input_max THEN
    RAISE_APPLICATION_ERROR(-20001, 'input_min must be less than input_max');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  IF p_clip THEN
    IF v_value < p_input_min THEN
      v_value := p_input_min;
    ELSIF v_value > p_input_max THEN
      v_value := p_input_max;
    END IF;
  ELSE
    IF v_value < p_input_min OR v_value > p_input_max THEN
      RAISE_APPLICATION_ERROR(-20003, 'value out of range');
    END IF;
  END IF;

  RETURN p_output_min + ((v_value - p_input_min) / (p_input_max - p_input_min)) * (p_output_max - p_output_min);
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_number_list_to_json(
  p_values IN SYS.ODCINUMBERLIST
) RETURN CLOB
IS
  v_index INTEGER := p_values.FIRST;
  v_output CLOB := '[';
BEGIN
  WHILE v_index IS NOT NULL LOOP
    IF v_index > p_values.FIRST THEN
      v_output := v_output || ',';
    END IF;
    v_output := v_output || TO_CHAR(p_values(v_index), 'FM9999999990.################');
    v_index := p_values.NEXT(v_index);
  END LOOP;
  v_output := v_output || ']';
  RETURN v_output;
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_image_raw(
  p_value IN RAW,
  p_width IN NUMBER,
  p_height IN NUMBER,
  p_channels IN NUMBER DEFAULT 1,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_clip IN BOOLEAN DEFAULT FALSE,
  p_allow_empty IN BOOLEAN DEFAULT FALSE
) RETURN CLOB
IS
  v_length PLS_INTEGER;
  v_expected_length NUMBER;
BEGIN
  IF p_value IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'image payload must not be null');
  END IF;

  IF p_width IS NULL OR p_height IS NULL OR p_channels IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'image shape metadata must be finite');
  END IF;

  IF p_width != TRUNC(p_width) OR p_height != TRUNC(p_height) OR p_channels != TRUNC(p_channels) THEN
    RAISE_APPLICATION_ERROR(-20031, 'image shape metadata must be integral');
  END IF;

  IF p_width < 1 OR p_height < 1 OR p_channels < 1 THEN
    RAISE_APPLICATION_ERROR(-20031, 'image shape metadata must be positive');
  END IF;

  IF p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'output values must be finite');
  END IF;

  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  v_length := UTL_RAW.LENGTH(p_value);
  IF v_length = 0 AND NOT p_allow_empty THEN
    RAISE_APPLICATION_ERROR(-20011, 'empty image payload is invalid by default');
  END IF;

  v_expected_length := p_width * p_height * p_channels;
  IF v_length != v_expected_length THEN
    RAISE_APPLICATION_ERROR(-20032, 'image payload length does not match shape metadata');
  END IF;

  RETURN libRangeMap_number_list_to_json(
    libRangeMap_map_bytes(
      p_value,
      p_output_min,
      p_output_max,
      p_clip,
      p_allow_empty
    )
  );
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_object_value(
  p_value IN CLOB,
  p_spec IN CLOB,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_clip IN BOOLEAN DEFAULT FALSE
) RETURN CLOB
IS
  v_spec JSON_OBJECT_T;
  v_mapper_type VARCHAR2(64);
  v_output_min NUMBER := p_output_min;
  v_output_max NUMBER := p_output_max;
  v_clip BOOLEAN := p_clip;
  v_input_min NUMBER;
  v_input_max NUMBER;
  v_false_value NUMBER;
  v_true_value NUMBER;
  v_text_value VARCHAR2(32767);
  v_mode VARCHAR2(32) := 'codepoint';
  v_alphabet VARCHAR2(32767);
  v_token_count NUMBER;
  v_tokens SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
  v_token VARCHAR2(32767);
  v_index NUMBER;
  v_num NUMBER;
  v_seq JSON_ARRAY_T;
  v_array_len PLS_INTEGER;
  v_width NUMBER;
  v_height NUMBER;
  v_channels NUMBER := 1;
  v_element_spec CLOB;
  v_element_value CLOB;
  v_element_output CLOB;
  v_result SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
  v_scalar_output NUMBER;
  v_allow_unknown_mode VARCHAR2(32);
  v_allow_empty_mode BOOLEAN;
  v_output CLOB;
  i PLS_INTEGER;
  j PLS_INTEGER;
  v_missing_value NUMBER := NULL;
  v_has_missing_value BOOLEAN := FALSE;
  v_missing_output NUMBER;
BEGIN
  IF p_value IS NULL THEN
    RAISE_APPLICATION_ERROR(-20016, 'value must not be null');
  END IF;
  IF p_spec IS NULL OR TRIM(p_spec) = '' THEN
    RAISE_APPLICATION_ERROR(-20017, 'spec must be provided');
  END IF;

  BEGIN
    v_spec := JSON_OBJECT_T.parse(p_spec);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20018, 'spec must be valid JSON');
  END;

  IF v_spec.get('mapper_type') IS NULL AND v_spec.get('family') IS NULL THEN
    RAISE_APPLICATION_ERROR(-20019, 'spec must define mapper_type or family');
  END IF;
  v_mapper_type := LOWER(TRIM(
    CASE
      WHEN v_spec.get('mapper_type') IS NOT NULL THEN v_spec.get_string('mapper_type')
      ELSE v_spec.get_string('family')
    END
  ));

  IF p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'output values must be finite');
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;
  IF v_spec.has('output_min') THEN
    v_output_min := v_spec.get_number('output_min');
  END IF;
  IF v_spec.has('output_max') THEN
    v_output_max := v_spec.get_number('output_max');
  END IF;
  IF v_spec.has('clip') THEN
    v_clip := v_spec.get_boolean('clip');
  END IF;
  IF v_output_min >= v_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;

  IF v_mapper_type = 'integer' THEN
    IF v_spec.has('input_min') IS FALSE OR v_spec.has('input_max') IS FALSE THEN
      RAISE_APPLICATION_ERROR(-20020, 'integer mapper requires input_min and input_max');
    END IF;
    v_input_min := v_spec.get_number('input_min');
    v_input_max := v_spec.get_number('input_max');
    v_num := JSON_VALUE(p_value, '$' RETURNING NUMBER ERROR ON ERROR);
    IF v_num != TRUNC(v_num) THEN
      RAISE_APPLICATION_ERROR(-20021, 'integer mapper requires an integral value');
    END IF;
    v_scalar_output := libRangeMap_map_integer(TRUNC(v_num), v_input_min, v_input_max, v_output_min, v_output_max, v_clip);
    RETURN TO_CHAR(v_scalar_output);

  ELSIF v_mapper_type = 'float' THEN
    IF v_spec.has('input_min') IS FALSE OR v_spec.has('input_max') IS FALSE THEN
      RAISE_APPLICATION_ERROR(-20020, 'float mapper requires input_min and input_max');
    END IF;
    v_input_min := v_spec.get_number('input_min');
    v_input_max := v_spec.get_number('input_max');
    v_num := JSON_VALUE(p_value, '$' RETURNING NUMBER ERROR ON ERROR);
    v_scalar_output := libRangeMap_map_float(v_num, v_input_min, v_input_max, v_output_min, v_output_max, v_clip);
    RETURN TO_CHAR(v_scalar_output);

  ELSIF v_mapper_type = 'boolean' THEN
    IF v_spec.has('false_value') THEN
      v_false_value := v_spec.get_number('false_value');
    END IF;
    IF v_spec.has('true_value') THEN
      v_true_value := v_spec.get_number('true_value');
    END IF;
    v_num := CASE
      WHEN LOWER(TRIM(JSON_VALUE(p_value, '$' RETURNING VARCHAR2(20) ERROR ON ERROR)) = 'true' THEN 1
      WHEN LOWER(TRIM(JSON_VALUE(p_value, '$' RETURNING VARCHAR2(20) ERROR ON ERROR)) = 'false' THEN 0
      ELSE -1
    END;
    IF v_num < 0 THEN
      RAISE_APPLICATION_ERROR(-20022, 'boolean mapper requires true/false');
    END IF;
    RETURN TO_CHAR(libRangeMap_map_boolean(v_num = 1, v_output_min, v_output_max, v_false_value, v_true_value));

  ELSIF v_mapper_type IN ('text', 'string') THEN
    IF v_spec.has('mode') THEN
      v_mode := LOWER(TRIM(v_spec.get_string('mode')));
    END IF;
    IF v_mode NOT IN ('codepoint', 'byte', 'alphabet') THEN
      RAISE_APPLICATION_ERROR(-20014, 'unknown text mode');
    END IF;
    v_text_value := JSON_VALUE(p_value, '$' RETURNING VARCHAR2(32767) ERROR ON ERROR);
    IF v_mode = 'alphabet' THEN
      IF v_spec.has('alphabet') IS FALSE THEN
        RAISE_APPLICATION_ERROR(-20012, 'alphabet must be supplied for alphabet mode');
      END IF;
      v_alphabet := v_spec.get_string('alphabet');
    ELSE
      v_alphabet := NULL;
    END IF;
    v_output := libRangeMap_number_list_to_json(
      libRangeMap_map_text(
        v_text_value,
        v_mode,
        v_alphabet,
        v_output_min,
        v_output_max
      )
    );
    RETURN v_output;

  ELSIF v_mapper_type = 'categorical' OR v_mapper_type = 'vocabulary' THEN
    IF v_spec.has('vocabulary') IS FALSE THEN
      RAISE_APPLICATION_ERROR(-20023, 'categorical mapper requires vocabulary');
    END IF;
    v_seq := v_spec.get_array('vocabulary');
    v_array_len := v_seq.get_size();
    IF v_array_len < 1 THEN
      RAISE_APPLICATION_ERROR(-20006, 'vocabulary must not be empty');
    END IF;
    FOR i IN 0 .. v_array_len - 1 LOOP
      v_token := TRIM(v_seq.get_string(i));
      IF v_token IS NULL THEN
        RAISE_APPLICATION_ERROR(-20007, 'vocabulary tokens must not be null');
      END IF;
      FOR j IN 1 .. v_tokens.COUNT LOOP
        IF v_tokens(j) = v_token THEN
          RAISE_APPLICATION_ERROR(-20008, 'vocabulary tokens must be unique');
        END IF;
      END LOOP;
      v_tokens.EXTEND;
      v_tokens(v_tokens.COUNT) := v_token;
    END LOOP;
    v_text_value := JSON_VALUE(p_value, '$' RETURNING VARCHAR2(32767) ERROR ON ERROR);
    v_scalar_output := libRangeMap_map_categorical(v_text_value, v_tokens, v_output_min, v_output_max);
    RETURN TO_CHAR(v_scalar_output);

  ELSIF v_mapper_type IN ('bytes', 'raw') THEN
    v_text_value := JSON_VALUE(p_value, '$' RETURNING VARCHAR2(32767) ERROR ON ERROR);
    v_output := libRangeMap_number_list_to_json(
      libRangeMap_map_bytes(
        HEXTORAW(v_text_value),
        v_output_min,
        v_output_max,
        v_clip,
        TRUE
      )
    );
    RETURN v_output;

  ELSIF v_mapper_type IN ('image', 'image_like', 'raw_image') THEN
    IF v_spec.has('width') IS FALSE OR v_spec.has('height') IS FALSE THEN
      RAISE_APPLICATION_ERROR(-20031, 'image mapper requires width and height');
    END IF;
    v_width := v_spec.get_number('width');
    v_height := v_spec.get_number('height');
    IF v_spec.has('channels') THEN
      v_channels := v_spec.get_number('channels');
    END IF;
    v_text_value := JSON_VALUE(p_value, '$' RETURNING VARCHAR2(32767) ERROR ON ERROR);
    RETURN libRangeMap_map_image_raw(
      HEXTORAW(v_text_value),
      v_width,
      v_height,
      v_channels,
      v_output_min,
      v_output_max,
      v_clip,
      TRUE
    );

  ELSIF v_mapper_type = 'temporal' THEN
    IF v_spec.has('input_min') IS FALSE OR v_spec.has('input_max') IS FALSE THEN
      RAISE_APPLICATION_ERROR(-20020, 'temporal mapper requires input_min and input_max');
    END IF;
    v_input_min := v_spec.get_number('input_min');
    v_input_max := v_spec.get_number('input_max');
    v_num := JSON_VALUE(p_value, '$' RETURNING NUMBER ERROR ON ERROR);
    v_scalar_output := libRangeMap_map_temporal(v_num, v_input_min, v_input_max, v_output_min, v_output_max, v_clip);
    RETURN TO_CHAR(v_scalar_output);

  ELSIF v_mapper_type = 'sequence' THEN
    IF v_spec.has('element_mapper') IS FALSE THEN
      RAISE_APPLICATION_ERROR(-20024, 'sequence mapper requires element_mapper');
    END IF;
    v_seq := JSON_ARRAY_T.parse(p_value);
    v_array_len := v_seq.get_size();
    IF v_array_len = 0 THEN
      IF NOT (v_spec.has('allow_empty') AND v_spec.get_boolean('allow_empty')) THEN
        RAISE_APPLICATION_ERROR(-20011, 'empty sequence input is invalid by default');
      END IF;
    END IF;
    v_element_spec := v_spec.get('element_mapper').to_string();
    v_output := '[';
    FOR i IN 0 .. v_array_len - 1 LOOP
      v_element_value := v_seq.get(i).to_string();
      IF i > 0 THEN
        v_output := v_output || ',';
      END IF;
      v_element_output := libRangeMap_map_object_value(
        v_element_value,
        v_element_spec,
        v_output_min,
        v_output_max,
        v_clip
      );
      v_output := v_output || v_element_output;
    END LOOP;
    v_output := v_output || ']';
    RETURN v_output;

  ELSIF v_mapper_type IN ('object', 'map') THEN
    IF v_spec.has('schema') IS FALSE THEN
      RAISE_APPLICATION_ERROR(-20025, 'object mapper requires schema');
    END IF;
    v_allow_unknown_mode := CASE WHEN v_spec.has('allow_unknown') THEN CASE WHEN v_spec.get_boolean('allow_unknown') THEN 'allow_unknown' ELSE 'deny_unknown' END ELSE 'deny_unknown' END;
    v_allow_empty_mode := CASE WHEN v_spec.has('allow_empty') THEN v_spec.get_boolean('allow_empty') ELSE FALSE END;
    v_has_missing_value := CASE WHEN v_spec.has('has_missing_value') THEN v_spec.get_boolean('has_missing_value') ELSE FALSE END;
    IF v_has_missing_value THEN
      v_missing_output := v_spec.get_number('missing_value');
      IF v_missing_output IS NULL THEN
        RAISE_APPLICATION_ERROR(-20026, 'missing_value must be provided when has_missing_value is true');
      END IF;
    END IF;
    RETURN libRangeMap_map_object(
      p_value,
      v_spec.get('schema').to_string(),
      (v_allow_unknown_mode = 'allow_unknown'),
      v_allow_empty_mode,
      v_has_missing_value,
      v_missing_output,
      v_output_min,
      v_output_max,
      v_clip
    );

  ELSE
    RAISE_APPLICATION_ERROR(-20027, 'unknown mapper_type');
  END IF;
END;
/

CREATE OR REPLACE FUNCTION libRangeMap_map_object(
  p_value IN CLOB,
  p_schema IN CLOB,
  p_allow_unknown IN BOOLEAN DEFAULT FALSE,
  p_allow_empty IN BOOLEAN DEFAULT FALSE,
  p_has_missing_value IN BOOLEAN DEFAULT FALSE,
  p_missing_value IN NUMBER DEFAULT NULL,
  p_output_min IN NUMBER DEFAULT -1,
  p_output_max IN NUMBER DEFAULT 1,
  p_clip IN BOOLEAN DEFAULT FALSE
) RETURN CLOB
IS
  v_spec JSON_OBJECT_T;
  v_value JSON_OBJECT_T;
  v_schema JSON_OBJECT_T;
  v_schema_keys JSON_KEY_LIST;
  v_value_keys JSON_KEY_LIST;
  v_output CLOB;
  v_schema_count NUMBER;
  v_value_count NUMBER;
  v_field VARCHAR2(32767);
  v_field_spec CLOB;
  v_field_value CLOB;
  v_field_output CLOB;
  v_missing_value NUMBER := p_missing_value;
  v_field_index INTEGER;
  v_schema_exists BOOLEAN;
BEGIN
  IF p_value IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'value must not be null');
  END IF;
  IF p_schema IS NULL THEN
    RAISE_APPLICATION_ERROR(-20017, 'schema must be provided');
  END IF;

  IF p_output_min IS NULL OR p_output_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20010, 'output values must be finite');
  END IF;
  IF p_output_min >= p_output_max THEN
    RAISE_APPLICATION_ERROR(-20002, 'output_min must be less than output_max');
  END IF;
  IF p_has_missing_value AND (p_missing_value IS NULL OR p_missing_value < p_output_min OR p_missing_value > p_output_max) THEN
    RAISE_APPLICATION_ERROR(-20010, 'missing_value must be finite and within output range');
  END IF;

  BEGIN
    v_value := JSON_OBJECT_T.parse(p_value);
    v_schema := JSON_OBJECT_T.parse(p_schema);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20018, 'value and schema must be valid JSON objects');
  END;

  v_schema_keys := v_schema.get_keys();
  v_schema_count := CASE WHEN v_schema_keys IS NULL THEN 0 ELSE v_schema_keys.COUNT END;
  v_value_keys := v_value.get_keys();
  v_value_count := CASE WHEN v_value_keys IS NULL THEN 0 ELSE v_value_keys.COUNT END;

  IF v_schema_count = 0 THEN
    IF NOT p_allow_empty THEN
      RAISE_APPLICATION_ERROR(-20028, 'schema must define at least one field');
    END IF;
  END IF;

  IF v_value_count = 0 AND NOT p_allow_empty THEN
    RAISE_APPLICATION_ERROR(-20011, 'object payload must not be empty unless allow_empty is true');
  END IF;

  FOR i IN 1 .. v_value_count LOOP
    v_schema_exists := FALSE;
    FOR j IN 1 .. v_schema_count LOOP
      IF v_value_keys(i) = v_schema_keys(j) THEN
        v_schema_exists := TRUE;
        EXIT;
      END IF;
    END LOOP;
    IF NOT v_schema_exists AND NOT p_allow_unknown THEN
      RAISE_APPLICATION_ERROR(-20029, 'unknown field(s) in payload');
    END IF;
  END LOOP;

  v_output := '{';
  FOR i IN 1 .. v_schema_count LOOP
    v_field := v_schema_keys(i);
    v_field_spec := v_schema.get(v_field).to_string();
    IF v_value.has(v_field) THEN
      v_field_value := v_value.get(v_field).to_string();
    ELSIF p_has_missing_value THEN
      v_output := v_output || CASE WHEN i > 1 THEN ',' END || '"' || REPLACE(v_field, '"', '\"') || '":' || TO_CHAR(v_missing_value);
      CONTINUE;
    ELSE
      RAISE_APPLICATION_ERROR(-20030, 'missing required field in payload');
    END IF;

    v_field_output := libRangeMap_map_object_value(
      v_field_value,
      v_field_spec,
      p_output_min,
      p_output_max,
      p_clip
    );
    v_output := v_output || CASE WHEN i > 1 THEN ',' END || '"' || REPLACE(v_field, '"', '\"') || '":' || v_field_output;
  END LOOP;
  v_output := v_output || '}';

  RETURN v_output;
END;
/
