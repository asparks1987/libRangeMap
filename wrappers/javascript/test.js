"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const { BooleanRangeMapper, FloatRangeMapper, IntegerRangeMapper, TextRangeMapper } = require("./index");
const { SequenceRangeMapper } = require("./index");

test("maps the canonical integer cases", () => {
  const mapper = new IntegerRangeMapper([0, 100]);
  assert.equal(mapper.mapValue(0), -1.0);
  assert.equal(mapper.mapValue(50), 0.0);
  assert.equal(mapper.mapValue(100), 1.0);
});

test("maps float values", () => {
  const mapper = new FloatRangeMapper([0.0, 100.0]);
  assert.equal(mapper.mapValue(0.0), -1.0);
  assert.equal(mapper.mapValue(50.0), 0.0);
  assert.equal(mapper.mapValue(100.0), 1.0);
});

test("supports float clipping", () => {
  const mapper = new FloatRangeMapper([0.0, 10.0], [-1.0, 1.0], true);
  assert.equal(mapper.mapValue(-5.0), -1.0);
  assert.equal(mapper.mapValue(15.0), 1.0);
});

test("rejects boolean as float value", () => {
  const mapper = new FloatRangeMapper([0.0, 1.0]);
  assert.throws(() => mapper.mapValue(true), /must be a finite number/);
});

test("maps booleans", () => {
  const mapper = new BooleanRangeMapper();
  assert.equal(mapper.mapValue(false), -1.0);
  assert.equal(mapper.mapValue(true), 1.0);
});

test("maps booleans with explicit policy", () => {
  const mapper = new BooleanRangeMapper([-1.0, 2.0], 0.1, 1.9);
  assert.equal(mapper.mapValue(false), 0.1);
  assert.equal(mapper.mapValue(true), 1.9);
});

test("maps text as codepoints", () => {
  const mapper = new TextRangeMapper([-1.0, 1.0], "codepoint", { allowEmpty: true });
  const mapped = mapper.mapValue("A");
  assert.equal(mapped.length, 1);
  assert.equal(mapped[0], -1.0 + ((65 / 0x10ffff) * 2));
});

test("maps text with custom alphabet", () => {
  const mapper = new TextRangeMapper([-1.0, 1.0], "alphabet", { alphabet: "abc", allowEmpty: true });
  const mapped = mapper.mapValue("cab");
  assert.deepEqual(mapped, [1.0, -1.0, 0.0]);
});

test("boolean mapping rejects non-boolean values", () => {
  const mapper = new BooleanRangeMapper();
  assert.throws(() => mapper.mapValue(1), /must be a boolean/);
});

test("maps nested sequences", () => {
  const intMapper = new IntegerRangeMapper([0, 100]);
  const seqMapper = new SequenceRangeMapper(intMapper);
  assert.deepEqual(
    seqMapper.mapValue([0, [25, 50, [75, 100]]]),
    [-1.0, [-0.5, 0.0, [0.5, 1.0]]],
  );
});

test("rejects empty sequence by default", () => {
  const seqMapper = new SequenceRangeMapper(new IntegerRangeMapper([0, 10]));
  assert.throws(() => seqMapper.mapValue([]), /empty sequence is invalid/);
});

test("allows explicit empty sequences", () => {
  const seqMapper = new SequenceRangeMapper(new IntegerRangeMapper([0, 10]), { allowEmpty: true });
  assert.deepEqual(seqMapper.mapValue([]), []);
});

test("rejects unknown element type in sequence", () => {
  const seqMapper = new SequenceRangeMapper(new FloatRangeMapper([0.0, 1.0]));
  assert.throws(() => seqMapper.mapValue([0.5, "oops"]), /must be a finite number/);
});

test("round trips sequence JSON specs", () => {
  const seqMapper = new SequenceRangeMapper(new IntegerRangeMapper([0, 10]), { allowEmpty: true, name: "nested" });
  const text = seqMapper.toJSON();
  const restored = SequenceRangeMapper.fromJSON(text);
  assert.deepEqual(restored.mapValue([]), []);
  assert.equal(restored.name, "nested");
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

test("round trips float JSON specs", () => {
  const mapper = new FloatRangeMapper([0.0, 10.0], [-1.0, 1.0], true);
  const text = mapper.toJSON();
  const restored = FloatRangeMapper.fromJSON(text);
  assert.equal(restored.mapValue(10.0), 1.0);
});

test("round trips boolean JSON specs", () => {
  const mapper = new BooleanRangeMapper([-1.0, 2.0], 0.2, 1.8, "flag");
  const text = mapper.toJSON();
  const restored = BooleanRangeMapper.fromJSON(text);
  assert.equal(restored.mapValue(true), 1.8);
  assert.equal(restored.name, "flag");
});

test("round trips text JSON specs", () => {
  const mapper = new TextRangeMapper([-1.0, 1.0], "alphabet", {
    alphabet: "abc",
    allowEmpty: true,
    name: "labels",
  });
  const text = mapper.toJSON();
  const restored = TextRangeMapper.fromJSON(text);
  assert.deepEqual(restored.mapValue("ab"), [-1.0, 0.0]);
  assert.equal(restored.name, "labels");
});

test("rejects unknown alphabet characters", () => {
  const mapper = new TextRangeMapper([-1.0, 1.0], "alphabet", { alphabet: "abc" });
  assert.throws(() => mapper.mapValue("d"), /unknown character/);
});

test("save and load spec files", () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "librangemap-js-"));
  const filePath = path.join(tmpDir, "mapper.json");
  const mapper = new IntegerRangeMapper([0, 4], [-1.0, 1.0], false);
  mapper.save(filePath);
  const restored = IntegerRangeMapper.load(filePath);
  assert.equal(restored.mapValue(2), 0.0);
});
