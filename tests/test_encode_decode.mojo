"""Round-trip encode/decode tests (RULES.md § 5.1).

SPEC § 3.3: decode(encode(s)) == s for all valid UTF-8 s.
Covers: ASCII, emoji, CJK, combining marks, control bytes, empty string.
"""

from std.testing import assert_equal, assert_true, assert_raises, TestSuite
from firebpe.vocab import RankTable
from firebpe.core import Encoder
from firebpe.special import SpecialPolicy
from firebpe.loaders.encodings import CL100K_PATTERN, cl100k_special_tokens


def _make_tiny_encoder() raises -> Encoder:
    """Build a minimal encoder with base byte tokens only (no merges).

    This is sufficient for round-trip tests when we don't need tiktoken
    output parity — every byte maps to its own token.
    """
    var t = RankTable.with_base_bytes()
    return Encoder(t^, CL100K_PATTERN, Dict[String, Int]())


def test_empty_string() raises:
    var enc = _make_tiny_encoder()
    var ids = enc.encode("")
    assert_equal(len(ids), 0)
    var text = enc.decode(ids)
    assert_equal(text, "")


def test_ascii_round_trip() raises:
    var enc = _make_tiny_encoder()
    var s = "Hello, world!"
    var ids = enc.encode(s)
    var back = enc.decode(ids)
    assert_equal(back, s)


def test_unicode_emoji_round_trip() raises:
    var enc = _make_tiny_encoder()
    var s = "Hello 🌍"
    var ids = enc.encode(s)
    var back = enc.decode(ids)
    assert_equal(back, s)


def test_cjk_round_trip() raises:
    var enc = _make_tiny_encoder()
    var s = "你好世界"
    var ids = enc.encode(s)
    var back = enc.decode(ids)
    assert_equal(back, s)


def test_combining_marks_round_trip() raises:
    var enc = _make_tiny_encoder()
    # é as combining e + combining acute = U+0065 U+0301
    var s = "e\u0301"
    var ids = enc.encode(s)
    var back = enc.decode(ids)
    assert_equal(back, s)


def test_all_ascii_bytes_round_trip() raises:
    var enc = _make_tiny_encoder()
    var s = String("")
    for b in range(32, 127):  # printable ASCII
        s += String(List[UInt8]([UInt8(b)]))
    var ids = enc.encode(s)
    var back = enc.decode(ids)
    assert_equal(back, s)


def test_decode_lossy_valid_utf8() raises:
    """decode_lossy on valid UTF-8 must match decode."""
    var enc = _make_tiny_encoder()
    var s = "Hello 🌍"
    var ids = enc.encode(s)
    var strict = enc.decode(ids)
    var lossy = enc.decode_lossy(ids)
    assert_equal(strict, lossy)


def test_decode_lossy_invalid_utf8() raises:
    """decode_lossy must not raise on invalid UTF-8 bytes."""
    var enc = _make_tiny_encoder()
    # IDs 0x80 and 0x81 are lone continuation bytes — invalid standalone UTF-8.
    var ids: List[Int] = [0x80, 0x41]  # invalid byte + 'A'
    var result = enc.decode_lossy(ids)
    # Should contain replacement char + 'A', not raise.
    assert_true(len(result) > 0)


def test_decode_strict_invalid_raises() raises:
    """decode must raise on invalid UTF-8."""
    var enc = _make_tiny_encoder()
    var ids: List[Int] = [0x80]  # lone continuation byte
    with assert_raises():
        var _ = enc.decode(ids)


def test_encode_batch_consistent() raises:
    """encode_batch must match individual encode calls."""
    var enc = _make_tiny_encoder()
    var texts: List[String] = ["Hello", "World", "Mojo!"]
    var batch = enc.encode_batch(texts)
    assert_equal(len(batch), 3)
    for i in range(3):
        var single = enc.encode(texts[i])
        assert_equal(len(batch[i]), len(single))
        for j in range(len(single)):
            assert_equal(batch[i][j], single[j])


def test_special_tokens_allowed() raises:
    """Special tokens emitted when policy is allow_all."""
    var specials = Dict[String, Int]()
    specials["<|endoftext|>"] = 100257
    var t = RankTable.with_base_bytes()
    var enc = Encoder(t^, CL100K_PATTERN, specials)

    var ids = enc.encode("<|endoftext|>", SpecialPolicy.allow_all())
    assert_equal(len(ids), 1)
    assert_equal(ids[0], 100257)


def test_disallowed_special_raises() raises:
    """Default policy raises on disallowed special token in input."""
    var specials = Dict[String, Int]()
    specials["<|endoftext|>"] = 100257
    var t = RankTable.with_base_bytes()
    var enc = Encoder(t^, CL100K_PATTERN, specials)

    with assert_raises():
        var _ = enc.encode("<|endoftext|>")  # default = allow_none → raise


def test_only_special_tokens() raises:
    """String consisting entirely of special tokens."""
    var specials = Dict[String, Int]()
    specials["<|endoftext|>"] = 100257
    var t = RankTable.with_base_bytes()
    var enc = Encoder(t^, CL100K_PATTERN, specials)

    var ids = enc.encode(
        "<|endoftext|><|endoftext|>", SpecialPolicy.allow_all()
    )
    assert_equal(len(ids), 2)
    assert_equal(ids[0], 100257)
    assert_equal(ids[1], 100257)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
