#!/usr/bin/env python3
"""Exercise report contracts independently of noisy host timings."""
import argparse
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("benchmark_runner", Path(__file__).resolve().parents[1] / "benchmarks/run.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class ReportTests(unittest.TestCase):
    def execute(self, temporary, trial):
        root = Path(temporary)
        manifest = root / "manifest.json"
        manifest.write_text(json.dumps({"zi": str(root), "annex": str(root), "cases": {"loader": {}}}))
        args = argparse.Namespace(candidate=manifest, baseline=manifest, mode="recipes", case=None,
                                  samples=3, warmups=1, zd_image=None, runner_image="unit-host", output=root / "report.json")
        with patch.object(runner, "prepare", side_effect=lambda *_: {"zi": "x", "annex": "x", "upstreams": {}}), \
                patch.object(runner, "source_fingerprint", return_value="x"), \
                patch.object(runner, "trial", side_effect=trial), \
                patch.dict(os.environ, {"GITHUB_STEP_SUMMARY": str(root / "summary.md"), "GITHUB_ACTIONS": "true"}), \
                contextlib.redirect_stdout(io.StringIO()):
            return runner.run(args)

    @staticmethod
    def measurement(value=10, runtime="5.9.2 linux x86_64"):
        return dict.fromkeys(runner.METRICS, value), "fixture", runtime, "fixed"

    def test_statistics_and_strict_flag_thresholds(self):
        before = runner.summary([10] * 20)
        self.assertEqual(before, {"median": 10, "p95": 10, "min": 10, "count": 20, "samples": [10] * 20})
        self.assertFalse(runner.comparison_row(before, runner.summary([11] * 20))["flag"])
        self.assertTrue(runner.comparison_row(before, runner.summary([11.01] * 20))["flag"])
        self.assertTrue(runner.comparison_row(before, runner.summary([10] * 18 + [12, 12]))["flag"])
        self.assertIsNone(runner.comparison_row(runner.summary([0, 0]), runner.summary([1, 1]))["change"]["median_delta_percent"])

    def test_balanced_order(self):
        orders = [tuple(runner.trial_order(i)) for i in range(6)]
        self.assertEqual(len(set(orders)), 6)
        for label in ("baseline", "candidate", "control"):
            for position in range(3):
                self.assertEqual(sum(order[position] == label for order in orders), 2)

    def test_identical_control_and_slowdown_are_valid_nonfatal_evidence(self):
        for slow in (False, True):
            with self.subTest(slow=slow), tempfile.TemporaryDirectory() as temporary:
                def trial(_spec, _case, root, _image):
                    return self.measurement(20 if slow and root.name == "candidate" else 10)
                report = self.execute(temporary, trial)
                self.assertIn("A/A p95 (%)", (Path(temporary) / "summary.md").read_text())
                self.assertEqual(report["status"], "complete")
                self.assertTrue(report["comparable"])
                self.assertEqual(report["schema_version"], 1)
                self.assertEqual(report["failed"], [])
                self.assertEqual(len(report["flagged"]), 4 if slow else 0)
                self.assertEqual(report["baseline"]["source_revision"], report["control_identity"]["source_revision"])
                for key, row in report["cases"].items():
                    self.assertEqual(row["results"]["candidate"]["count"], 3)
                    self.assertEqual(report["control"][key]["change"]["median_delta_percent"], 0)
                    self.assertFalse(report["control"][key]["flag"])

    def test_failures_and_invalid_metrics_never_complete(self):
        for variant in ("baseline", "candidate", "control"):
            for kind in ("failure", "missing", "nan", "bool", "shell"):
                with self.subTest(variant=variant, kind=kind), tempfile.TemporaryDirectory() as temporary:
                    def trial(_spec, _case, root, _image):
                        result = self.measurement()
                        if root.name == variant:
                            if kind == "failure":
                                raise RuntimeError("fixture failed")
                            if kind == "missing":
                                result[0].pop("repeat_ms")
                            if kind == "nan":
                                result[0]["repeat_ms"] = float("nan")
                            if kind == "bool":
                                result[0]["repeat_ms"] = True
                            if kind == "shell":
                                return self.measurement(runtime="5.8.1 linux x86_64")
                        return result
                    with self.assertRaises((ValueError, RuntimeError)):
                        self.execute(temporary, trial)
                    report = json.loads((Path(temporary) / "report.json").read_text())
                    self.assertEqual(report["status"], "incomplete")
                    self.assertFalse(report["comparable"])
                    self.assertEqual(len(report["failed"]), 4)
                    self.assertEqual(report["flagged"], [])
                    self.assertTrue(any("failure" in row for section in ("cases", "control") for row in report[section].values()))


if __name__ == "__main__":
    unittest.main()
