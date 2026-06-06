"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const { IntegerRangeMapper } = require("./index");

test("maps the canonical integer cases", () => {
  const mapper = new IntegerRangeMapper([0, 100]);
  assert.equal(mapper.mapValue(0), -1.0);
  assert.equal(mapper.mapValue(50), 0.0);
  assert.equal(mapper.mapValue(100), 1.0);
});

test("supports clipping", () => {
  const mapper = new IntegerRangeMapper([0, 10], [-1.0, 1.0], true);
  assert.equal(mapper.mapValue(-5), -1.0);
  assert.equal(mapper.mapValue(15), 1.0);
});

test("rejects out of range values in strict mode", () => {
  const mapper = new IntegerRangeMapper([0, 10]);
  assert.throws(() => mapper.mapValue(11), /above input_range upper bound/);
});

test("round trips JSON specs", () => {
  const mapper = new IntegerRangeMapper([-10, 10], [-1.0, 1.0], true, "sample");
  const text = mapper.toJSON();
  const restored = IntegerRangeMapper.fromJSON(text);
  assert.equal(restored.mapValue(-10), -1.0);
  assert.equal(restored.name, "sample");
});

test("save and load spec files", () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "librangemap-js-"));
  const filePath = path.join(tmpDir, "mapper.json");
  const mapper = new IntegerRangeMapper([0, 4], [-1.0, 1.0], false);
  mapper.save(filePath);
  const restored = IntegerRangeMapper.load(filePath);
  assert.equal(restored.mapValue(2), 0.0);
});
