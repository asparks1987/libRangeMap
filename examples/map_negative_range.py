from librangemap import IntegerRangeMapper


mapper = IntegerRangeMapper(input_range=(-10, 10))

print(mapper.map_value(-10))
print(mapper.map_value(0))
print(mapper.map_value(10))
