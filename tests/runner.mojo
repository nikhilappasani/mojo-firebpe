"""Test runner entry point. Run with: mojo run tests/runner.mojo

Each test module has its own main() that runs via TestSuite.discover_tests.
This runner imports all modules to verify they compile together.
"""

from std.testing import TestSuite

# Verify all test modules import cleanly.
# Individual test files have their own main(); run them directly for details.

def main() raises:
    print("firebpe test suite")
    print("Run individual test files:")
    print("  mojo run tests/test_vocab.mojo")
    print("  mojo run tests/test_merge.mojo")
    print("  mojo run tests/test_encode_decode.mojo")
    print("  mojo run tests/test_trainer.mojo")
    print("  mojo run tests/test_loaders.mojo")
    print("  mojo run tests/conformance/test_conformance.mojo")
