# libRangeMap V1 Alpha / V1 Beta Burndown

Last refreshed: 2026-06-06

This file is the delivery source of truth for turning `libRangeMap` into a first-party, dependency-free, language-agnostic range-mapping SDK for AI dataset preparation and data normalization.

`AGENTS.md` defines standing repository behavior. This `burndown.md` defines the mission, phases, acceptance criteria, and release gates.

---

## Codex Roleplaying Scenario

Codex must operate as if it is the world's best developer in the field of AI data tooling, normalization SDKs, and cross-language library design.

In this role, Codex is responsible for turning `libRangeMap` from an early personal experiment into a clean, auditable, first-party SDK that serious AI developers can trust.

Codex should think like:

- a principal AI infrastructure engineer,
- a numerical correctness specialist,
- a language-agnostic SDK architect,
- an open-source maintainer,
- a dependency-minimalist,
- a documentation-first educator,
- and a careful release engineer.

Codex should not behave like a hackathon prototype generator. It must not chase novelty, add unnecessary dependencies, copy outside code, or overbuild speculative systems before the alpha core is correct.

The guiding mindset:

> Build the smallest correct core first. Make it deterministic, dependency-free, documented, tested, serializable, and easy to port to any language. Then expand input types through explicit mapper contracts.

---

## Project Vision

`libRangeMap` is a 100% first-party, dependency-free SDK for converting values into normalized floating-point representations for AI dataset preparation, feature normalization, training-data collection, embedded AI tooling, and cross-language data pipelines.

The core idea:

> Any supported input value can be deterministically mapped from a declared input range or mapping policy into a floating-point value in the range `[-1.0, 1.0]`.

The long-term idea:

> `libRangeMap` becomes agnostic of programming language and agnostic of input type by defining a universal range-mapping specification, then providing first-party implementations and adapter contracts for many languages and data shapes.

---

## Non-Negotiable Rules

These rules override implementation convenience.

### First-Party Rule

- Do not copy, paste, port, vendor, adapt, or borrow source code from another repository or third-party library.
- All implementation logic must be original to this project.
- Do not import third-party runtime packages.
- Do not add hidden runtime dependencies.
- Do not require users to install anything beyond the target language/runtime to use the core SDK.

### Dependency-Free Core Rule

The core SDK must not depend on:

- NumPy
- Pillow
- pandas
- PyTorch
- TensorFlow
- scikit-learn
- OpenCV
- requests
- pydantic
- click
- typer
- rich
- pytest
- ruff
- mypy
- setuptools at runtime
- or any other third-party runtime package

Development tooling may be discussed later, but the default alpha path should use standard-library tooling where possible.

### Offline / Local Rule

- No telemetry.
- No analytics.
- No tracking.
- No remote uploads.
- No network calls.
- No model downloads.
- No automatic update checks.
- No private-data logging.

### Numerical Correctness Rule

- The default output range is `[-1.0, 1.0]`.
- `[0.0, 1.0]` may be supported only when explicitly configured.
- The same input plus the same mapping spec must always produce the same output.
- Lower bound maps to `-1.0`.
- Upper bound maps to `1.0`.
- Midpoint maps to `0.0` where mathematically exact.
- Invalid input must fail clearly; it must not produce magic values.

### Release Honesty Rule

- Do not claim alpha or beta readiness until the release gate passes.
- Mark uncertain current repo behavior as `VERIFY`, not `DONE`.
- If a task cannot be run locally, document why and continue with static-verifiable work.
- Every phase report must include changed files, tests/commands run, results, blockers, and readiness percentage.

---

## Canonical Mapping Formula

The generic linear mapping formula is:

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```

Default output range:

```text
out_min = -1.0
out_max = 1.0
```

Required alpha examples:

```text
0 in [0, 100]       -> -1.0
50 in [0, 100]      ->  0.0
100 in [0, 100]     ->  1.0

-10 in [-10, 10]    -> -1.0
0 in [-10, 10]      ->  0.0
10 in [-10, 10]     ->  1.0

5 in [5, 15]        -> -1.0
10 in [5, 15]       ->  0.0
15 in [5, 15]       ->  1.0
```

---

## Current Repo Snapshot

STATUS: ACTIVE  
PRIORITY: CRITICAL

Known current state to verify in the local checkout:

- The public repo currently presents `libRangeMap` as a small mixed C++/Python project.
- The README currently describes a C++ library that maps numeric and character values.
- Current examples use `[0.0, 1.0]` as the output range.
- Current Python source appears to expose `RangeMapper` and `CharRangeMapper`.
- Current Python default output range appears to be `[0.0, 1.0]`.
- Current Python character mapping uses alphabet position and an unknown fallback value.
- Current C++ header appears to default to `[0.0f, 1.0f]`.
- Generated-looking folders such as `dist/` and `libRangeMap.egg-info/` appear in the repo.
- `setup.py` appears to declare package metadata and must be audited for dependency correctness.
- There are no visible published releases at the time this plan was written.

Codex must inspect the actual checkout before editing. If the local repo differs from this snapshot, update this burndown with the verified local state.

---

## Status Legend

- `DONE`: implemented and verified.
- `IN_PROGRESS`: partially implemented; remaining work is known.
- `PENDING`: not started or only planned.
- `BLOCKED`: waiting on a required decision, tool, environment, or external action.
- `DEFERRED`: intentionally outside the current release.
- `VERIFY`: may exist, but must be audited and tested before it can count.

---

## V1 Alpha Ship Definition

`libRangeMap` reaches **V1 Alpha** when it has a language-agnostic specification and a clean first-party reference implementation that can convert any finite integer within a declared integer range into a float between `-1.0` and `1.0`.

Alpha is intentionally narrow. It proves the core idea correctly before expanding to many input types.

### V1 Alpha User Journey

A fresh developer can:

1. Clone the repo.
2. Read the spec and README.
3. Install or import the SDK without third-party dependencies.
4. Create an integer range mapper.
5. Map finite integers from a declared integer range into `[-1.0, 1.0]`.
6. Choose strict or clipping out-of-range behavior.
7. Save/export the mapping spec.
8. Reload the mapping spec.
9. Reproduce the same mapping results.
10. Run the alpha compliance tests.
11. Understand what is alpha, what is beta, and what is deferred.

### Minimum Alpha Entry Gate

Alpha v1 is not ready until:

- [ ] Default output range is `[-1.0, 1.0]`.
- [ ] Integer mapper is implemented and tested.
- [ ] Positive, negative, mixed, non-zero, and large integer ranges work.
- [ ] Strict and clipping modes work.
- [ ] Invalid ranges fail clearly.
- [ ] Non-integer inputs fail clearly in integer mode.
- [ ] Boolean input is rejected by default.
- [ ] NaN and infinity are rejected where relevant.
- [ ] Mapping specs can serialize and reload using standard-library JSON.
- [ ] The SDK imports without third-party runtime dependencies.
- [ ] Documentation explains the formula and examples.
- [ ] Generated artifacts are not treated as source.
- [ ] The release gate passes from a clean checkout.

### Alpha Is Not

Alpha is not:

- arbitrary data-type mapping,
- image decoding,
- natural language understanding,
- semantic encoding,
- NumPy/Pillow/pandas/PyTorch integration,
- automatic schema discovery,
- multi-language package support,
- or a full dataset platform.

Those are beta/post-beta expansion areas.

---

## V1 Beta Readiness Definition

`libRangeMap` reaches **V1 Beta** when it is an importable SDK that can map all supported built-in data categories and user-defined data types through explicit mapper, schema, or adapter contracts.

The beta claim must be precise:

> Beta does not magically understand every object in existence. Beta provides a universal mapping contract so any data type can be mapped once a mapper, schema, adapter, or range policy is declared.

### V1 Beta Minimum Gate

A developer can:

1. Import the SDK into a project.
2. Map integers, floats, booleans, characters, strings, bytes, sequences, nested sequences, and schema-described custom objects.
3. Register a first-party custom mapper for a new type.
4. Serialize and reload mapper specs.
5. Validate mappings.
6. Inverse-map where mathematically safe.
7. Build simple dataset-normalization pipelines without third-party dependencies.
8. Use the same mapping rules across supported language implementations.
9. Run compliance fixtures proving stable behavior.

---

## Readiness Scoring

### V1 Alpha Readiness

- 10% repo hygiene and dependency audit.
- 10% canon/spec lock.
- 25% integer mapper implementation.
- 15% error handling and validation.
- 10% serialization/reproducibility.
- 15% correctness tests.
- 10% docs/examples.
- 5% package/import validation.

### V1 Beta Readiness

- 10% stable alpha core.
- 10% mapper/adapter architecture.
- 10% numeric type expansion.
- 10% character/text expansion.
- 10% sequence/nested data expansion.
- 10% bytes/buffer expansion.
- 10% raw pixel/image-like expansion.
- 10% custom object/schema expansion.
- 10% serialization/compliance fixtures.
- 10% docs, examples, packaging, and release validation.

Readiness percentages must be based on completed checklist items, not vibes.

---

## Codex Execution Plan

Codex must work in small, reviewable phases.

### Step 0 — Start With Context

1. Read `AGENTS.md`.
2. Read `burndown.md`.
3. Inspect the repo tree.
4. Identify current files, generated artifacts, package metadata, tests, docs, and examples.
5. Summarize current state before editing.

### Step 1 — Protect The Project Rules

1. Confirm no third-party runtime dependency is needed.
2. Confirm no copied external source is being introduced.
3. Confirm all proposed tests can run with the standard library.
4. Confirm generated artifacts will not be committed as source.

### Step 2 — Lock The Spec

1. Add or update `docs/spec.md`.
2. Define terminology.
3. Define formula.
4. Define integer alpha behavior.
5. Define strict/clipping behavior.
6. Define serialization format.
7. Define compliance tests.

### Step 3 — Clean Package Shape

1. Create or normalize `librangemap/`.
2. Add stable package entry points.
3. Preserve old names only as compatibility shims if practical.
4. Ensure imports work from source and install.
5. Do not require `dist/` or generated files.

### Step 4 — Implement Alpha Integer Mapping

1. Implement `IntegerRangeMapper` or equivalent.
2. Implement `map_value`.
3. Implement `transform` for one value and simple sequences if in alpha scope.
4. Implement range validation.
5. Implement strict/clipping behavior.
6. Implement serialization and reload.
7. Add custom exceptions.

### Step 5 — Test The Heartbeat

1. Use `python -m unittest discover`.
2. Add tests for lower/upper/midpoint.
3. Add tests for negative/mixed/non-zero/large ranges.
4. Add tests for invalid inputs.
5. Add tests for serialization.
6. Add tests for dependency-free import.

### Step 6 — Document User Journey

1. Rewrite README around the new alpha goal.
2. Add examples.
3. Add migration notes from `[0, 1]` to `[-1, 1]`.
4. Explain no dependencies.
5. Explain beta roadmap.

### Step 7 — Validate Release Gate

1. Run tests.
2. Install locally.
3. Import package.
4. Run examples.
5. Check generated artifacts remain ignored.
6. Report readiness percentage and blockers.

### Step 8 — Continue To Beta

Only after alpha passes:

1. Add mapper interface.
2. Add adapter registry.
3. Add float mapper.
4. Add char/string mappers.
5. Add bytes/buffer mappers.
6. Add sequence/nested mappers.
7. Add raw pixel data structures.
8. Add custom object schemas.
9. Add language-neutral compliance fixtures.
10. Add additional first-party language implementations when ready.

---

# Critical Path Order

Work these in order unless a blocker forces a lower task first.

1. `LRM-000` Canon lock and scope.
2. `LRM-010` Repo hygiene and dependency audit.
3. `LRM-020` Language-agnostic range-mapping spec.
4. `LRM-030` Core integer mapper.
5. `LRM-040` Error handling and validation.
6. `LRM-050` Serialization and reproducibility.
7. `LRM-060` Python reference implementation.
8. `LRM-070` C++ reference implementation or legacy decision.
9. `LRM-080` Tests and correctness gate.
10. `LRM-090` Documentation and examples.
11. `LRM-100` Packaging and import validation.
12. `LRM-110` Alpha release gate.
13. `LRM-120` Beta roadmap foundation.
14. `LRM-130` Beta type expansion.
15. `LRM-140` Cross-language SDK expansion.
16. `LRM-150` Open-source project quality.
17. `LRM-160` Beta release gate.

---

# LRM-000 — Canon Lock And Scope

STATUS: PENDING  
PRIORITY: CRITICAL

## Goal

Lock the identity and scope of `libRangeMap` before implementation expands.

## Tasks For Codex

1. Read current README.
2. Read current Python and C++ files.
3. Summarize current behavior.
4. Identify behavior that conflicts with the new canon.
5. Update project docs so the new canon is explicit.
6. Mark old behavior as legacy where needed.

## Requirements

- [ ] Define `libRangeMap` as a first-party dependency-free SDK.
- [ ] Define default output range as `[-1.0, 1.0]`.
- [ ] Define Alpha v1 as integer-range mapping only.
- [ ] Define Beta v1 as multi-type mapping through built-in and custom adapters.
- [ ] Define language agnosticism as a spec-first contract.
- [ ] Define input-type agnosticism as extensible mapper contracts.
- [ ] Declare no third-party runtime dependencies.
- [ ] Declare no copied third-party source.
- [ ] Decide package name casing:
  - `libRangeMap`
  - `librangemap`
  - `lib_rangemap`
- [ ] Decide canonical Python import style.
- [ ] Decide whether C++ remains supported in alpha or becomes legacy until beta.

## Acceptance Criteria

Any contributor can read the README/spec and understand what Alpha v1 must ship.

---

# LRM-010 — Repo Hygiene And Dependency Audit

STATUS: PENDING  
PRIORITY: CRITICAL

## Goal

Clean the repo so it is source-only, dependency-free, and safe for open-source development.

## Tasks For Codex

1. List all tracked files.
2. Identify generated artifacts.
3. Inspect package metadata.
4. Inspect import paths.
5. Inspect license files.
6. Inspect dependencies.
7. Propose cleanup as a separate focused change.

## Requirements

- [ ] Audit every tracked file.
- [ ] Identify generated artifacts.
- [ ] Remove `dist/` from source control.
- [ ] Remove `build/` if present.
- [ ] Remove `*.egg-info/` from source control.
- [ ] Add or update `.gitignore`.
- [ ] Confirm no private data exists in repo.
- [ ] Confirm no external source code was copied into repo.
- [ ] Confirm no runtime dependencies are declared.
- [ ] Fix `setup.py` dependency metadata so it does not declare empty or bogus dependencies.
- [ ] Add `pyproject.toml` or document why legacy packaging remains.
- [ ] Add or verify license file.
- [ ] Add `AGENTS.md`.
- [ ] Add `CHANGELOG.md`.
- [ ] Add `SECURITY.md` if desired.
- [ ] Add `CONTRIBUTING.md` when outside contributors are expected.

## Acceptance Criteria

The repo contains source, tests, docs, and examples only. Generated package artifacts are ignored and not treated as source.

---

# LRM-020 — Language-Agnostic Range-Mapping Specification

STATUS: PENDING  
PRIORITY: CRITICAL

## Goal

Create a spec that can be implemented in any language.

## Tasks For Codex

1. Create `docs/spec.md`.
2. Write the language-neutral formula.
3. Define alpha integer mapping.
4. Define strict/clipping behavior.
5. Define serialization.
6. Define compliance tests.
7. Keep the spec independent of Python implementation details.

## Required Spec Sections

- [ ] Project purpose.
- [ ] Core terms:
  - value
  - input range
  - output range
  - mapper
  - mapping spec
  - transform
  - inverse transform
  - clipping
  - strict mode
  - finite numeric value
- [ ] Canonical formula.
- [ ] Default output range.
- [ ] Integer mapping behavior.
- [ ] Floating-point precision expectations.
- [ ] Handling of out-of-range values.
- [ ] Handling of invalid ranges.
- [ ] Handling of equal min/max.
- [ ] Handling of reversed ranges.
- [ ] Handling of NaN and infinity.
- [ ] Serialization format.
- [ ] Versioning format.
- [ ] Required compliance tests.
- [ ] Definition of a conforming implementation.
- [ ] Rules for future type adapters.

## Alpha Spec Decisions

- [ ] `in_min < in_max` is required for Alpha.
- [ ] `out_min < out_max` is required for Alpha.
- [ ] Default `out_min = -1.0`.
- [ ] Default `out_max = 1.0`.
- [ ] Values below input range:
  - clip if `clip=True`.
  - raise if `clip=False`.
- [ ] Values above input range:
  - clip if `clip=True`.
  - raise if `clip=False`.
- [ ] Input values must be finite integers for Alpha.
- [ ] Output must be a float.
- [ ] Midpoint should map to approximately zero.
- [ ] No hidden global state.

## Acceptance Criteria

A developer can implement a compatible `libRangeMap` in another language using only the spec.

---

# LRM-030 — Core Integer Mapper

STATUS: PENDING  
PRIORITY: CRITICAL

## Goal

Implement the Alpha v1 MVP: convert any finite integer from a declared integer range into a float in `[-1.0, 1.0]`.

## Tasks For Codex

1. Design the API before editing.
2. Implement the smallest correct integer mapper.
3. Add validation before mapping.
4. Add strict and clipping modes.
5. Add compatibility alias only if safe.
6. Add tests immediately.

## Requirements

- [ ] Add `IntegerRangeMapper` or make `RangeMapper` explicitly support integer mode.
- [ ] Constructor accepts:
  - `input_range`
  - optional `output_range`
  - `clip`
  - optional mapper id/name
- [ ] Default output range is `[-1.0, 1.0]`.
- [ ] Input range supports:
  - positive ranges
  - zero-based ranges
  - negative ranges
  - mixed negative-to-positive ranges
  - non-zero positive ranges
  - large integer ranges
- [ ] Return type is float.
- [ ] Lower input bound maps to `-1.0`.
- [ ] Upper input bound maps to `1.0`.
- [ ] Exact midpoint maps to `0.0` where mathematically exact.
- [ ] Non-exact midpoint maps within documented tolerance.
- [ ] Values below range clip or raise based on config.
- [ ] Values above range clip or raise based on config.
- [ ] Equal input min/max raises clear error.
- [ ] Reversed range raises clear error.
- [ ] Non-integer input in integer mapper raises clear error.
- [ ] Boolean input is rejected by default even though Python bool is a subclass of int.
- [ ] Optional explicit bool support is deferred.

## Acceptance Criteria

The integer mapper passes all alpha compliance tests and is suitable as the first stable SDK primitive.

---

# LRM-040 — Error Handling And Validation

STATUS: PENDING  
PRIORITY: HIGH

## Goal

Make failures safe, clear, and consistent across languages.

## Tasks For Codex

1. Add custom exception types.
2. Replace generic errors in new code with meaningful exceptions.
3. Add tests for each failure path.
4. Ensure error messages explain the fix.

## Required Exceptions / Error Types

- [ ] `RangeMapError`
- [ ] `InvalidRangeError`
- [ ] `OutOfRangeError`
- [ ] `UnsupportedTypeError`
- [ ] `NotFiniteError`
- [ ] `SerializationError`
- [ ] `NotFittedError`, deferred until fitted mappers exist.

## Validation Tasks

- [ ] Validate input range shape.
- [ ] Validate input range values are integers for alpha.
- [ ] Validate output range shape.
- [ ] Validate output range values are finite floats/ints.
- [ ] Validate output range is ordered.
- [ ] Validate input value type.
- [ ] Validate input value finite-ness.
- [ ] Validate clip mode.
- [ ] Validate mapper metadata.
- [ ] Ensure exception messages explain how to fix the issue.

## Acceptance Criteria

Invalid input never produces silent nonsense.

---

# LRM-050 — Serialization And Reproducibility

STATUS: PENDING  
PRIORITY: HIGH

## Goal

Make mapping specs saveable, loadable, auditable, and reproducible.

## Tasks For Codex

1. Implement dict serialization.
2. Implement JSON serialization using the standard library.
3. Implement file save/load.
4. Add round-trip tests.
5. Document the spec.

## Requirements

- [ ] Add `to_dict`.
- [ ] Add `from_dict`.
- [ ] Add `to_json`.
- [ ] Add `from_json`.
- [ ] Add `save`.
- [ ] Add `load`.
- [ ] Include mapper type.
- [ ] Include spec version.
- [ ] Include input range.
- [ ] Include output range.
- [ ] Include clip mode.
- [ ] Include strictness settings.
- [ ] Include optional name/id.
- [ ] Include implementation version.
- [ ] Do not store raw user datasets.
- [ ] JSON uses only standard library.
- [ ] Serialized specs are stable enough for tests.

## Example Metadata

```json
{
  "spec_version": "1.0-alpha",
  "mapper_type": "integer_range",
  "input_range": [0, 100],
  "output_range": [-1.0, 1.0],
  "clip": true
}
```

## Acceptance Criteria

A mapper can be saved, reloaded, and produce the same output for the same input.

---

# LRM-060 — Python Reference Implementation

STATUS: IN_PROGRESS  
PRIORITY: CRITICAL

## Goal

Turn the current Python experiment into a clean dependency-free reference implementation.

## Tasks For Codex

1. Create a package directory if missing.
2. Move new implementation into clear modules.
3. Keep compatibility shims where safe.
4. Add tests before deleting old behavior.
5. Do not require third-party packages.

## Requirements

- [ ] Create package directory:
  - `librangemap/`
- [ ] Add `librangemap/__init__.py`.
- [ ] Add `librangemap/core.py`.
- [ ] Add `librangemap/errors.py`.
- [ ] Add `librangemap/spec.py`.
- [ ] Add `librangemap/integer.py`.
- [ ] Add `librangemap/serialization.py`.
- [ ] Move old `libRangeMap.py` behavior behind compatibility wrapper or deprecate it.
- [ ] Default output range changes to `[-1.0, 1.0]`.
- [ ] Keep dependency-free standard-library-only code.
- [ ] Add type hints using standard syntax only.
- [ ] Add docstrings.
- [ ] Add `__all__`.
- [ ] Add package version.
- [ ] Add compatibility notes for old API.
- [ ] Avoid public method name `map` unless kept as alias.
- [ ] Prefer `map_value` and `transform`.

## Backward Compatibility Tasks

- [ ] Decide whether `RangeMapper.map()` remains as alias.
- [ ] If kept, test it.
- [ ] If deprecated, document migration.
- [ ] Document output default change from `[0, 1]` to `[-1, 1]`.

## Acceptance Criteria

Python implementation is clean, importable, tested, dependency-free, and aligned with the spec.

---

# LRM-070 — C++ Reference Implementation Or Legacy Decision

STATUS: VERIFY  
PRIORITY: MEDIUM

## Goal

Decide whether C++ is a first-class alpha target or legacy source.

## Option A — C++ Supported In Alpha

Requirements:

- [ ] Update `librangemap.h` to match alpha spec.
- [ ] Default output range becomes `[-1.0f, 1.0f]`.
- [ ] Correct numeric formula for non-zero lower bounds.
- [ ] Add integer-specific tests or examples.
- [ ] Add clear C++ usage docs.
- [ ] Ensure no third-party dependencies.
- [ ] Ensure C++ behavior matches Python compliance tests conceptually.

## Option B — C++ Marked Legacy Until Beta

Requirements:

- [ ] Move current header to `legacy/` or document it as experimental.
- [ ] Keep repo focused on spec plus Python reference for alpha.
- [ ] Create a C++ beta milestone.
- [ ] Avoid claiming C++ alpha support.

## Acceptance Criteria

The repo does not pretend unsupported C++ behavior is production-ready.

---

# LRM-080 — Alpha Correctness Test Gate

STATUS: PENDING  
PRIORITY: CRITICAL

## Goal

Prove integer range mapping is correct.

## Testing Rules

Use only standard-library test tools unless the user explicitly approves a third-party test framework.

Default:

```bash
python -m unittest discover
```

## Tasks For Codex

1. Add `tests/`.
2. Use `unittest`.
3. Add one test file per behavior group.
4. Add positive and negative cases.
5. Ensure tests run from clean checkout.

## Required Tests

- [ ] Import package with no third-party dependencies.
- [ ] Map lower bound to `-1.0`.
- [ ] Map upper bound to `1.0`.
- [ ] Map midpoint to `0.0`.
- [ ] Map zero-based range `[0, 100]`.
- [ ] Map non-zero range `[5, 15]`.
- [ ] Map negative range `[-100, -50]`.
- [ ] Map mixed range `[-10, 10]`.
- [ ] Map large integer range.
- [ ] Reject equal input range.
- [ ] Reject reversed input range.
- [ ] Reject non-integer input for integer mapper.
- [ ] Reject bool by default.
- [ ] Reject NaN.
- [ ] Reject infinity.
- [ ] Clip below lower bound when `clip=True`.
- [ ] Clip above upper bound when `clip=True`.
- [ ] Raise below lower bound when `clip=False`.
- [ ] Raise above upper bound when `clip=False`.
- [ ] Serialize mapper to dict.
- [ ] Reload mapper from dict.
- [ ] Serialize mapper to JSON.
- [ ] Reload mapper from JSON.
- [ ] Save mapper to file.
- [ ] Load mapper from file.
- [ ] Preserve same output after reload.
- [ ] Old compatibility alias works or documented deprecation path exists.
- [ ] No generated artifacts required for tests.

## Acceptance Criteria

All alpha tests pass from a clean checkout using only the standard library.

---

# LRM-090 — Documentation And Examples

STATUS: PENDING  
PRIORITY: CRITICAL

## Goal

Make the project understandable to external users.

## Tasks For Codex

1. Rewrite README around the new vision.
2. Add spec docs.
3. Add quickstart docs.
4. Add examples.
5. Add alpha limitations and beta roadmap.

## README Requirements

- [ ] Explain what range mapping is.
- [ ] Explain why `[-1.0, 1.0]` is the default.
- [ ] Explain that the SDK is first-party and dependency-free.
- [ ] Explain Alpha v1 scope.
- [ ] Explain Beta roadmap.
- [ ] Show integer mapping quickstart.
- [ ] Show clipping.
- [ ] Show strict out-of-range errors.
- [ ] Show saving/loading mapper specs.
- [ ] Explain old `[0, 1]` examples are legacy or configurable.
- [ ] Explain no external packages are required.
- [ ] Explain how to run tests.
- [ ] Explain how to install locally.
- [ ] Explain contribution rules.

## Docs Directory

- [ ] `docs/spec.md`
- [ ] `docs/quickstart.md`
- [ ] `docs/alpha_scope.md`
- [ ] `docs/beta_roadmap.md`
- [ ] `docs/compatibility.md`
- [ ] `docs/no_dependencies.md`

## Examples

- [ ] `examples/map_integer.py`
- [ ] `examples/map_negative_range.py`
- [ ] `examples/map_with_clipping.py`
- [ ] `examples/map_strict.py`
- [ ] `examples/save_and_load_mapper.py`

## Acceptance Criteria

A new user can understand and use integer mapping in under five minutes.

---

# LRM-100 — Packaging And Import Validation

STATUS: PENDING  
PRIORITY: HIGH

## Goal

Make the SDK installable and importable without dependencies.

## Tasks For Codex

1. Audit packaging metadata.
2. Ensure dependency lists are empty.
3. Ensure package name is consistent.
4. Test install/import locally.
5. Keep generated builds out of source.

## Requirements

- [ ] Add or clean `pyproject.toml`.
- [ ] Ensure runtime dependencies list is empty.
- [ ] Keep `setup.py` only if needed.
- [ ] Ensure package name is consistent.
- [ ] Ensure import works after local install.
- [ ] Ensure import works from source checkout.
- [ ] Ensure import works without generated `dist/`.
- [ ] Add package metadata.
- [ ] Add license metadata.
- [ ] Add project URLs.
- [ ] Add supported Python versions.
- [ ] Add classifiers only when true.
- [ ] Ensure no empty dependency string.
- [ ] Ensure generated build artifacts are ignored.

## Required Commands

```bash
python -m unittest discover
python -m pip install .
python -c "import librangemap; print(librangemap.__version__)"
```

## Acceptance Criteria

A developer can install and import `libRangeMap` locally without third-party dependencies.

---

# LRM-110 — V1 Alpha Release Gate

STATUS: PENDING  
PRIORITY: CRITICAL

## Goal

Determine whether v1 alpha is shippable.

## Tasks For Codex

1. Run all alpha tests.
2. Run install/import validation.
3. Run examples.
4. Check repo hygiene.
5. Write release notes.
6. Report readiness percentage.

## Required Alpha Checks

- [ ] Repo hygiene complete.
- [ ] Spec exists.
- [ ] Integer mapper exists.
- [ ] Default output range is `[-1.0, 1.0]`.
- [ ] Tests pass.
- [ ] No third-party runtime dependency.
- [ ] No third-party source vendored.
- [ ] README updated.
- [ ] Examples exist.
- [ ] Serialization exists.
- [ ] Install/import validation passes.
- [ ] Old generated artifacts removed from source control.
- [ ] Alpha limitations documented.
- [ ] Beta roadmap documented.
- [ ] Version set to `0.1.0-alpha` or similar.
- [ ] Release notes drafted.

## Alpha Exit Criteria

`libRangeMap` is Alpha v1-ready only when:

```text
A user can import the SDK, declare an integer input range, map finite integers into [-1.0, 1.0], save/reload the mapper spec, and run tests proving correctness without installing any dependency.
```

---

# LRM-120 — Beta Roadmap Foundation

STATUS: PENDING  
PRIORITY: HIGH

## Goal

Prepare the architecture for input-type expansion without bloating Alpha.

## Tasks For Codex

1. Define a mapper interface.
2. Define custom adapter contract.
3. Define schema idea.
4. Define type registry.
5. Keep implementation minimal until alpha passes.

## Requirements

- [ ] Define mapper interface.
- [ ] Define adapter interface.
- [ ] Define schema interface.
- [ ] Define type registry.
- [ ] Define custom mapper registration.
- [ ] Define transform result metadata.
- [ ] Define batch transform behavior.
- [ ] Define nested shape preservation.
- [ ] Define unknown-value policies.
- [ ] Define inverse-transform rules.
- [ ] Define compatibility test suite for future languages.
- [ ] Keep all of this dependency-free.

## Acceptance Criteria

The alpha codebase has a clear path to support more data types without rewriting the integer mapper.

---

# LRM-130 — Beta Type Expansion

STATUS: DEFERRED  
PRIORITY: TRACKED

## Goal

Expand from integer-only alpha toward input-type agnosticism.

## Beta Data Type Milestones

### Numeric Types

- [ ] Float range mapper.
- [ ] Decimal-compatible policy using standard library.
- [ ] Boolean mapper with explicit policy.
- [ ] Enum-like mapper.
- [ ] Bounded numeric schema.

### Character And Text

- [ ] ASCII character mapper.
- [ ] Configurable alphabet mapper.
- [ ] Case-sensitive policy.
- [ ] Case-insensitive policy.
- [ ] Unicode codepoint mapper.
- [ ] Unknown-character policy.
- [ ] String-as-character-sequence mapper.
- [ ] String-as-token-sequence mapper.
- [ ] Vocabulary mapper.
- [ ] Unknown-token policy.

### Sequences

- [ ] List mapper.
- [ ] Tuple mapper.
- [ ] Nested list/tuple mapper.
- [ ] Shape-preserving transform.
- [ ] Flattening option.
- [ ] Batch transform.
- [ ] Streaming/generator-safe policy.

### Binary And Buffers

- [ ] Bytes mapper.
- [ ] Bytearray mapper.
- [ ] Memoryview mapper.
- [ ] Bit-level mapper, optional.
- [ ] Fixed-width chunk mapper.

### Image-Like Data Without Dependencies

- [ ] Raw grayscale nested sequence mapper.
- [ ] RGB tuple mapper.
- [ ] RGBA tuple mapper.
- [ ] Flat raw pixel buffer mapper.
- [ ] Width/height/channel metadata.
- [ ] Pixel range policy.
- [ ] Shape-preserving output.

### Custom Objects

- [ ] Field schema mapper.
- [ ] Attribute mapper.
- [ ] Dict mapper.
- [ ] Dataclass mapper.
- [ ] Custom adapter registration.
- [ ] User-defined type policies.
- [ ] Nested object traversal.

## Acceptance Criteria

Beta can map many built-in data shapes and gives users a clear way to map their own types.

---

# LRM-140 — Cross-Language SDK Expansion

STATUS: DEFERRED  
PRIORITY: TRACKED

## Goal

Move from language-agnostic spec to multi-language first-party SDKs.

## Candidate Language Targets

- [ ] Python reference implementation.
- [ ] C++ implementation.
- [ ] C implementation or C ABI.
- [ ] JavaScript/TypeScript implementation.
- [ ] Rust implementation.
- [ ] C# implementation.
- [ ] Java/Kotlin implementation.
- [ ] Go implementation.

## Cross-Language Requirements

- [ ] Shared spec tests.
- [ ] Shared golden input/output fixtures.
- [ ] Same integer mapping outputs.
- [ ] Same clipping behavior.
- [ ] Same error categories.
- [ ] Same JSON mapping spec format.
- [ ] Same version compatibility policy.
- [ ] No third-party runtime dependencies unless explicitly documented per language.
- [ ] No copied third-party source.

## Acceptance Criteria

A mapper spec created in one language can be understood and reproduced in another supported language.

---

# LRM-150 — Open-Source Project Quality

STATUS: PENDING  
PRIORITY: MEDIUM

## Goal

Make the project welcoming and maintainable.

## Tasks For Codex

1. Add missing open-source documents.
2. Keep claims truthful.
3. Add contribution guidance.
4. Prepare release notes.
5. Consider CI only if it stays aligned with no-runtime-dependency rule.

## Requirements

- [ ] Add clear README.
- [ ] Add license.
- [ ] Add contribution guide.
- [ ] Add issue templates.
- [ ] Add PR template.
- [ ] Add code of conduct if desired.
- [ ] Add changelog.
- [ ] Add release notes.
- [ ] Add examples.
- [ ] Add docs.
- [ ] Add GitHub Actions CI if acceptable.
- [ ] Add badges only when truthful.
- [ ] Add roadmap.
- [ ] Add versioning policy.

## Acceptance Criteria

External contributors can understand project goals, open issues, run tests, and submit changes without guessing.

---

# LRM-160 — V1 Beta Release Gate

STATUS: DEFERRED  
PRIORITY: TRACKED

## Goal

Define when the SDK is ready to be called Beta.

## Required Beta Checks

- [ ] Alpha integer mapper remains stable.
- [ ] Numeric mappers stable.
- [ ] Character mapper stable.
- [ ] String mapper stable.
- [ ] Sequence mapper stable.
- [ ] Bytes/buffer mapper stable.
- [ ] Raw pixel/image-like mapper stable.
- [ ] Custom adapter system stable.
- [ ] Schema system stable.
- [ ] Serialization stable.
- [ ] Cross-language spec stable.
- [ ] At least two language implementations pass compliance tests, if language-agnostic claim is promoted.
- [ ] Import/install path validated.
- [ ] No core dependencies.
- [ ] Docs explain all supported types.
- [ ] Examples cover all supported types.
- [ ] API compatibility policy exists.

## Beta Exit Criteria

`libRangeMap` is Beta-ready when:

```text
A user can import the SDK into a project, map supported data types into [-1.0, 1.0], define custom mappers for unsupported types, save/reload mapper specs, and rely on documented deterministic behavior across supported implementations.
```

---

# Deferred Until After V1 Beta

STATUS: DEFERRED  
PRIORITY: TRACKED

- Machine-learning framework integrations.
- NumPy adapter package.
- Pillow adapter package.
- Pandas adapter package.
- PyTorch adapter package.
- TensorFlow adapter package.
- OpenCV adapter package.
- GPU acceleration.
- Dataset storage format.
- Dataset visualization tools.
- Model-training tools.
- Automatic semantic encoding.
- Remote dataset services.
- Telemetry or hosted services.
- Any non-first-party dependency in the core SDK.

---

# Immediate Next Implementation Task

STATUS: ACTIVE  
PRIORITY: CRITICAL

Codex should start with `LRM-000` through `LRM-030`.

## Exact First Codex Run Plan

1. Read `AGENTS.md` and this `burndown.md`.
2. Inspect the repo tree and summarize:
   - current source files,
   - generated artifacts,
   - package metadata,
   - current README claims,
   - tests/docs/examples,
   - Python behavior,
   - C++ behavior.
3. Update `burndown.md` statuses based on actual local repo findings.
4. Add or update `AGENTS.md` if missing.
5. Add `docs/spec.md`.
6. Implement dependency-free integer mapping with default output `[-1.0, 1.0]`.
7. Add standard-library `unittest` coverage.
8. Update README with alpha scope and no-dependency promise.
9. Run:

```bash
python -m unittest discover
python -m pip install .
python -c "import librangemap; print(librangemap.__version__)"
```

10. Report:
    - completed work,
    - remaining work,
    - files changed,
    - commands run,
    - command results,
    - blockers,
    - alpha readiness percentage.

## Immediate Acceptance Criteria

A fresh checkout can prove:

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100))
assert mapper.map_value(0) == -1.0
assert mapper.map_value(50) == 0.0
assert mapper.map_value(100) == 1.0
```

This is the v1 alpha heartbeat: small, deterministic, dependency-free, language-spec-backed, and ready to expand.

---

# Codex Reporting Template

After every phase or subphase, Codex must report:

```md
## Phase Report

Phase/subphase:
Status:
Alpha readiness %:
Beta readiness %:

Completed:
- ...

Files changed:
- ...

Commands run:
- ...

Results:
- ...

Known blockers:
- ...

Dependency check:
- No third-party runtime dependency added.
- No third-party source copied or vendored.

Spec/API notes:
- ...

Next recommended task:
- ...
```

---

# Final Alpha Report Template

When Codex believes Alpha v1 is ready, it must provide:

```md
# libRangeMap V1 Alpha Readiness Report

Final alpha readiness:
Version:
Date:

Completed phases:
- ...

Required checks:
- [ ] Repo hygiene complete
- [ ] Spec complete
- [ ] Integer mapper complete
- [ ] Error handling complete
- [ ] Serialization complete
- [ ] Tests pass
- [ ] Docs/examples complete
- [ ] Package/import validation pass
- [ ] No runtime dependencies
- [ ] No copied third-party source

Commands run:
- ...

Results:
- ...

Known risks:
- ...

Deferred to beta:
- ...

Recommended next phase:
- ...
```

