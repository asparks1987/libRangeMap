"use strict";

const fs = require("node:fs");

const SPEC_VERSION = "1.0-alpha";
const MAPPER_TYPE_INTEGER_RANGE = "integer_range";
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

function linearMap(value, inMin, inMax, outMin, outMax) {
  return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
}

module.exports = {
  DEFAULT_OUTPUT_RANGE,
  IntegerRangeMapper,
  SPEC_VERSION,
};
