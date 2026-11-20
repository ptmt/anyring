"""Keep missing workout-zone data neutral, without implying denied access."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class WorkoutZoneCopyTests(unittest.TestCase):
    def test_no_readable_zones_uses_neutral_copy(self):
        source = (ROOT / 'AnyRing/Shared/HealthKitDataSource/HealthKitDataSource.swift').read_text()
        error = source.split('enum WorkoutZoneError: LocalizedError {', 1)[1]
        match = re.search(r'case \.noReadableZones:\s*"([^"\n]*)"', error)
        if match is None:
            self.fail('Missing noReadableZones error description')
        self.assertEqual(match.group(1), 'No data')
