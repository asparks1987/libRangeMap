from librangemap import IntegerRangeMapper


mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)

print(mapper.map_value(-50))
print(mapper.map_value(150))
