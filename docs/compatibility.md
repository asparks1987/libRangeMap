# Compatibility Notes

The original experiment exposed `libRangeMap.py` with `RangeMapper` and `CharRangeMapper`.

Alpha v1 makes `librangemap` the canonical Python import package:

```python
from librangemap import IntegerRangeMapper
```

The historical default output range was `[0.0, 1.0]`. Alpha v1 changes the default to `[-1.0, 1.0]`.

The historical character mapper used alphabet positions and mapped unknown characters to `999`. That behavior is not part of alpha because unknown values must not silently become magic numbers.
