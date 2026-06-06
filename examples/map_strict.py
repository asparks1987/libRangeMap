from librangemap import IntegerRangeMapper, OutOfRangeError


mapper = IntegerRangeMapper(input_range=(0, 100))

try:
    mapper.map_value(101)
except OutOfRangeError as exc:
    print(exc)
