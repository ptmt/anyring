"""Lightweight structure guards, NOT native rendering/height acceptance.

The iOS Form geometry and snapshots are gated separately in Tests_iOS.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class DashboardDensityContract(unittest.TestCase):
    def test_empty_library_uses_single_intrinsic_save_control(self):
        source = (ROOT / "AnyRing/Shared/Views/TemplateView.swift").read_text()
        saved = source.split("struct SavedConfigurationsView: View", 1)[1]
        self.assertRegex(saved, r"if model\.savedConfigurations\.isEmpty\s*\{\s*saveButton\s*\} else \{")
        self.assertIn('"Save current setup"', saved)
        self.assertIn('.buttonStyle(.plain)', saved.split('var body: some View', 1)[0])


    def test_week_inclusion_is_not_a_table_underline(self):
        source = (ROOT / "AnyRing/Shared/Views/RingDashboard.swift").read_text()
        week = source.split("struct TrackingWeekView", 1)[1].split("struct RingDashboard", 1)[0]
        self.assertNotIn("Rectangle().fill(day.included", week)
        self.assertIn("Circle().fill(day.included ? periodSecondary : .clear)", week)
        self.assertIn('.frame(width: 4, height: 4)', week)
        self.assertIn('.onChange(of: calendar.startOfDay(for: now))', week)


    def test_saved_strip_requests_intrinsic_vertical_size(self):
        source = (ROOT / "AnyRing/Shared/Views/TemplateView.swift").read_text()
        saved = source.split("struct SavedConfigurationsView: View", 1)[1]
        self.assertRegex(saved, r"\.scrollIndicators\(\.hidden\)\s*\.fixedSize\(horizontal: false, vertical: true\)")
        self.assertRegex(saved, r"\}\s*\.fixedSize\(horizontal: false, vertical: true\)\s*\.alert\(renaming")


if __name__ == "__main__":
    unittest.main()
