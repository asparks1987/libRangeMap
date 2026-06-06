from librangemap import IntegerRangeMapper


mapper = IntegerRangeMapper(input_range=(0, 255), clip=True)
mapper.save("pixel_range.json")

loaded = IntegerRangeMapper.load("pixel_range.json")

print(loaded.map_value(0))
print(loaded.map_value(255))
