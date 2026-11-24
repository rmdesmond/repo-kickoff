import contextlib
import io
import unittest

from app import __version__
from app.cli import main


class CliTest(unittest.TestCase):
    def test_prints_placeholder(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.assertEqual(main([]), 0)
        self.assertEqual(
            out.getvalue(), "{{NAME}}: placeholder - nothing implemented yet\n"
        )

    def test_version(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), self.assertRaises(SystemExit) as exit:
            main(["--version"])
        self.assertEqual(exit.exception.code, 0)
        self.assertEqual(out.getvalue(), "{{NAME}} " + __version__ + "\n")

    def test_unknown_argument(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(
            SystemExit
        ) as exit:
            main(["--no-such-option"])
        self.assertEqual(exit.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
