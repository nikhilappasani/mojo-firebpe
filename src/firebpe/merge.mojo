"""byte_pair_merge — the BPE hot path.

Matches tiktoken's _byte_pair_merge semantics exactly.

Key insight vs naive SPEC reading:
  parts[i].rank = rank of piece[parts[i].start : parts[i+2].start]
  i.e. rank of (part_i bytes ++ part_i+1 bytes concatenated).

  After merging i with i+1 (deleting parts[i+1]):
  - parts[i].rank must become rank of piece[parts[i].start : NEW_parts[i+2].start]
                                    = piece[parts[i].start : OLD_parts[i+3].start]
  So the update uses parts[i+3] (not i+2) — equivalent to tiktoken's skip=1.

Hot-path rules (RULES.md § 2):
  - No String construction. All operations on Span[UInt8, _].
  - get_rank is @always_inline.
"""

from .vocab import RankTable, RANK_MAX

comptime SMALL_PIECE: Int = 64


@fieldwise_init
struct Part(Copyable, Movable, ImplicitlyCopyable):
    var start: UInt32
    var rank: UInt32


@always_inline
def _get_rank(
    piece: Span[UInt8, _],
    ranks: RankTable,
    lo: Int,
    hi: Int,
) -> UInt32:
    """Return rank of piece[lo:hi], or RANK_MAX if out of range or absent."""
    if hi > len(piece):
        return RANK_MAX
    return ranks.rank_of(piece[lo:hi])


@always_inline
def _rank_for_update(
    piece: Span[UInt8, _],
    ranks: RankTable,
    parts: List[Part],
    i: Int,
) -> UInt32:
    """Rank for parts[i] after a merge — uses parts[i+3] (skip=1 in tiktoken).

    Returns RANK_MAX when i+3 >= len(parts) (parts[i+2] would be sentinel
    or out of bounds after the deletion that follows).
    """
    if i + 3 >= len(parts):
        return RANK_MAX
    var lo = Int(parts[i].start)
    var hi = Int(parts[i + 3].start)
    return _get_rank(piece, ranks, lo, hi)


@always_inline
def _rank_for_prev_update(
    piece: Span[UInt8, _],
    ranks: RankTable,
    parts: List[Part],
    i: Int,
) -> UInt32:
    """Rank for parts[i-1] after a merge at i — uses parts[i+2] (skip=1).

    After deletion of parts[i+1]:
      new_parts[i-1].rank = rank of piece[parts[i-1].start : old_parts[i+2].start]
    """
    if i + 2 >= len(parts):
        return RANK_MAX
    var lo = Int(parts[i - 1].start)
    var hi = Int(parts[i + 2].start)
    return _get_rank(piece, ranks, lo, hi)


def byte_pair_merge(piece: Span[UInt8, _], ranks: RankTable) raises -> List[Int]:
    """Encode one pre-tokenized piece to a list of token IDs.

    Args:
        piece: Non-owning view of the UTF-8 bytes of the piece.
        ranks: The loaded rank/vocab table.

    Returns:
        List of token IDs (ranks) that cover the piece.
    """
    var n = len(piece)
    if n == 0:
        return List[Int]()

    if n == 1:
        var out = List[Int]()
        out.append(ranks.id_of(piece))
        return out^

    # Initialize parts: one per byte plus sentinel.
    # parts[i].rank = rank of piece[parts[i].start : parts[i+2].start]
    #               = rank of concatenated bytes of part_i and part_i+1.
    var parts = List[Part](capacity=n + 1)
    for i in range(n):
        # Check i+2 < len(parts_after_init) = n+1  →  i+2 < n+1  →  i+1 < n
        var r: UInt32
        if i + 2 <= n:
            r = _get_rank(piece, ranks, i, i + 2)
        else:
            r = RANK_MAX
        parts.append(Part(UInt32(i), r))
    parts.append(Part(UInt32(n), RANK_MAX))  # sentinel

    # Merge loop: repeatedly merge the minimum-rank adjacent pair.
    while True:
        var min_rank: UInt32 = RANK_MAX
        var min_pos: Int = -1
        var p_len = len(parts)
        for j in range(p_len - 1):
            if parts[j].rank < min_rank:
                min_rank = parts[j].rank
                min_pos = j

        if min_rank == RANK_MAX:
            break

        var i = min_pos

        # Update ranks BEFORE deleting parts[i+1].
        # parts[i].rank: uses parts[i+3] (skip=1) — see module docstring.
        parts[i].rank = _rank_for_update(piece, ranks, parts, i)

        if i > 0:
            parts[i - 1].rank = _rank_for_prev_update(piece, ranks, parts, i)

        # Delete parts[i+1] in-place (shift left, pop tail).
        _ = parts.pop(i + 1)

    # Emit token IDs from surviving parts.
    var out = List[Int](capacity=len(parts) - 1)
    for j in range(len(parts) - 1):
        var lo = Int(parts[j].start)
        var hi = Int(parts[j + 1].start)
        out.append(ranks.id_of(piece[lo:hi]))

    return out^
