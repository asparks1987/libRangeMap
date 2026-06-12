"use strict";

const fs = require("node:fs");

const SPEC_VERSION = "1.0-alpha";
const MAPPER_TYPE_INTEGER_RANGE = "integer_range";
const MAPPER_TYPE_FLOAT_RANGE = "float_range";
const MAPPER_TYPE_BOOLEAN_RANGE = "boolean_range";
const MAPPER_TYPE_SEQUENCE_RANGE = "sequence_range";
const MAPPER_TYPE_TEXT_RANGE = "text_range";
const DEFAULT_OUTPUT_RANGE = [-1.0, 1.0];

class IntegerRangeMapper {
  constructor(inputRange, outputRange = DEFAULT_OUTPUT_RANGE, clip = false, name = null) {
    if (!Array.isArray(inputRange) || inputRange.length !== 2) {
      throw new TypeError("input_range must be a two-item array.");
    }
    if (!Array.isArray(outputRange) || outputRange.length !== 2) {
      throw new TypeError("output_range must be a two-item array.");
    }
    if (typeof clip !== "boolean") {
      throw new TypeError("clip must be a boolean.");
    }
    if (name !== null && typeof name !== "string") {
      throw new TypeError("name must be a string or null.");
    }

    const inputMin = requireInteger(inputRange[0], "input_range[0]");
    const inputMax = requireInteger(inputRange[1], "input_range[1]");
    const outputMin = requireFiniteNumber(outputRange[0], "output_range[0]");
    const outputMax = requireFiniteNumber(outputRange[1], "output_range[1]");

    validateIntegerRange(inputMin, inputMax);
    validateOutputRange(outputMin, outputMax);

    this.inputRange = [inputMin, inputMax];
    this.outputRange = [outputMin, outputMax];
    this.clip = clip;
    this.name = name;
  }

  mapValue(value) {
    const input = requireInteger(value, "value");
    return mapIntegerValue(input, this.inputRange, this.outputRange, this.clip);
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_INTEGER_RANGE,
      input_range: [this.inputRange[0], this.inputRange[1]],
      output_range: [this.outputRange[0], this.outputRange[1]],
      clip: this.clip,
    };
    if (this.name !== null) {
      spec.name = this.name;
    }
    return spec;
  }

  toJSON() {
    return JSON.stringify(this.toDict());
  }

  save(path) {
    fs.writeFileSync(path, this.toJSON(), "utf8");
  }

  static fromDict(data) {
    if (data === null || typeof data !== "object" || Array.isArray(data)) {
      throw new TypeError("mapper spec must be an object.");
    }
    if (data.spec_version !== SPEC_VERSION) {
      throw new Error(`unsupported spec_version ${JSON.stringify(data.spec_version)}; expected ${JSON.stringify(SPEC_VERSION)}.`);
    }
    if (data.mapper_type !== MAPPER_TYPE_INTEGER_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_INTEGER_RANGE)}.`);
    }
    return new IntegerRangeMapper(
      data.input_range,
      data.output_range,
      Boolean(data.clip),
      data.name ?? null,
    );
  }

  static fromJSON(text) {
    return IntegerRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return IntegerRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
  }
}

class FloatRangeMapper {
  constructor(inputRange, outputRange = DEFAULT_OUTPUT_RANGE, clip = false, name = null) {
    if (!Array.isArray(inputRange) || inputRange.length !== 2) {
      throw new TypeError("input_range must be a two-item array.");
    }
    if (!Array.isArray(outputRange) || outputRange.length !== 2) {
      throw new TypeError("output_range must be a two-item array.");
    }
    if (typeof clip !== "boolean") {
      throw new TypeError("clip must be a boolean.");
    }
    if (name !== null && typeof name !== "string") {
      throw new TypeError("name must be a string or null.");
    }

    const inputMin = requireFiniteNumber(inputRange[0], "input_range[0]");
    const inputMax = requireFiniteNumber(inputRange[1], "input_range[1]");
    const outputMin = requireFiniteNumber(outputRange[0], "output_range[0]");
    const outputMax = requireFiniteNumber(outputRange[1], "output_range[1]");

    validateInputFloatRange(inputMin, inputMax);
    validateOutputRange(outputMin, outputMax);

    this.inputRange = [inputMin, inputMax];
    this.outputRange = [outputMin, outputMax];
    this.clip = clip;
    this.name = name;
  }

  mapValue(value) {
    const input = requireFiniteNumber(value, "value");
    return mapFloatValue(input, this.inputRange, this.outputRange, this.clip);
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_FLOAT_RANGE,
      input_range: [this.inputRange[0], this.inputRange[1]],
      output_range: [this.outputRange[0], this.outputRange[1]],
      clip: this.clip,
    };
    if (this.name !== null) {
      spec.name = this.name;
    }
    return spec;
  }

  toJSON() {
    return JSON.stringify(this.toDict());
  }

  save(path) {
    fs.writeFileSync(path, this.toJSON(), "utf8");
  }

  static fromDict(data) {
    if (data === null || typeof data !== "object" || Array.isArray(data)) {
      throw new TypeError("mapper spec must be an object.");
    }
    if (data.spec_version !== SPEC_VERSION) {
      throw new Error(`unsupported spec_version ${JSON.stringify(data.spec_version)}; expected ${JSON.stringify(SPEC_VERSION)}.`);
    }
    if (data.mapper_type !== MAPPER_TYPE_FLOAT_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_FLOAT_RANGE)}.`);
    }
    return new FloatRangeMapper(
      data.input_range,
      data.output_range,
      Boolean(data.clip),
      data.name ?? null,
    );
  }

  static fromJSON(text) {
    return FloatRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return FloatRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
  }
}

class BooleanRangeMapper {
  constructor(outputRange = DEFAULT_OUTPUT_RANGE, falseValue = null, trueValue = null, name = null) {
    if (!Array.isArray(outputRange) || outputRange.length !== 2) {
      throw new TypeError("output_range must be a two-item array.");
    }
    if (name !== null && typeof name !== "string") {
      throw new TypeError("name must be a string or null.");
    }
    if (falseValue !== null && !Number.isFinite(falseValue)) {
      throw new TypeError("false_value must be a finite number.");
    }
    if (trueValue !== null && !Number.isFinite(trueValue)) {
      throw new TypeError("true_value must be a finite number.");
    }

    const outputMin = requireFiniteNumber(outputRange[0], "output_range[0]");
    const outputMax = requireFiniteNumber(outputRange[1], "output_range[1]");

    validateOutputRange(outputMin, outputMax);

    this.outputRange = [outputMin, outputMax];
    this.falseValue = typeof falseValue === "number" ? falseValue : outputMin;
    this.trueValue = typeof trueValue === "number" ? trueValue : outputMax;
    this.name = name;
  }

  mapValue(value) {
    if (typeof value !== "boolean") {
      throw new TypeError("value must be a boolean.");
    }
    return value ? this.trueValue : this.falseValue;
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_BOOLEAN_RANGE,
      output_range: [this.outputRange[0], this.outputRange[1]],
      false_value: this.falseValue,
      true_value: this.trueValue,
    };
    if (this.name !== null) {
      spec.name = this.name;
    }
    return spec;
  }

  toJSON() {
    return JSON.stringify(this.toDict());
  }

  save(path) {
    fs.writeFileSync(path, this.toJSON(), "utf8");
  }

  static fromDict(data) {
    if (data === null || typeof data !== "object" || Array.isArray(data)) {
      throw new TypeError("mapper spec must be an object.");
    }
    if (data.spec_version !== SPEC_VERSION) {
      throw new Error(`unsupported spec_version ${JSON.stringify(data.spec_version)}; expected ${JSON.stringify(SPEC_VERSION)}.`);
    }
    if (data.mapper_type !== MAPPER_TYPE_BOOLEAN_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_BOOLEAN_RANGE)}.`);
    }
    return new BooleanRangeMapper(
      data.output_range,
      data.false_value,
      data.true_value,
      data.name ?? null,
    );
  }

  static fromJSON(text) {
    return BooleanRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return BooleanRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
  }
}

class SequenceRangeMapper {
  constructor(elementMapper, { allowEmpty = false, name = null } = {}) {
    if (!elementMapper || typeof elementMapper.mapValue !== "function") {
      throw new TypeError("elementMapper must provide mapValue(value).");
    }
    if (typeof allowEmpty !== "boolean") {
      throw new TypeError("allowEmpty must be a boolean.");
    }
    if (name !== null && typeof name !== "string") {
      throw new TypeError("name must be a string or null.");
    }
    this.elementMapper = elementMapper;
    this.allowEmpty = allowEmpty;
    this.name = name;
  }

  mapValue(value) {
    if (Array.isArray(value)) {
      if (!this.allowEmpty && value.length === 0) {
        throw new TypeError("empty sequence is invalid by default; set allowEmpty=true to map empty containers.");
      }
      return value.map((item) => this.mapValue(item));
    }
    return this.elementMapper.mapValue(value);
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_SEQUENCE_RANGE,
      element_mapper: this.elementMapper.toDict(),
      allow_empty: this.allowEmpty,
    };
    if (this.name !== null) {
      spec.name = this.name;
    }
    return spec;
  }

  toJSON() {
    return JSON.stringify(this.toDict());
  }

  save(path) {
    fs.writeFileSync(path, this.toJSON(), "utf8");
  }

  static fromDict(data) {
    if (data === null || typeof data !== "object" || Array.isArray(data)) {
      throw new TypeError("mapper spec must be an object.");
    }
    if (data.spec_version !== SPEC_VERSION) {
      throw new Error(`unsupported spec_version ${JSON.stringify(data.spec_version)}; expected ${JSON.stringify(SPEC_VERSION)}.`);
    }
    if (data.mapper_type !== MAPPER_TYPE_SEQUENCE_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_SEQUENCE_RANGE)}.`);
    }
    if (!data.element_mapper || typeof data.element_mapper !== "object") {
      throw new TypeError("element_mapper must be a valid mapper spec object.");
    }
    return new SequenceRangeMapper(mapperFromDict(data.element_mapper), {
      allowEmpty: Boolean(data.allow_empty),
      name: data.name ?? null,
    });
  }

  static fromJSON(text) {
    return SequenceRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return SequenceRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
  }
}

class TextRangeMapper {
  constructor(outputRange = DEFAULT_OUTPUT_RANGE, mode = "codepoint", options = {}) {
    if (!Array.isArray(outputRange) || outputRange.length !== 2) {
      throw new TypeError("outputRange must be a two-item array.");
    }
    if (typeof mode !== "string") {
      throw new TypeError("mode must be a string.");
    }
    if (mode !== "codepoint" && mode !== "alphabet" && mode !== "byte") {
      throw new TypeError("mode must be 'codepoint', 'alphabet', or 'byte'.");
    }
    if (options === null || typeof options !== "object" || Array.isArray(options)) {
      throw new TypeError("options must be an object.");
    }
    if (typeof options.allowEmpty !== "undefined" && typeof options.allowEmpty !== "boolean") {
      throw new TypeError("allowEmpty must be a boolean.");
    }
    if (options.clip !== undefined && typeof options.clip !== "boolean") {
      throw new TypeError("clip must be a boolean.");
    }
    if (options.name !== undefined && options.name !== null && typeof options.name !== "string") {
      throw new TypeError("name must be a string or null.");
    }

    const outputMin = requireFiniteNumber(outputRange[0], "output_range[0]");
    const outputMax = requireFiniteNumber(outputRange[1], "output_range[1]");
    validateOutputRange(outputMin, outputMax);

    this.mode = mode;
    this.outputRange = [outputMin, outputMax];
    this.clip = options.clip === true;
    this.allowEmpty = options.allowEmpty === true;
    this.name = options.name ?? null;
    this.alphabet = options.alphabet;
    this.alphabetMap = null;
    if (this.mode === "alphabet") {
      if (typeof this.alphabet !== "string" || this.alphabet.length === 0) {
        throw new TypeError("alphabet is required and must be a non-empty string for alphabet mode.");
      }
      this.inputRange = [0, this.alphabet.length - 1];
      this.alphabetMap = new Map();
      for (let i = 0; i < this.alphabet.length; i++) {
        const ch = this.alphabet[i];
        if (this.alphabetMap.has(ch)) {
          throw new TypeError("alphabet must contain unique characters.");
        }
        this.alphabetMap.set(ch, i);
      }
    } else if (this.mode === "byte") {
      this.inputRange = [0, 255];
    } else {
      this.inputRange = [0, 0x10ffff];
    }
  }

  mapValue(value) {
    if (typeof value !== "string") {
      throw new TypeError("value must be a string.");
    }
    if (value.length === 0 && !this.allowEmpty) {
      throw new TypeError("empty string is invalid by default; set allowEmpty=true to map empty strings.");
    }

    const values = this.mode === "byte" ? Buffer.from(value, "utf8") : [...value];
    const [inputMin, inputMax] = this.inputRange;
    const out = [];
    for (const unit of values) {
      let numeric = 0;
      if (this.mode === "byte") {
        numeric = unit;
      } else if (this.mode === "codepoint") {
        numeric = requireFiniteNumber(unit.codePointAt(0), "string value");
      } else {
        if (!this.alphabetMap.has(unit)) {
          throw new TypeError(`unknown character ${JSON.stringify(unit)} for alphabet mode.`);
        }
        numeric = this.alphabetMap.get(unit);
      }

      if (numeric < inputMin) {
        if (!this.clip) {
          throw new RangeError(`value ${numeric} is below input_range lower bound ${inputMin}; enable clip to clamp.`);
        }
        numeric = inputMin;
      } else if (numeric > inputMax) {
        if (!this.clip) {
          throw new RangeError(`value ${numeric} is above input_range upper bound ${inputMax}; enable clip to clamp.`);
        }
        numeric = inputMax;
      }
      out.push(linearMap(numeric, inputMin, inputMax, this.outputRange[0], this.outputRange[1]));
    }
    return out;
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_TEXT_RANGE,
      output_range: [this.outputRange[0], this.outputRange[1]],
      mode: this.mode,
      clip: this.clip,
      allow_empty: this.allowEmpty,
    };
    if (this.alphabet !== undefined) {
      spec.alphabet = this.alphabet;
    }
    if (this.name !== null) {
      spec.name = this.name;
    }
    return spec;
  }

  toJSON() {
    return JSON.stringify(this.toDict());
  }

  save(path) {
    fs.writeFileSync(path, this.toJSON(), "utf8");
  }

  static fromDict(data) {
    if (data === null || typeof data !== "object" || Array.isArray(data)) {
      throw new TypeError("mapper spec must be an object.");
    }
    if (data.spec_version !== SPEC_VERSION) {
      throw new Error(`unsupported spec_version ${JSON.stringify(data.spec_version)}; expected ${JSON.stringify(SPEC_VERSION)}.`);
    }
    if (data.mapper_type !== MAPPER_TYPE_TEXT_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_TEXT_RANGE)}.`);
    }
    return new TextRangeMapper(
      data.output_range,
      data.mode ?? "codepoint",
      {
        clip: Boolean(data.clip),
        allowEmpty: Boolean(data.allow_empty),
        alphabet: data.alphabet,
        name: data.name ?? null,
      },
    );
  }

  static fromJSON(text) {
    return TextRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return TextRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
  }
}

function requireInteger(value, label) {
  if (typeof value === "bigint") {
    return value;
  }
  if (typeof value === "number" && Number.isInteger(value) && Number.isFinite(value)) {
    return value;
  }
  throw new TypeError(`${label} must be an integer.`);
}

function requireFiniteNumber(value, label) {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new TypeError(`${label} must be a finite number.`);
  }
  return value;
}

function validateInputFloatRange(inputMin, inputMax) {
  if (inputMax <= inputMin) {
    throw new RangeError("input_range must be strictly increasing.");
  }
}

function validateIntegerRange(inputMin, inputMax) {
  if (typeof inputMin === "bigint" || typeof inputMax === "bigint") {
    if (BigInt(inputMax) <= BigInt(inputMin)) {
      throw new RangeError("input_range must be strictly increasing.");
    }
    return;
  }
  if (inputMax <= inputMin) {
    throw new RangeError("input_range must be strictly increasing.");
  }
}

function validateOutputRange(outputMin, outputMax) {
  if (!(Number.isFinite(outputMin) && Number.isFinite(outputMax) && outputMax > outputMin)) {
    throw new RangeError("output_range must be finite and strictly increasing.");
  }
}

function mapIntegerValue(value, inputRange, outputRange, clip) {
  let current = value;
  const inputMin = inputRange[0];
  const inputMax = inputRange[1];
  const outputMin = outputRange[0];
  const outputMax = outputRange[1];

  if (typeof current === "bigint" || typeof inputMin === "bigint" || typeof inputMax === "bigint") {
    const v = BigInt(current);
    const min = BigInt(inputMin);
    const max = BigInt(inputMax);
    if (v < min) {
      if (!clip) {
        throw new RangeError(`value ${String(value)} is below input_range lower bound ${String(min)}; enable clip to clamp.`);
      }
      current = min;
    } else if (v > max) {
      if (!clip) {
        throw new RangeError(`value ${String(value)} is above input_range upper bound ${String(max)}; enable clip to clamp.`);
      }
      current = max;
    } else {
      current = v;
    }
    return linearMap(Number(current), Number(min), Number(max), outputMin, outputMax);
  }

  if (current < inputMin) {
    if (!clip) {
      throw new RangeError(`value ${current} is below input_range lower bound ${inputMin}; enable clip to clamp.`);
    }
    current = inputMin;
  } else if (current > inputMax) {
    if (!clip) {
      throw new RangeError(`value ${current} is above input_range upper bound ${inputMax}; enable clip to clamp.`);
    }
    current = inputMax;
  }

  return linearMap(current, inputMin, inputMax, outputMin, outputMax);
}

function mapFloatValue(value, inputRange, outputRange, clip) {
  const inputMin = inputRange[0];
  const inputMax = inputRange[1];
  const outputMin = outputRange[0];
  const outputMax = outputRange[1];

  let current = value;
  if (current < inputMin) {
    if (!clip) {
      throw new RangeError(`value ${current} is below input_range lower bound ${inputMin}; enable clip to clamp.`);
    }
    current = inputMin;
  } else if (current > inputMax) {
    if (!clip) {
      throw new RangeError(`value ${current} is above input_range upper bound ${inputMax}; enable clip to clamp.`);
    }
    current = inputMax;
  }

  return linearMap(current, inputMin, inputMax, outputMin, outputMax);
}

function linearMap(value, inMin, inMax, outMin, outMax) {
  return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
}

function mapperFromDict(data) {
  if (data === null || typeof data !== "object" || Array.isArray(data)) {
    throw new TypeError("mapper spec must be an object.");
  }
  const mapperType = data.mapper_type;
  if (mapperType === MAPPER_TYPE_INTEGER_RANGE) {
    return IntegerRangeMapper.fromDict(data);
  }
  if (mapperType === MAPPER_TYPE_FLOAT_RANGE) {
    return FloatRangeMapper.fromDict(data);
  }
  if (mapperType === MAPPER_TYPE_BOOLEAN_RANGE) {
    return BooleanRangeMapper.fromDict(data);
  }
  if (mapperType === MAPPER_TYPE_SEQUENCE_RANGE) {
    return SequenceRangeMapper.fromDict(data);
  }
  if (mapperType === MAPPER_TYPE_TEXT_RANGE) {
    return TextRangeMapper.fromDict(data);
  }
  throw new Error(`unsupported mapper_type ${JSON.stringify(mapperType)}.`);
}

module.exports = {
  DEFAULT_OUTPUT_RANGE,
  IntegerRangeMapper,
  FloatRangeMapper,
  BooleanRangeMapper,
  SequenceRangeMapper,
  TextRangeMapper,
  SPEC_VERSION,
  MAPPER_TYPE_INTEGER_RANGE,
  MAPPER_TYPE_FLOAT_RANGE,
  MAPPER_TYPE_BOOLEAN_RANGE,
  MAPPER_TYPE_SEQUENCE_RANGE,
  MAPPER_TYPE_TEXT_RANGE,
};
