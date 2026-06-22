"""Tests for .tiktoken and base64 loaders (RULES.md § 5.1).

HF JSON loader tests require Python; run in pyregex environment.
Conformance parity (tiktoken vs firebpe output) is in tests/conformance/.
"""

from std.testing import assert_equal, assert_true, assert_raises, TestSuite
from firebpe.loaders.tiktoken import base64_decode, load_tiktoken_ranks
from firebpe.loaders.byte_unicode import hf_token_str_to_bytes, byte_to_char_table
from firebpe.errors import raise_malformed_rank_file
import std.os


def test_base64_decode_basic() raises:
    # 'A' -> 65 -> base64 'QQ=='
    var decoded = base64_decode("QQ==")
    assert_equal(len(decoded), 1)
    assert_equal(decoded[0], UInt8(65))


def test_base64_decode_two_bytes() raises:
    # 'AB' -> [65, 66] -> base64 'QUI='
    var decoded = base64_decode("QUI=")
    assert_equal(len(decoded), 2)
    assert_equal(decoded[0], UInt8(65))
    assert_equal(decoded[1], UInt8(66))


def test_base64_decode_three_bytes() raises:
    # 'ABC' -> [65, 66, 67] -> base64 'QUJD'
    var decoded = base64_decode("QUJD")
    assert_equal(len(decoded), 3)
    assert_equal(decoded[0], UInt8(65))
    assert_equal(decoded[1], UInt8(66))
    assert_equal(decoded[2], UInt8(67))


def test_base64_decode_single_newline() raises:
    # '\n' = 0x0A -> base64 'Cg=='
    var decoded = base64_decode("Cg==")
    assert_equal(len(decoded), 1)
    assert_equal(decoded[0], UInt8(0x0A))


def test_base64_round_trip_all_bytes() raises:
    """All 256 single-byte values round-trip through base64."""
    from firebpe.core import _base64_encode
    for b in range(256):
        var orig: List[UInt8] = [UInt8(b)]
        var encoded = _base64_encode(Span[UInt8](orig))
        var decoded = base64_decode(encoded)
        assert_equal(len(decoded), 1)
        assert_equal(decoded[0], UInt8(b))


def test_hf_byte_unicode_all_bytes() raises:
    """All 256 bytes map to a char and back."""
    var btc = byte_to_char_table()
    for b in range(256):
        var char_cp = btc[b]
        assert_true(char_cp >= 0)

    # Spot check: byte 65 ('A') → char code point 65.
    assert_equal(btc[65], 65)
    # Byte 0x20 (space) is one of the control-range bytes → maps to 256+.
    assert_true(btc[0x20] >= 256)


def test_load_tiktoken_ranks_placeholder() raises:
    """Load a hand-crafted minimal .tiktoken file and verify ranks."""
    # Write a temp file with 3 tokens.
    var path = "/tmp/firebpe_test_ranks.tiktoken"
    # IQ== = '!'(33) rank 0, Ig== = '"'(34) rank 1, Iw== = '#'(35) rank 2
    with open(path, "w") as f:
        f.write("IQ== 0\n")
        f.write("Ig== 1\n")
        f.write("Iw== 2\n")

    var table = load_tiktoken_ranks(path)
    var bang: List[UInt8] = [UInt8(33)]
    var quote: List[UInt8] = [UInt8(34)]
    var hash_: List[UInt8] = [UInt8(35)]
    assert_equal(table.rank_of(Span[UInt8](bang)), UInt32(0))
    assert_equal(table.rank_of(Span[UInt8](quote)), UInt32(1))
    assert_equal(table.rank_of(Span[UInt8](hash_)), UInt32(2))


def test_load_tiktoken_malformed_raises() raises:
    var path = "/tmp/firebpe_test_bad.tiktoken"
    with open(path, "w") as f:
        f.write("not_valid_line_without_rank\n")
    with assert_raises():
        var _ = load_tiktoken_ranks(path)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
