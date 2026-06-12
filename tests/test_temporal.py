import unittest
from datetime import date, datetime, time, timedelta, timezone

from librangemap import OutOfRangeError, TemporalRangeMapper, UnsupportedTypeError


class TemporalRangeMapperTests(unittest.TestCase):
    def test_datetime_mode_maps_with_explicit_epoch(self):
        epoch = datetime(2020, 1, 1, tzinfo=timezone.utc)
        mapper = TemporalRangeMapper(
            input_range=(0.0, 86400.0),
            mode="datetime",
            epoch=epoch,
        )
        self.assertEqual(mapper.map_value(epoch), -1.0)
        self.assertEqual(mapper.map_value(epoch + timedelta(hours=12)), 0.0)
        self.assertEqual(mapper.map_value(epoch + timedelta(hours=24)), 1.0)

    def test_auto_mode_accepts_duration_input(self):
        mapper = TemporalRangeMapper(input_range=(0.0, 120.0), mode="auto")
        self.assertEqual(mapper.map_value(timedelta(seconds=0)), -1.0)
        self.assertEqual(mapper.map_value(timedelta(seconds=60)), 0.0)
        self.assertEqual(mapper.map_value(timedelta(seconds=120)), 1.0)

    def test_duration_mode_rejects_date_input(self):
        mapper = TemporalRangeMapper(input_range=(0.0, 120.0), mode="duration")
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(date(2020, 1, 2))

    def test_time_mode_is_seconds_of_day(self):
        mapper = TemporalRangeMapper(input_range=(0.0, 3600.0), mode="time", clip=True)
        self.assertEqual(mapper.map_value(time(0, 0, 0)), -1.0)
        self.assertEqual(mapper.map_value(time(0, 30, 0)), -0.5)

    def test_duration_out_of_range_fails_in_strict_mode(self):
        mapper = TemporalRangeMapper(input_range=(0.0, 10.0), mode="duration", clip=False)
        with self.assertRaises(OutOfRangeError):
            mapper.map_value(timedelta(seconds=-1))

    def test_naive_datetime_policy_reject(self):
        mapper = TemporalRangeMapper(input_range=(0.0, 10.0), mode="datetime", naive_datetime_policy="reject")
        with self.assertRaises(UnsupportedTypeError):
            mapper.map_value(datetime(2020, 1, 1))


if __name__ == "__main__":
    unittest.main()
