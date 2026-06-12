"use strict";

const fs = require("node:fs");

const SPEC_VERSION = "1.0-alpha";
const MAPPER_TYPE_INTEGER_RANGE = "integer_range";
const MAPPER_TYPE_FLOAT_RANGE = "float_range";
const MAPPER_TYPE_BOOLEAN_RANGE = "boolean_range";
const MAPPER_TYPE_SEQUENCE_RANGE = "sequence_range";
const MAPPER_TYPE_TEXT_RANGE = "text_range";
const MAPPER_TYPE_BYTES_RANGE = "bytes_range";
const MAPPER_TYPE_MAP_RANGE = "map_range";
const MAPPER_TYPE_CATEGORICAL_RANGE = "categorical_range";
const MAPPER_TYPE_TEMPORAL_RANGE = "temporal_range";
const MAPPER_TYPE_IMAGE_RANGE = "image_range";
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

class CategoricalRangeMapper {
  constructor(vocabulary, outputRange = DEFAULT_OUTPUT_RANGE, name = null) {
    if (!Array.isArray(vocabulary)) {
      throw new TypeError("vocabulary must be an array.");
    }
    if (vocabulary.length === 0) {
      throw new TypeError("vocabulary must be non-empty.");
    }
    if (!Array.isArray(outputRange) || outputRange.length !== 2) {
      throw new TypeError("outputRange must be a two-item array.");
    }
    if (name !== null && typeof name !== "string") {
      throw new TypeError("name must be a string or null.");
    }

    const outputMin = requireFiniteNumber(outputRange[0], "output_range[0]");
    const outputMax = requireFiniteNumber(outputRange[1], "output_range[1]");
    validateOutputRange(outputMin, outputMax);

    this.vocabulary = [];
    this.vocabularyMap = new Map();
    this.outputRange = [outputMin, outputMax];

    for (let i = 0; i < vocabulary.length; i++) {
      const token = vocabulary[i];
      validateCategoricalToken(token, `vocabulary[${i}]`);
      if (this.vocabularyMap.has(token)) {
        throw new TypeError(`vocabulary must contain unique tokens; duplicate found for ${tokenToString(token)}.`);
      }
      this.vocabulary.push(token);
      this.vocabularyMap.set(token, i);
    }

    this.name = name;
  }

  mapValue(value) {
    validateCategoricalToken(value, "value");
    if (!this.vocabularyMap.has(value)) {
      throw new TypeError(`unknown token ${tokenToString(value)}; configure a vocabulary or explicit unknown-token policy.`);
    }
    const index = this.vocabularyMap.get(value);
    if (this.vocabulary.length === 1) {
      return this.outputRange[0];
    }
    return linearMap(index, 0.0, this.vocabulary.length - 1, this.outputRange[0], this.outputRange[1]);
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_CATEGORICAL_RANGE,
      vocabulary: this.vocabulary,
      output_range: [this.outputRange[0], this.outputRange[1]],
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
    if (data.mapper_type !== MAPPER_TYPE_CATEGORICAL_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_CATEGORICAL_RANGE)}.`);
    }
    if (!Array.isArray(data.vocabulary)) {
      throw new TypeError("vocabulary must be an array.");
    }
    return new CategoricalRangeMapper(
      data.vocabulary,
      data.output_range,
      data.name ?? null,
    );
  }

  static fromJSON(text) {
    return CategoricalRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return CategoricalRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
  }
}

class TemporalRangeMapper {
  constructor(inputRange, outputRange = DEFAULT_OUTPUT_RANGE, clip = false, name = null) {
    if (!Array.isArray(inputRange) || inputRange.length !== 2) {
      throw new TypeError("inputRange must be a two-item array.");
    }
    if (!Array.isArray(outputRange) || outputRange.length !== 2) {
      throw new TypeError("outputRange must be a two-item array.");
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
    const timestamp = coerceTemporalValue(value);
    return mapFloatValue(timestamp, this.inputRange, this.outputRange, this.clip);
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_TEMPORAL_RANGE,
      input_range: [this.inputRange[0], this.inputRange[1]],
      output_range: [this.outputRange[0], this.outputRange[1]],
      clip: this.clip,
      input_unit: "milliseconds_since_epoch",
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
    if (data.mapper_type !== MAPPER_TYPE_TEMPORAL_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_TEMPORAL_RANGE)}.`);
    }
    if (data.input_unit !== undefined && data.input_unit !== "milliseconds_since_epoch") {
      throw new Error(`unsupported input_unit ${JSON.stringify(data.input_unit)}; expected "milliseconds_since_epoch".`);
    }
    return new TemporalRangeMapper(
      data.input_range,
      data.output_range,
      Boolean(data.clip),
      data.name ?? null,
    );
  }

  static fromJSON(text) {
    return TemporalRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return TemporalRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
  }
}

class ImageRangeMapper {
  constructor(outputRange = DEFAULT_OUTPUT_RANGE, clip = false, allowEmpty = false, name = null) {
    if (!Array.isArray(outputRange) || outputRange.length !== 2) {
      throw new TypeError("outputRange must be a two-item array.");
    }
    if (typeof clip !== "boolean") {
      throw new TypeError("clip must be a boolean.");
    }
    if (typeof allowEmpty !== "boolean") {
      throw new TypeError("allowEmpty must be a boolean.");
    }
    if (name !== null && typeof name !== "string") {
      throw new TypeError("name must be a string or null.");
    }

    const outputMin = requireFiniteNumber(outputRange[0], "output_range[0]");
    const outputMax = requireFiniteNumber(outputRange[1], "output_range[1]");
    validateOutputRange(outputMin, outputMax);

    this.outputRange = [outputMin, outputMax];
    this.clip = clip;
    this.allowEmpty = allowEmpty;
    this.name = name;
  }

  mapValue(value) {
    if (Buffer.isBuffer(value) || value instanceof ArrayBuffer || ArrayBuffer.isView(value)) {
      const bytes = new BytesRangeMapper(this.outputRange, this.clip, this.allowEmpty, this.name);
      return bytes.mapValue(value);
    }
    return this._mapNode(value, 0);
  }

  _mapNode(value, depth) {
    if (Array.isArray(value)) {
      if (value.length === 0 && !this.allowEmpty) {
        throw new TypeError("empty image-like container is invalid by default; set allowEmpty=true to map empty containers.");
      }
      return value.map((child) => this._mapNode(child, depth + 1));
    }
    if (value === null || typeof value !== "number" || !Number.isFinite(value)) {
      throw new TypeError("image-like values must be numeric grayscale/channel values or nested arrays of numeric pixels.");
    }
    if (value < 0 || value > 255) {
      if (!this.clip) {
        throw new RangeError(`image value ${value} is outside the supported 0..255 channel range; enable clip to clamp.`);
      }
    }
    const channel = value < 0 ? 0 : value > 255 ? 255 : value;
    return linearMap(channel, 0.0, 255.0, this.outputRange[0], this.outputRange[1]);
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_IMAGE_RANGE,
      output_range: [this.outputRange[0], this.outputRange[1]],
      clip: this.clip,
      allow_empty: this.allowEmpty,
      input_range: [0, 255],
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
    if (data.mapper_type !== MAPPER_TYPE_IMAGE_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_IMAGE_RANGE)}.`);
    }
    return new ImageRangeMapper(
      data.output_range,
      Boolean(data.clip),
      Boolean(data.allow_empty),
      data.name ?? null,
    );
  }

  static fromJSON(text) {
    return ImageRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return ImageRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
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

class BytesRangeMapper {
  constructor(outputRange = DEFAULT_OUTPUT_RANGE, clip = false, allowEmpty = false, name = null) {
    if (!Array.isArray(outputRange) || outputRange.length !== 2) {
      throw new TypeError("outputRange must be a two-item array.");
    }
    if (typeof clip !== "boolean") {
      throw new TypeError("clip must be a boolean.");
    }
    if (typeof allowEmpty !== "boolean") {
      throw new TypeError("allowEmpty must be a boolean.");
    }
    if (name !== null && typeof name !== "string") {
      throw new TypeError("name must be a string or null.");
    }

    const outputMin = requireFiniteNumber(outputRange[0], "output_range[0]");
    const outputMax = requireFiniteNumber(outputRange[1], "output_range[1]");
    validateOutputRange(outputMin, outputMax);

    this.inputRange = [0, 255];
    this.outputRange = [outputMin, outputMax];
    this.clip = clip;
    this.allowEmpty = allowEmpty;
    this.name = name;
  }

  mapValue(value) {
    const bytes = this._coerceBytes(value);
    if (bytes.length === 0 && !this.allowEmpty) {
      throw new TypeError("empty bytes value is invalid by default; set allowEmpty=true to map empty bytes.");
    }
    const out = [];
    for (let i = 0; i < bytes.length; i++) {
      const raw = bytes[i];
      const numeric = this._validateByte(raw, i);
      const mapped = mapIntegerValue(numeric, this.inputRange, this.outputRange, this.clip);
      out.push(mapped);
    }
    return out;
  }

  map(value) {
    return this.mapValue(value);
  }

  _validateByte(value, index) {
    if (typeof value !== "number" || !Number.isInteger(value)) {
      throw new TypeError(`bytes[${index}] must be an integer byte.`);
    }
    if (value < 0) {
      if (!this.clip) {
        throw new RangeError(`byte value ${value} is below input_range lower bound 0; enable clip to clamp.`);
      }
      return 0;
    }
    if (value > 255) {
      if (!this.clip) {
        throw new RangeError(`byte value ${value} is above input_range upper bound 255; enable clip to clamp.`);
      }
      return 255;
    }
    return value;
  }

  _coerceBytes(value) {
    if (Buffer.isBuffer(value)) {
      return value;
    }
    if (value instanceof ArrayBuffer) {
      return new Uint8Array(value);
    }
    if (Array.isArray(value)) {
      return value;
    }
    if (ArrayBuffer.isView(value)) {
      return value;
    }
    throw new TypeError("value must be Buffer, Uint8Array, ArrayBuffer, typed byte-view, or byte-number array.");
  }

  toDict() {
    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_BYTES_RANGE,
      input_range: [this.inputRange[0], this.inputRange[1]],
      output_range: [this.outputRange[0], this.outputRange[1]],
      clip: this.clip,
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
    if (data.mapper_type !== MAPPER_TYPE_BYTES_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_BYTES_RANGE)}.`);
    }
    if (data.input_range) {
      if (
        !Array.isArray(data.input_range) ||
        data.input_range.length !== 2 ||
        data.input_range[0] !== 0 ||
        data.input_range[1] !== 255
      ) {
        throw new Error("unsupported input_range for bytes mapper; expected [0, 255].");
      }
    }
    return new BytesRangeMapper(
      data.output_range,
      Boolean(data.clip),
      Boolean(data.allow_empty),
      data.name ?? null,
    );
  }

  static fromJSON(text) {
    return BytesRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return BytesRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
  }
}

class ObjectRangeMapper {
  constructor(schema, options = {}) {
    if (!schema || typeof schema !== "object" || Array.isArray(schema)) {
      throw new TypeError("schema must be a non-array object mapping field names to mappers.");
    }
    if (options === null || typeof options !== "object" || Array.isArray(options)) {
      throw new TypeError("options must be an object.");
    }

    const {
      allowUnknown = false,
      allowEmpty = false,
      missingValue,
      name = null,
    } = options;

    if (typeof allowUnknown !== "boolean") {
      throw new TypeError("allowUnknown must be a boolean.");
    }
    if (typeof allowEmpty !== "boolean") {
      throw new TypeError("allowEmpty must be a boolean.");
    }
    if (name !== null && typeof name !== "string") {
      throw new TypeError("name must be a string or null.");
    }

    this.schema = this._validateSchema(schema);
    if (!allowEmpty && Object.keys(this.schema).length === 0) {
      throw new TypeError("schema must contain at least one field unless allowEmpty is true.");
    }
    this.allowUnknown = allowUnknown;
    this.allowEmpty = allowEmpty;
    this.name = name;
    this.hasMissingValue = Object.prototype.hasOwnProperty.call(options, "missingValue");
    this.missingValue = missingValue;
  }

  _validateSchema(schema) {
    const keys = Object.keys(schema);
    const parsed = {};
    for (const fieldName of keys) {
      if (typeof fieldName !== "string" || fieldName.length === 0) {
        throw new TypeError("schema keys must be non-empty strings.");
      }
      const mapper = schema[fieldName];
      if (!mapper || typeof mapper.mapValue !== "function") {
        throw new TypeError(`schema field ${JSON.stringify(fieldName)} must be a mapper with mapValue().`);
      }
      parsed[fieldName] = mapper;
    }
    return parsed;
  }

  mapValue(value) {
    if (value === null || typeof value !== "object") {
      throw new TypeError("value must be a non-null object.");
    }
    if (Array.isArray(value)) {
      throw new TypeError("value must be a mapping object, not an array.");
    }

    const keys = Object.keys(value);
    if (!this.allowEmpty && keys.length === 0) {
      throw new TypeError("empty map/object input is invalid by default; set allowEmpty=true to map empty objects.");
    }
    if (!this.allowUnknown) {
      for (const key of keys) {
        if (!Object.prototype.hasOwnProperty.call(this.schema, key)) {
          throw new TypeError("object map has unknown fields; set allowUnknown=true to accept extra keys.");
        }
      }
    }

    const mapped = {};
    for (const fieldName of Object.keys(this.schema)) {
      const mapper = this.schema[fieldName];
      if (Object.prototype.hasOwnProperty.call(value, fieldName)) {
        mapped[fieldName] = mapper.mapValue(value[fieldName]);
      } else if (this.hasMissingValue) {
        mapped[fieldName] = this.missingValue;
      } else {
        throw new TypeError(`missing required field ${JSON.stringify(fieldName)} in object input.`);
      }
    }
    return mapped;
  }

  map(value) {
    return this.mapValue(value);
  }

  toDict() {
    const schema = {};
    for (const fieldName of Object.keys(this.schema)) {
      schema[fieldName] = this.schema[fieldName].toDict();
    }

    const spec = {
      spec_version: SPEC_VERSION,
      mapper_type: MAPPER_TYPE_MAP_RANGE,
      schema,
      allow_unknown: this.allowUnknown,
      allow_empty: this.allowEmpty,
    };
    if (this.hasMissingValue) {
      spec.has_missing_value = true;
      spec.missing_value = this.missingValue;
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
    if (data.mapper_type !== MAPPER_TYPE_MAP_RANGE) {
      throw new Error(`unsupported mapper_type ${JSON.stringify(data.mapper_type)}; expected ${JSON.stringify(MAPPER_TYPE_MAP_RANGE)}.`);
    }
    if (!data.schema || typeof data.schema !== "object" || Array.isArray(data.schema)) {
      throw new TypeError("schema must be an object in map spec.");
    }

    const schema = {};
    for (const fieldName of Object.keys(data.schema)) {
      if (typeof fieldName !== "string" || fieldName.length === 0) {
        throw new TypeError("schema field names must be non-empty strings.");
      }
      schema[fieldName] = mapperFromDict(data.schema[fieldName]);
    }

    const hasMissingValue = Boolean(data.has_missing_value);
    return new ObjectRangeMapper(schema, {
      allowUnknown: Boolean(data.allow_unknown),
      allowEmpty: Boolean(data.allow_empty),
      ...(hasMissingValue ? { missingValue: data.missing_value } : {}),
      name: data.name ?? null,
    });
  }

  static fromJSON(text) {
    return ObjectRangeMapper.fromDict(JSON.parse(text));
  }

  static load(path) {
    return ObjectRangeMapper.fromJSON(fs.readFileSync(path, "utf8"));
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

function validateCategoricalToken(value, label) {
  const valueType = typeof value;
  if (value === null) {
    return;
  }
  if (valueType === "string") {
    return;
  }
  if (valueType === "boolean") {
    return;
  }
  if (valueType === "number" && Number.isFinite(value)) {
    return;
  }
  throw new TypeError(`${label} must be a finite number, boolean, string, or null.`);
}

function tokenToString(token) {
  if (token === null) {
    return "null";
  }
  return JSON.stringify(token);
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
  if (mapperType === MAPPER_TYPE_BYTES_RANGE) {
    return BytesRangeMapper.fromDict(data);
  }
  if (mapperType === MAPPER_TYPE_MAP_RANGE) {
    return ObjectRangeMapper.fromDict(data);
  }
  if (mapperType === MAPPER_TYPE_CATEGORICAL_RANGE) {
    return CategoricalRangeMapper.fromDict(data);
  }
  if (mapperType === MAPPER_TYPE_TEMPORAL_RANGE) {
    return TemporalRangeMapper.fromDict(data);
  }
  if (mapperType === MAPPER_TYPE_IMAGE_RANGE) {
    return ImageRangeMapper.fromDict(data);
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
  BytesRangeMapper,
  ObjectRangeMapper,
  SPEC_VERSION,
  MAPPER_TYPE_INTEGER_RANGE,
  MAPPER_TYPE_FLOAT_RANGE,
  MAPPER_TYPE_BOOLEAN_RANGE,
  MAPPER_TYPE_SEQUENCE_RANGE,
  MAPPER_TYPE_TEXT_RANGE,
  MAPPER_TYPE_BYTES_RANGE,
  MAPPER_TYPE_MAP_RANGE,
  MAPPER_TYPE_CATEGORICAL_RANGE,
  MAPPER_TYPE_TEMPORAL_RANGE,
  MAPPER_TYPE_IMAGE_RANGE,
  CategoricalRangeMapper,
  TemporalRangeMapper,
  ImageRangeMapper,
};

function coerceTemporalValue(value) {
  if (value instanceof Date) {
    const timestamp = value.getTime();
    if (!Number.isFinite(timestamp)) {
      throw new TypeError("value must be a valid Date.");
    }
    return timestamp;
  }
  if (typeof value === "number") {
    return requireFiniteNumber(value, "value");
  }
  if (typeof value === "string") {
    const timestamp = Date.parse(value);
    if (!Number.isFinite(timestamp)) {
      throw new TypeError("value must be a valid Date, epoch millisecond number, or ISO-8601 timestamp string.");
    }
    return timestamp;
  }
  throw new TypeError("value must be a Date, epoch millisecond number, or ISO-8601 timestamp string.");
}
