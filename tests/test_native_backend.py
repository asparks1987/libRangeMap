import unittest

from librangemap.native_backend import load_native_backend


class NativeBackendTests(unittest.TestCase):
    def test_native_backend_loads_when_built(self):
        backend = load_native_backend()
        if backend is None:
            self.skipTest("native backend not built in this checkout")

        mapper = backend.create_mapper(0, 100, -1.0, 1.0, False)
        self.assertIsNotNone(mapper)
        self.assertEqual(backend.map_value(mapper, 0), -1.0)
        self.assertEqual(backend.map_value(mapper, 50), 0.0)
        self.assertEqual(backend.map_value(mapper, 100), 1.0)


if __name__ == "__main__":
    unittest.main()
