"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  BooleanRangeMapper,
  BytesRangeMapper,
  FloatRangeMapper,
  IntegerRangeMapper,
  CategoricalRangeMapper,
  ObjectRangeMapper,
  ImageRangeMapper,
  TemporalRangeMapper,
  SequenceRangeMapper,
  TextRangeMapper,
  DEFAULT_OUTPUT_RANGE,
} = require("./index");

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

test("maps temporal values deterministically", () => {
  const mapper = new TemporalRangeMapper([0, 1000]);
  assert.equal(mapper.mapValue(new Date(500)), 0.0);
  assert.equal(mapper.mapValue(500), 0.0);
  assert.equal(mapper.mapValue("1970-01-01T00:00:00.500Z"), 0.0);

  const roundTrip = TemporalRangeMapper.fromJSON(mapper.toJSON());
  assert.equal(roundTrip.mapValue(new Date(500)), 0.0);
  assert.equal(mapper.mapValue(new Date(500)), mapper.mapValue(new Date(500)));
  assert.throws(() => mapper.mapValue("not-a-date"), /valid Date/);
});

test("maps image-like nested arrays deterministically", () => {
  const mapper = new ImageRangeMapper();
  const pixels = [[0, 128, 255], [64, 192, 32]];
  const first = mapper.mapValue(pixels);
  const second = mapper.mapValue(pixels);
  assert.deepEqual(first, second);
  assert.deepEqual(first[0], [-1.0, 0.0039215686274509665, 1.0]);
  assert.deepEqual(first[1], [-0.4980392156862745, 0.5058823529411764, -0.7490196078431373]);
  assert.throws(() => mapper.mapValue("not image data"), /image-like values/);
  assert.deepEqual(ImageRangeMapper.fromJSON(mapper.toJSON()).mapValue(pixels), first);
});

test("maps bytes as numeric vectors", () => {
  const mapper = new BytesRangeMapper();
  assert.deepEqual(mapper.mapValue(Buffer.from([0, 127, 255])), [-1.0, 0.0, 1.0]);
  assert.deepEqual(mapper.mapValue([0, 127, 255]), [-1.0, 0.0, 1.0]);
});

test("bytes mapping stays deterministic and rejects strict out-of-range input", () => {
  const mapper = new BytesRangeMapper();
  const first = mapper.mapValue(Buffer.from([0, 127, 255]));
  const second = mapper.mapValue(Buffer.from([0, 127, 255]));
  assert.deepEqual(first, second);
  assert.deepEqual(first, [-1.0, 0.0, 1.0]);
  assert.throws(() => mapper.mapValue([256]), /above input_range upper bound/);
});

test("maps object records via explicit schema", () => {
  const mapper = new ObjectRangeMapper({
    id: new IntegerRangeMapper([0, 10]),
    active: new BooleanRangeMapper(),
    tags: new SequenceRangeMapper(new IntegerRangeMapper([0, 3]), { allowEmpty: true }),
  });
  assert.deepEqual(mapper.mapValue({
    id: 10,
    active: false,
    tags: [0, 3],
  }), {
    id: 1.0,
    active: -1.0,
    tags: [-1.0, 1.0],
  });
});

test("nested object and sequence mapping stays deterministic", () => {
  const mapper = new SequenceRangeMapper(
    new ObjectRangeMapper({
      id: new IntegerRangeMapper([0, 100]),
      tags: new SequenceRangeMapper(
        new CategoricalRangeMapper(["red", "green", "blue"]),
        { allowEmpty: true },
      ),
    }),
  );

  const input = [
    { id: 25, tags: ["red", "green"] },
    { id: 75, tags: ["blue", "green", "red"] },
  ];

  const first = mapper.mapValue(input);
  const second = mapper.mapValue(input);

  assert.deepEqual(first, second);
  assert.deepEqual(first, [
    { id: -0.5, tags: [-1.0, 0.0] },
    { id: 0.5, tags: [1.0, 0.0, -1.0] },
  ]);
});

test("nested object mapping rejects missing nested fields by default", () => {
  const mapper = new ObjectRangeMapper({
    profile: new ObjectRangeMapper({
      id: new IntegerRangeMapper([0, 100]),
      tags: new SequenceRangeMapper(new CategoricalRangeMapper(["red", "green", "blue"]), { allowEmpty: true }),
    }),
    active: new BooleanRangeMapper(),
  });

  assert.throws(
    () => mapper.mapValue({
      profile: { id: 25 },
      active: true,
    }),
    /missing required field/,
  );
});

test("supports empty and missing-value object mapping policies", () => {
  const mapper = new ObjectRangeMapper(
    { value: new FloatRangeMapper([0.0, 10.0]) },
    { allowEmpty: true, missingValue: 0.5 },
  );
  assert.deepEqual(mapper.mapValue({}), { value: 0.5 });
});

test("rejects missing object fields by default", () => {
  const mapper = new ObjectRangeMapper({
    label: new TextRangeMapper([-1.0, 1.0], "alphabet", { alphabet: "abc" }),
  });
  assert.throws(() => mapper.mapValue({}), /missing required field/);
});

test("rejects unknown object fields unless allowUnknown=true", () => {
  const strict = new ObjectRangeMapper({ value: new IntegerRangeMapper([0, 1]) });
  assert.throws(() => strict.mapValue({ value: 0, unknown: 1 }), /object map has unknown fields/);
});

test("allows unknown object fields when allowUnknown=true", () => {
  const lenient = new ObjectRangeMapper({ value: new IntegerRangeMapper([0, 1]) }, { allowUnknown: true });
  assert.deepEqual(lenient.mapValue({ value: 1, unknown: "skip" }), { value: 1.0 });
});

test("maps empty bytes only when enabled", () => {
  const strict = new BytesRangeMapper(DEFAULT_OUTPUT_RANGE, false, false);
  assert.throws(() => strict.mapValue(Buffer.from([])), /empty bytes value is invalid/);
  const lenient = new BytesRangeMapper(DEFAULT_OUTPUT_RANGE, false, true);
  assert.deepEqual(lenient.mapValue(Uint8Array.from([])), []);
});

test("rejects invalid bytes in strict mode", () => {
  const mapper = new BytesRangeMapper();
  assert.throws(() => mapper.mapValue([256]), /above input_range upper bound/);
});

test("clips out-of-range bytes when clip=true", () => {
  const mapper = new BytesRangeMapper(DEFAULT_OUTPUT_RANGE, true, true);
  assert.deepEqual(mapper.mapValue([-1, 300]), [-1.0, 1.0]);
});

test("rejects typed array values and wrong container types", () => {
  const mapper = new BytesRangeMapper();
  assert.throws(() => mapper.mapValue("not bytes"), /must be Buffer, Uint8Array/);
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

test("round trips bytes JSON specs", () => {
  const mapper = new BytesRangeMapper(DEFAULT_OUTPUT_RANGE, true, true, "bytes");
  const text = mapper.toJSON();
  const restored = BytesRangeMapper.fromJSON(text);
  assert.deepEqual(restored.mapValue([0, 1]), [-1.0, -0.9921568627450981]);
  assert.equal(restored.name, "bytes");
});

test("maps categorical tokens via vocabulary", () => {
  const mapper = new CategoricalRangeMapper(["cat", "dog", "fox"], [-1.0, 1.0]);
  assert.equal(mapper.mapValue("cat"), -1.0);
  assert.equal(mapper.mapValue("dog"), 0.0);
  assert.equal(mapper.mapValue("fox"), 1.0);
});

test("maps singleton categorical vocabularies to lower bound", () => {
  const mapper = new CategoricalRangeMapper([42], [0.0, 4.0]);
  assert.equal(mapper.mapValue(42), 0.0);
});

test("rejects unknown categorical tokens", () => {
  const mapper = new CategoricalRangeMapper(["cat", "dog"]);
  assert.throws(() => mapper.mapValue("fox"), /unknown token/);
});

test("rejects duplicate categorical vocabulary tokens", () => {
  assert.throws(() => new CategoricalRangeMapper(["cat", "cat"]), /duplicate token/);
});

test("rejects empty categorical vocabularies", () => {
  assert.throws(() => new CategoricalRangeMapper([]), /vocabulary must be non-empty/);
});

test("round trips categorical JSON specs", () => {
  const mapper = new CategoricalRangeMapper(["cat", "dog", "fox"], [-1.0, 1.0], "labels");
  const text = mapper.toJSON();
  const restored = CategoricalRangeMapper.fromJSON(text);
  assert.equal(restored.mapValue("dog"), 0.0);
  assert.equal(restored.name, "labels");
});

test("round trips object map JSON specs", () => {
  const mapper = new ObjectRangeMapper(
    { value: new FloatRangeMapper([0.0, 1.0], [-1.0, 1.0], false) },
    { allowEmpty: true, missingValue: 0.5, name: "obj" },
  );
  const text = mapper.toJSON();
  const restored = ObjectRangeMapper.fromJSON(text);
  assert.deepEqual(restored.mapValue({ value: 0.25 }), { value: -0.5 });
  assert.deepEqual(restored.mapValue({}), { value: 0.5 });
  assert.equal(restored.name, "obj");
});

test("round trips nested map-sequence-categorical JSON specs", () => {
  const mapper = new ObjectRangeMapper(
    {
      profile: new ObjectRangeMapper(
        {
          age: new IntegerRangeMapper([0, 100]),
          tags: new SequenceRangeMapper(
            new CategoricalRangeMapper(["red", "green", "blue"]),
            { allowEmpty: true },
          ),
        },
        { allowEmpty: false },
      ),
      active: new BooleanRangeMapper(),
    },
    { allowUnknown: true, name: "nested-profile" },
  );

  const text = mapper.toJSON();
  const restored = ObjectRangeMapper.fromJSON(text);
  const sample = {
    profile: {
      age: 25,
      tags: ["red", "green"],
    },
    active: true,
  };

  const first = mapper.mapValue(sample);
  const second = restored.mapValue(sample);

  assert.deepEqual(first, second);
  assert.deepEqual(first, {
    profile: {
      age: -0.5,
      tags: [-1.0, 0.0],
    },
    active: 1.0,
  });
  assert.equal(restored.name, "nested-profile");
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
