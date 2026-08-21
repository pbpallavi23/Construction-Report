
"""Run the full backend test suite.

Usage:
    python run_tests.py            # run everything
    python run_tests.py -v         # verbose (per-test output)
    python run_tests.py tests.test_api   # run a single test module

No third-party test framework is required - everything is stdlib
`unittest`, so `pip install -r requirements.txt` (which gets you Flask,
reportlab, openpyxl, etc.) is enough. `faster-whisper` is optional: the
one place that needs it (`speech_service.transcribe`) is tested with the
model mocked out, so the full suite runs fine without it installed too.
"""
from __future__ import annotations

import sys
import unittest


def main() -> int:
    args = sys.argv[1:]
    verbosity = 2 if "-v" in args or "--verbose" in args else 1
    args = [a for a in args if a not in ("-v", "--verbose")]

    if args:


        suite = unittest.TestLoader().loadTestsFromNames(args)
    else:
        suite = unittest.TestLoader().discover(
            start_dir="tests", pattern="test_*.py", top_level_dir="."
        )

    result = unittest.TextTestRunner(verbosity=verbosity).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
