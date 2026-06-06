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
