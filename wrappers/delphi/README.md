# libRangeMap Delphi/Object Pascal Wrapper

This directory contains a first-party Delphi/Object Pascal implementation of the Alpha v1 integer mapper.

It is a dependency-free reference implementation that follows the shared mapping contract:

- validates input bounds and output bounds
- strict mode by default, optional clipping mode
- deterministic output in `[output_min, output_max]` with finite inputs
