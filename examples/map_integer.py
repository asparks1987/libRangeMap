from librangemap import IntegerRangeMapper


mapper = IntegerRangeMapper(input_range=(0, 100))

print(mapper.map_value(0))
print(mapper.map_value(50))
print(mapper.map_value(100))
