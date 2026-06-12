# Beta Readiness Evidence

This page maps the active Alpha v1 Beta readiness objective to current repository evidence.
It is intentionally conservative: Beta v1 readiness is complete while production v1 remains pending.

## Current gate summary

| Milestone | Current status | Evidence |
| --- | --- | --- |
| Foundation | complete | `docs/spec.md`, `docs/beta_wrapper_contract.md`, Python mappers, and shared formula docs define deterministic bounded mapping, explicit errors, default `[-1.0, 1.0]`, and JSON specs. |
| Wrapper parity | complete | `compliance/alpha_v1_languages.json`, `compliance/runtime_verification_status.json`, `wrappers/`, wrapper READMEs, and smoke scripts cover the 25 canonical language paths. |
| Compatibility matrix | complete for beta family parity | `compliance/beta_readiness.json` lists 10 implemented beta families and zero planned families for all 25 languages; `docs/compatibility.md` shows every family at `25/25`. |
| Docs finish | complete | README, quickstart, docs site, wrapper contract, compatibility matrix, beta completion audit, and production path explain the current beta state. |
| Packaging/readiness | complete for beta | Core remains dependency-free with packaging guards in `tests/test_dependency_free.py`; `compliance/beta_conformance_fixtures.json` starts shared beta-family fixture coverage; `tools/write_runtime_verification_results.py` can generate verified/skipped/failed runtime records; production readiness still needs broader fixture depth and release packaging checks. |

## Acceptance criteria evidence map

| # | Requirement | Current evidence | Status |
| -: | --- | --- | --- |
| 1 | Consistent mapper contract and canonical formula are documented and tested. | `docs/spec.md`, `README.md`, `docs/quickstart.md`, `docs/beta_wrapper_contract.md`, and mapper tests document/use the canonical formula. | complete for beta |
| 2 | Language wrappers exist for all 25 entries, with CI-friendly smoke checks. | `compliance/alpha_v1_languages.json`, `compliance/runtime_verification_status.json`, `wrappers/<language>/README.md`, `wrappers/<language>/test.cmd`, `tools/verify_wrapper_contract.ps1`, and runtime smoke tests define the wrapper surface. | complete for beta |
| 3 | Mapping outputs remain bounded to configured range by design. | Strict range validation, clipping policies, and byte/text/image policies are documented in `docs/spec.md`, `docs/beta_wrapper_contract.md`, and wrapper READMEs. | complete for beta |
| 4 | Deterministic behavior verified across nested sequences and edge-case inputs. | `compliance/beta_conformance_fixtures.json`, Python tests, and multiple wrapper smoke paths cover repeated calls, nested sequences, object schemas, unknown/missing failures, and image-like payloads; `compliance/beta_readiness.json` records family support. | complete for beta; production fixture breadth continues |
| 5 | Failures are explicit and typed. | Core docs require helpful exceptions/statuses for invalid ranges, NaN/Inf, unknown tokens, unknown fields, unsupported types, empty data, and missing metadata. | complete for beta |
| 6 | JSON-serializable mapper specs include fitted ranges/vocab/policies/metadata. | `compliance/spec_metadata_contract.json`, Python serialization tests, and wrapper spec classes include `spec_version`, `mapper_type`, ranges, vocabulary/policy fields, clipping, empty/missing policies, and metadata where supported. | complete for beta |
| 7 | Docs include roadmap: current alpha beta state, blocker list, and production target. | `README.md`, `docs/beta_roadmap.md`, `docs/production_path_to_v1.md`, `docs/compatibility.md`, and `docs/index.html` describe beta parity, production blockers, and the 99%+ practical compatibility target. | complete for beta roadmap |

## What remains before production v1

- Build shared conformance fixtures for every beta family and representative cross-language edge case.
- Record verified/skipped/failed runtime results per language using `compliance/runtime_verification_results.schema.json`.
- Harden spec round-trip tests for nested mapper graphs, fitted vocabularies, missing policies, and metadata.
- Apply the extractor/schema contract in `compliance/opaque_extractor_contract.json` to any future support for opaque runtime objects such as sockets, file handles, threads, processes, closures, and raw pointers without metadata.
- Preserve the first-party, dependency-free rule through packaging and release checks.

## Source of truth

- [Beta Readiness Manifest](../compliance/beta_readiness.json)
- [Beta Completion Audit](beta_completion_audit.md)
- [Beta Conformance Fixtures](../compliance/beta_conformance_fixtures.json)
- [Spec Metadata Contract](../compliance/spec_metadata_contract.json)
- [Opaque Extractor Contract](../compliance/opaque_extractor_contract.json)
- [Runtime Verification Status](../compliance/runtime_verification_status.json)
- [Runtime Verification Results Schema](../compliance/runtime_verification_results.schema.json)
- [Runtime Result Writer](../tools/write_runtime_verification_results.py)
- [Compatibility Matrix](compatibility.md)
- [Beta Wrapper Contract](beta_wrapper_contract.md)
- [Path to Production v1](production_path_to_v1.md)
