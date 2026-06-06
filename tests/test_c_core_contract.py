import os
import unittest


class CCoreContractTests(unittest.TestCase):
    def test_c_core_header_exists(self):
        root = os.path.dirname(os.path.dirname(__file__))
        header = os.path.join(root, "csrc", "librangemap_core.h")
        source = os.path.join(root, "csrc", "librangemap_core.c")

        self.assertTrue(os.path.exists(header))
        self.assertTrue(os.path.exists(source))

    def test_c_core_exports_abi(self):
        root = os.path.dirname(os.path.dirname(__file__))
        header = os.path.join(root, "csrc", "librangemap_core.h")

        with open(header, "r", encoding="utf-8") as handle:
            text = handle.read()

        self.assertIn("lrm_integer_range_mapper_init", text)
        self.assertIn("lrm_integer_range_mapper_map_value", text)
        self.assertIn("lrm_integer_range_mapper_get_spec", text)
        self.assertIn("LRM_ERROR_OUT_OF_RANGE", text)
        self.assertIn("extern \"C\"", text)


if __name__ == "__main__":
    unittest.main()
