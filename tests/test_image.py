import unittest

from librangemap import ImageRangeMapper, OutOfRangeError, UnsupportedTypeError


class ImageRangeMapperTests(unittest.TestCase):
    def test_grayscale_nested_sequence_maps(self):
        mapper = ImageRangeMapper(input_range=(0, 255), mode="grayscale")
        self.assertEqual(
            mapper.map_value([[0, 255], [64, 255]]),
            [[-1.0, 1.0], [-0.4980392156862745, 1.0]],
        )

    def test_rgb_nested_pixels_map(self):
        mapper = ImageRangeMapper(input_range=(0, 255), mode="rgb", preserve_tuples=False, allow_empty=True)
        self.assertEqual(
            mapper.map_value([[(0, 0, 0), (255, 255, 255)]]),
            [[-1.0, -1.0, -1.0], [1.0, 1.0, 1.0]],
        )

    def test_rgba_channel_validation_fails_when_malformed(self):
        mapper = ImageRangeMapper(input_range=(0, 255), mode="rgba")
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value((1, 2, 3))

    def test_raw_bytes_mapping(self):
        mapper = ImageRangeMapper(input_range=(0, 255), mode="raw_bytes")
        self.assertEqual(mapper.map_value(b"\x00\xff"), [-1.0, 1.0])

    def test_empty_input_rejected_by_default(self):
        mapper = ImageRangeMapper()
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value([])

    def test_out_of_range_strict_mode_raises(self):
        mapper = ImageRangeMapper(input_range=(0, 10), mode="grayscale", clip=False)
        with self.assertRaises(OutOfRangeError):
            mapper.map_value(20)

    def test_serialization_round_trip(self):
        mapper = ImageRangeMapper(input_range=(0, 255), mode="rgb", preserve_tuples=True, name="img")
        restored = ImageRangeMapper.from_json(mapper.to_json())
        self.assertEqual(restored.mode, "rgb")
        self.assertEqual(restored.map_value((0, 0, 255)), (-1.0, -1.0, 1.0))
        self.assertEqual(restored.name, "img")


if __name__ == "__main__":
    unittest.main()
