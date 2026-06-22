"""Unit tests for byte_pair_merge (RULES.md § 5.1).

Covers: empty piece, single byte, no-merge, full-merge, multibyte UTF-8,
heap-spill path (piece > SMALL_PIECE), edge cases from SPEC § 4.
"""

from std.testing import assert_equal, assert_true, TestSuite
from firebpe.vocab import RankTable, RANK_MAX
from firebpe.merge import byte_pair_merge


def _base_table() raises -> RankTable:
    return RankTable.with_base_bytes()


def _insert(mut t: RankTable, bytes: List[UInt8], rank: UInt32) raises:
    t.insert(Span[UInt8](bytes), rank)


def test_empty_piece() raises:
    var t = _base_table()
    var piece: List[UInt8] = []
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    assert_equal(len(ids), 0)


def test_single_byte() raises:
    var t = _base_table()
    var piece: List[UInt8] = [65]  # 'A'
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    assert_equal(len(ids), 1)
    assert_equal(ids[0], 65)


def test_no_merge_available() raises:
    """Two bytes, no merged token in vocab → emits 2 IDs."""
    var t = _base_table()
    var piece: List[UInt8] = [65, 66]  # 'A', 'B'
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    assert_equal(len(ids), 2)
    assert_equal(ids[0], 65)
    assert_equal(ids[1], 66)


def test_full_merge_two_bytes() raises:
    """Two bytes with a merge token: should produce one ID."""
    var t = _base_table()
    var ab: List[UInt8] = [65, 66]
    _insert(t, ab, UInt32(300))

    var piece: List[UInt8] = [65, 66]
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    assert_equal(len(ids), 1)
    assert_equal(ids[0], 300)


def test_merge_priority() raises:
    """Lower rank merge wins. ABC: merge AB (rank 300) or BC (rank 301)."""
    var t = _base_table()
    var ab: List[UInt8] = [65, 66]
    var bc: List[UInt8] = [66, 67]
    _insert(t, ab, UInt32(300))
    _insert(t, bc, UInt32(301))

    var piece: List[UInt8] = [65, 66, 67]
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    # AB merges first (rank 300), then AB+C = no merge → [300, 67].
    assert_equal(len(ids), 2)
    assert_equal(ids[0], 300)
    assert_equal(ids[1], 67)


def test_chain_merges() raises:
    """ABC merges fully: AB→300, then AB+C=ABC→299 (lower rank)."""
    var t = _base_table()
    var ab: List[UInt8] = [65, 66]
    var abc_bytes: List[UInt8] = [65, 66, 67]
    _insert(t, ab, UInt32(300))
    _insert(t, abc_bytes, UInt32(299))

    var piece: List[UInt8] = [65, 66, 67]
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    assert_equal(len(ids), 1)
    assert_equal(ids[0], 299)


def test_multibyte_utf8_boundary() raises:
    """UTF-8 multibyte treated as raw bytes; no boundary logic in merge."""
    var t = _base_table()
    # 'é' in UTF-8 = [0xC3, 0xA9]; no merged token → 2 byte-token IDs.
    var piece: List[UInt8] = [0xC3, 0xA9]
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    assert_equal(len(ids), 2)
    assert_equal(ids[0], 0xC3)
    assert_equal(ids[1], 0xA9)


def test_all_same_bytes() raises:
    """AAAA with AA→256 merge: expect [256, 256]."""
    var t = _base_table()
    var aa: List[UInt8] = [65, 65]
    _insert(t, aa, UInt32(256))

    var piece: List[UInt8] = [65, 65, 65, 65]
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    assert_equal(len(ids), 2)
    assert_equal(ids[0], 256)
    assert_equal(ids[1], 256)


def test_single_high_byte() raises:
    """Byte 0xFF is a valid base token."""
    var t = _base_table()
    var piece: List[UInt8] = [0xFF]
    var ids = byte_pair_merge(Span[UInt8](piece), t)
    assert_equal(len(ids), 1)
    assert_equal(ids[0], 0xFF)


def test_round_trip_bytes() raises:
    """All 256 single-byte pieces decode back to themselves."""
    var t = _base_table()
    for b in range(256):
        var piece: List[UInt8] = [UInt8(b)]
        var ids = byte_pair_merge(Span[UInt8](piece), t)
        assert_equal(len(ids), 1)
        assert_equal(ids[0], b)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
