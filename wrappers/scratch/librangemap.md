# libRangeMap Scratch Spec

- Inputs:
  - `value`
  - `inputMin`
  - `inputMax`
  - `outputMin` (default `-1`)
  - `outputMax` (default `1`)
  - `clip` (true/false)
- Guard rails:
  - require `inputMin < inputMax`
  - require `outputMin < outputMax`
  - if not clipping and value is outside bounds, report `"out_of_range"` and halt
- Formula:

```
mapped = outputMin + ((value - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin)
```

Expected examples:

`[0,100]`, value `0` -> `-1`
`[0,100]`, value `50` -> `0`
`[0,100]`, value `100` -> `1`
