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
