# Quickstart

Install locally from the repo:

```bash
python -m pip install .
```

Use the alpha integer mapper:

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100))

assert mapper.map_value(0) == -1.0
assert mapper.map_value(50) == 0.0
assert mapper.map_value(100) == 1.0
```

Strict mode is the default:

```python
mapper.map_value(101)  # raises OutOfRangeError
```

Enable clipping explicitly:

```python
mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)
assert mapper.map_value(150) == 1.0
```
