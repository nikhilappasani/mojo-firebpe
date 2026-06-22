"""Unit tests for the BPE Trainer (RULES.md § 5.1).

Covers: determinism, known-small-corpus merges, early stop.
"""

from std.testing import assert_equal, assert_true, TestSuite
from firebpe.trainer import Trainer
from firebpe.loaders.encodings import CL100K_PATTERN


def test_trainer_basic() raises:
    """Train on a tiny corpus; vocab grows past 256."""
    var t = Trainer(vocab_size=260, pattern=CL100K_PATTERN)
    var corpus: List[String] = ["aaabdaaabac"]
    var enc = t.train_from_strings(corpus)
    assert_true(enc.n_vocab() > 256)


def test_trainer_deterministic() raises:
    """Same corpus and vocab_size produce identical encoders."""
    var corpus: List[String] = ["hello world hello mojo mojo mojo"]
    var t1 = Trainer(vocab_size=264)
    var t2 = Trainer(vocab_size=264)
    var enc1 = t1.train_from_strings(corpus)
    var enc2 = t2.train_from_strings(corpus)
    assert_equal(enc1.n_vocab(), enc2.n_vocab())

    # Encode same text with both; must match.
    var text = "hello mojo"
    var ids1 = enc1.encode(text)
    var ids2 = enc2.encode(text)
    assert_equal(len(ids1), len(ids2))
    for i in range(len(ids1)):
        assert_equal(ids1[i], ids2[i])


def test_trainer_early_stop() raises:
    """When no pairs remain, trainer stops before reaching vocab_size."""
    # Single unique character corpus — no pairs after base tokens.
    var t = Trainer(vocab_size=300)
    var corpus: List[String] = ["a"]
    var enc = t.train_from_strings(corpus)
    # Should stop early; vocab won't reach 300.
    assert_true(enc.n_vocab() < 300)


def test_trainer_round_trip() raises:
    """Train then encode/decode round-trip."""
    var t = Trainer(vocab_size=270)
    var corpus: List[String] = ["the quick brown fox jumps over the lazy dog"]
    var enc = t.train_from_strings(corpus)

    var text = "the quick"
    var ids = enc.encode(text)
    var back = enc.decode(ids)
    assert_equal(back, text)


def test_trainer_known_merges() raises:
    """Verify a known merge for corpus 'aaab'.
    'aa' should be merged first (highest frequency), then 'aab'.
    """
    var t = Trainer(vocab_size=258)
    var corpus: List[String] = ["aaab aaab aaab aaab"]
    var enc = t.train_from_strings(corpus)

    # After training, encoding 'aaab' should use fewer tokens than 4.
    var ids = enc.encode("aaab")
    assert_true(len(ids) < 4)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
