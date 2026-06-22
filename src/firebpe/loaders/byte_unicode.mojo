"""GPT-2 bytes↔unicode mapping for HuggingFace tokenizer.json loading.

HuggingFace ByteLevel BPE stores tokens as the GPT-2 bytes_to_unicode
printable representation rather than raw bytes. The loader must invert
this mapping at load time so the in-memory RankTable keys on raw bytes,
keeping the merge core format-agnostic (SPEC § 7.2 / ARCHITECTURE.md § 7).

The forward map (byte → char) is the exact bytes_to_unicode() from GPT-2.
The inverse map (char → byte) is used at load time.
"""

# GPT-2 bytes_to_unicode: maps 0..255 to a printable Unicode character.
# Characters 33-126 and 161-172 and 174-255 map to themselves.
# The remaining 33 control/whitespace bytes map to characters starting at 256.
#
# Precomputed as two parallel arrays: BYTE_TO_CHAR_ORD[b] = Unicode code point
# for byte b; CHAR_ORD_TO_BYTE maps the Unicode code point back to the byte.


def _build_byte_to_char() -> List[Int]:
    """Build the forward byte→char map (256 entries).

    Matches Python's bytes_to_unicode() exactly: unmapped bytes are assigned
    code points 256, 257, ... in order of their byte value (0 first).
    """
    var result = List[Int]()
    for _ in range(256):
        result.append(-1)  # -1 = unoccupied sentinel

    # Printable ASCII 33-126 map to themselves.
    for b in range(33, 127):
        result[b] = b

    # Latin-1 supplement 161-172, 174-255 map to themselves.
    for b in range(161, 173):
        result[b] = b
    for b in range(174, 256):
        result[b] = b

    # Remaining bytes (0-32, 127-160, 173) get code points 256, 257, ...
    # Processed in ascending byte order — matching Python's bytes_to_unicode.
    var n = 256
    for b in range(256):
        if result[b] == -1:
            result[b] = n
            n += 1

    return result^


def byte_to_char_table() -> List[Int]:
    """Return the forward byte→char map (256 entries). Builds on each call."""
    return _build_byte_to_char()


def build_char_to_byte() -> Dict[Int, UInt8]:
    """Build the inverse char→byte map (288 entries, since n goes to ~288)."""
    var byte_to_char = _build_byte_to_char()
    var d = Dict[Int, UInt8]()
    for b in range(256):
        d[byte_to_char[b]] = UInt8(b)
    return d^


def hf_token_str_to_bytes(token_str: String) raises -> List[UInt8]:  # no Span in sig
    """Convert a HuggingFace token string (GPT-2 printable repr) to raw bytes.

    Args:
        token_str: A token as stored in tokenizer.json (printable chars).

    Returns:
        The raw byte sequence this token represents.

    Raises:
        Error if a character in token_str is not in the 288-entry map.
    """
    var char_to_byte = build_char_to_byte()
    var result = List[UInt8]()

    for cp in token_str.codepoints():
        var cp_int = Int(cp)
        if cp_int in char_to_byte:
            result.append(char_to_byte[cp_int])
        else:
            raise Error(
                "hf_token_str_to_bytes: unexpected character U+"
                + String(cp_int)
                + " in token '"
                + token_str
                + "'"
            )

    return result^
