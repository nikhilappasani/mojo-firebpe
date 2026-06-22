"""Unit tests for RankTable and SpanDict (vocab.mojo)."""

from std.testing import assert_equal, assert_true, TestSuite
from firebpe.vocab import RankTable, SpanDict, RANK_MAX


def test_span_dict_insert_and_get() raises:
    var d = SpanDict()
    var key: List[UInt8] = [65, 66, 67]
    d.insert(Span[UInt8](key), UInt32(42))
    assert_equal(d.get(Span[UInt8](key)), UInt32(42))


def test_span_dict_missing_key() raises:
    var d = SpanDict()
    var key: List[UInt8] = [1, 2, 3]
    assert_equal(d.get(Span[UInt8](key)), RANK_MAX)


def test_span_dict_overwrite() raises:
    var d = SpanDict()
    var key: List[UInt8] = [10]
    d.insert(Span[UInt8](key), UInt32(1))
    d.insert(Span[UInt8](key), UInt32(99))
    assert_equal(d.get(Span[UInt8](key)), UInt32(99))


def test_span_dict_resize() raises:
    """Insert enough entries to force a resize."""
    var d = SpanDict(16)
    for i in range(50):
        var key: List[UInt8] = [UInt8(i)]
        d.insert(Span[UInt8](key), UInt32(i))
    for i in range(50):
        var key: List[UInt8] = [UInt8(i)]
        assert_equal(d.get(Span[UInt8](key)), UInt32(i))


def test_rank_table_base_bytes() raises:
    var t = RankTable.with_base_bytes()
    assert_equal(t.n_vocab(), 256)
    for b in range(256):
        var key: List[UInt8] = [UInt8(b)]
        assert_equal(t.rank_of(Span[UInt8](key)), UInt32(b))


def test_rank_table_insert_merged() raises:
    var t = RankTable.with_base_bytes()
    var merged: List[UInt8] = [65, 66]
    t.insert(Span[UInt8](merged), UInt32(300))
    assert_equal(t.rank_of(Span[UInt8](merged)), UInt32(300))
    assert_equal(t.n_vocab(), 301)


def test_rank_table_bytes_of() raises:
    var t = RankTable.with_base_bytes()
    var b = t.bytes_of(65)
    assert_equal(len(b), 1)
    assert_equal(b[0], UInt8(65))


def test_rank_table_absent() raises:
    var t = RankTable.with_base_bytes()
    var key: List[UInt8] = [65, 66]  # not inserted
    assert_equal(t.rank_of(Span[UInt8](key)), RANK_MAX)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
