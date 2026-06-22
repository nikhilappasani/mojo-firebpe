"""Loader for .tiktoken rank files.

File format (SPEC § 7.1):
  Each line: <base64(token_bytes)> <rank>
  rank == token ID for tiktoken-format files.
  The file contains only mergeable ranks; pattern + specials are supplied
  by the caller (from encodings.mojo).

This module provides:
  load_tiktoken_ranks(path) -> RankTable
"""

from std.os import open as os_open
from ..vocab import RankTable, RANK_MAX
from ..errors import raise_malformed_rank_file

# ── Minimal base64 decoder ────────────────────────────────────────────────────
# We implement base64 decoding inline to avoid a Python dependency on the
# pure-Mojo path. Standard base64 alphabet only (no URL-safe variant needed).

comptime _B64_TABLE: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


def _b64_value(c: UInt8) raises -> Int:
    """Return the 6-bit value for a base64 character, or -1 for '='."""
    if c == UInt8(ord('=')):
        return -1
    if c >= UInt8(ord('A')) and c <= UInt8(ord('Z')):
        return Int(c) - ord('A')
    if c >= UInt8(ord('a')) and c <= UInt8(ord('z')):
        return Int(c) - ord('a') + 26
    if c >= UInt8(ord('0')) and c <= UInt8(ord('9')):
        return Int(c) - ord('0') + 52
    if c == UInt8(ord('+')):
        return 62
    if c == UInt8(ord('/')):
        return 63
    raise Error("Invalid base64 character: " + String(Int(c)))


def base64_decode(encoded: String) raises -> List[UInt8]:  # no Span in sig
    """Decode a standard base64 string to raw bytes.

    Args:
        encoded: Base64-encoded string (may have '=' padding).

    Returns:
        Decoded bytes.

    Raises:
        Error on invalid base64 characters.
    """
    var result = List[UInt8]()
    var n = encoded.byte_length()
    var bytes = encoded.as_bytes()
    var i = 0

    while i + 3 < n:
        var b0 = _b64_value(bytes[i])
        var b1 = _b64_value(bytes[i + 1])
        var b2 = _b64_value(bytes[i + 2])
        var b3 = _b64_value(bytes[i + 3])

        result.append(UInt8((b0 << 2) | (b1 >> 4)))
        if b2 != -1:
            result.append(UInt8(((b1 & 0xF) << 4) | (b2 >> 2)))
        if b3 != -1:
            result.append(UInt8(((b2 & 0x3) << 6) | b3))
        i += 4

    return result^


# ── Rank file loader ──────────────────────────────────────────────────────────


def load_tiktoken_ranks(path: String) raises -> RankTable:
    """Load a .tiktoken rank file into a RankTable.

    Each non-empty line must be: <base64_token> <integer_rank>
    Blank lines are skipped. Any other format raises MalformedRankFile.

    Args:
        path: Filesystem path to the .tiktoken file.

    Returns:
        Populated RankTable (base byte tokens NOT pre-inserted; only
        the ranks from the file are loaded, which includes byte tokens
        as rank 0..255 for well-formed tiktoken files).

    Raises:
        MalformedRankFile on parse errors.
        Error on IO failures.
    """
    var content = String()
    with open(path, "r") as f:
        content = f.read()

    var table = RankTable(131072)  # cl100k has ~100k tokens
    var line_num = 0

    for line_slice in content.split("\n"):
        line_num += 1
        var line = String(line_slice).strip()
        if len(line) == 0:
            continue

        # Split on space: "b64token rank"
        var parts = line.split(" ")
        if len(parts) != 2:
            raise_malformed_rank_file(
                line_num, "expected '<base64> <rank>', got: " + line
            )

        var b64_token = String(parts[0])
        var rank_str = String(parts[1]).strip()

        # Parse rank.
        var rank: Int = 0
        try:
            rank = Int(rank_str)
        except:
            raise_malformed_rank_file(
                line_num, "rank is not an integer: " + rank_str
            )

        # Decode token bytes.
        var token_bytes = base64_decode(b64_token)
        table.insert(Span[UInt8](token_bytes), UInt32(rank))

    return table^
