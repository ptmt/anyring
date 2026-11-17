"""Presentation contracts and real Foundation formatting; no simulator/pixel proof.

Compile the unchanged presentation-property slice from RingViewModel with tiny
input adapters. Provider/query/model integration remains covered by native tests.
"""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / "AnyRing/Shared/Views/ViewModels/RingViewModel.swift"


class CompactMetricLabels(unittest.TestCase):
    def test_overview_uses_inline_target_without_visible_goal_or_baseline(self):
        source = (ROOT / "AnyRing/Shared/Views/Common/RingLabel.swift").read_text()
        overview = source.split("struct RingDashboardLegend: View", 1)[1].split("struct RingMetricView", 1)[0]
        self.assertIn('Text(" / \\(ring.targetText) \\(ring.units)")', overview)
        self.assertNotIn('Text("Goal ', overview)
        self.assertNotIn('ring.startingValueText', overview)
        self.assertIn('.foregroundColor(.secondary)', overview)
        self.assertIn('Text(ring.name)', overview)
        self.assertIn('Circle().fill(ring.configuration.appearance.mainColor.color)', overview)
        self.assertIn('ring.overviewAccessibilityValue', overview)
        self.assertIn('.fixedSize(horizontal: false, vertical: true)', overview)
        self.assertNotIn('.lineLimit(', overview)
        self.assertNotIn('.minimumScaleFactor(', overview)

    def test_actual_presentation_properties_keep_precision_and_goal_semantics(self):
        source = MODEL.read_text()
        self.assertIn('var targetText:', source, 'Missing plain configured target presentation')
        properties = source.split('    var direction:', 1)[1].split('    var name:', 1)[0]
        harness = '''import Foundation
struct Input { var minValue: Double; var maxValue: Double }
struct Reading { var absolute: Double; var empty: Bool { absolute == 0 } }
struct Labels {
    var configuration: Input
    var progress: Reading
    var isReversed: Bool
    var units: String
    var isRefreshing = false
    var error: NSError? = nil
    var direction:''' + properties + '''
}
func formatted(_ n: Double) -> String { n.formatted(.number.precision(.fractionLength(0...1))) }
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}
print("Locale: \\(Locale.current.identifier)")
let cases: [(Double, Double, Double, Bool, String)] = [
    (55, 42, 80, true, "bpm"),
    (110, 0, 100, false, "ms"),
    (5100.25, 0, 15000, false, "steps"),
    (12.34, 0, 45.67, false, "min"), // zone 2–3
    (8.75, 0, 30.25, false, "min"), // zone 4–5
    (1234.56, 250, 15000.75, false, "歩数 🏃"),
    (55.25, 42.75, 80.5, true, "уд/мин")
]
for (current, minimum, maximum, reverse, unit) in cases {
    let labels = Labels(configuration: Input(minValue: minimum, maxValue: maximum),
                        progress: Reading(absolute: current), isReversed: reverse, units: unit)
    let target = reverse ? minimum : maximum
    check(labels.targetText == formatted(target), "Configured target, not baseline")
    check(labels.valueText == formatted(current), "Preserve existing decimal formatter")
    let visible = "\\(labels.valueText) / \\(labels.targetText) \\(unit)"
    check(!visible.contains("≥") && !visible.contains("≤"), "Plain slash only")
    check(labels.overviewAccessibilityValue.contains(labels.goalText), "Accessible comparison/target/unit")
    check(labels.overviewAccessibilityValue.contains(labels.direction), "Accessible direction")
    if let baseline = labels.startingValueText {
        check(labels.overviewAccessibilityValue.contains(baseline), "Accessible baseline")
    }
    if reverse && current == 55 {
        check(visible == "\\(formatted(55)) / \\(formatted(42)) bpm", "Never baseline 80")
        if Locale.current.identifier == "en_US" { check(visible == "55 / 42 bpm", "Never 55 / 80 bpm") }
    }
    print(visible)
}
var empty = Labels(configuration: Input(minValue: 42, maxValue: 80),
                   progress: Reading(absolute: 0), isReversed: true, units: "bpm", isRefreshing: true)
check(empty.valueText == "—" && empty.targetText == formatted(42), "Loading does not erase target")
empty.error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Read unavailable"])
check(empty.overviewAccessibilityValue.contains("Read unavailable"), "Keep accessible errors")
print("PASS: presentation cases, decimal precision, Unicode, baseline, pending/error")
'''
        with tempfile.TemporaryDirectory(prefix="compact-labels-", dir=os.environ.get("TMPDIR")) as folder:
            swift = Path(folder) / "main.swift"
            swift.write_text(harness)
            for locale in ["en_US", "fr_FR", "ru_RU", "ar_EG"]:
                result = subprocess.run(["swift", str(swift), "-AppleLocale", locale],
                                        capture_output=True, text=True, timeout=120)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("Locale: " + locale, result.stdout)
                print(result.stdout)


if __name__ == "__main__":
    unittest.main()
