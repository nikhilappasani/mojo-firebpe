"""Hand-rolled pre-tokenizer for cl100k_base / o200k_base patterns.

Implements the GPT-4 family pre-tokenizer as a pure-Mojo byte scanner.
Reference pattern (cl100k_base, SPEC SS 5.2):

  (?i:'s|'t|'re|'ve|'m|'ll|'d)
  |[^\\r\\n\\p{L}\\p{N}]?\\p{L}+
  |\\p{N}{1,3}
  | ?[^\\s\\p{L}\\p{N}]+[\\r\\n]*
  |\\s*[\\r\\n]+
  |\\s+(?!\\S)
  |\\s+

The scanner attempts alternatives in order at each position, emitting the
longest match for the winning alternative.

Hot-path rules (RULES.md SS 2):
  - No heap allocation per call; yields Span[UInt8, _] views into the input.
  - No String construction on the hot path.
  - UTF-8 decoded to code points on the fly, no intermediate buffer.
"""

from .unicode import is_letter, is_number

# ── UTF-8 decoder helpers ──────────────────────────────────────────────────────


@always_inline
def _utf8_cp_len(b: UInt8) -> Int:
    """Return the byte length of a UTF-8 sequence starting with byte b.
    Returns 1 for invalid lead bytes (treat as single byte).
    """
    if b < 0x80:
        return 1
    if b < 0xC0:
        return 1  # continuation byte — caller handles
    if b < 0xE0:
        return 2
    if b < 0xF0:
        return 3
    return 4


@always_inline
def _decode_utf8(data: Span[UInt8, _], pos: Int) -> Tuple[Int, Int]:
    """Decode one UTF-8 code point starting at pos.
    Returns (codepoint, byte_length). On invalid sequence returns (byte, 1).
    """
    var b0 = Int(data[pos])
    var rem = len(data) - pos
    if b0 < 0x80:
        return (b0, 1)
    if b0 < 0xC0:
        return (b0, 1)  # lone continuation byte
    if b0 < 0xE0 and rem >= 2:
        var b1 = Int(data[pos + 1])
        if b1 >= 0x80 and b1 < 0xC0:
            return (((b0 & 0x1F) << 6) | (b1 & 0x3F), 2)
    if b0 < 0xF0 and rem >= 3:
        var b1 = Int(data[pos + 1])
        var b2 = Int(data[pos + 2])
        if (b1 >= 0x80 and b1 < 0xC0) and (b2 >= 0x80 and b2 < 0xC0):
            return (((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F), 3)
    if rem >= 4:
        var b1 = Int(data[pos + 1])
        var b2 = Int(data[pos + 2])
        var b3 = Int(data[pos + 3])
        if (
            (b1 >= 0x80 and b1 < 0xC0)
            and (b2 >= 0x80 and b2 < 0xC0)
            and (b3 >= 0x80 and b3 < 0xC0)
        ):
            return (
                ((b0 & 0x07) << 18)
                | ((b1 & 0x3F) << 12)
                | ((b2 & 0x3F) << 6)
                | (b3 & 0x3F),
                4,
            )
    return (b0, 1)


# ── Character class helpers ────────────────────────────────────────────────────


@always_inline
def _is_whitespace_byte(b: UInt8) -> Bool:
    """ASCII-range whitespace: space, tab, CR, LF, FF, VT."""
    return b == 0x20 or b == 0x09 or b == 0x0A or b == 0x0D or b == 0x0C or b == 0x0B


@always_inline
def _is_whitespace(cp: Int) -> Bool:
    """Unicode whitespace (covers ASCII and common Unicode spaces)."""
    if cp <= 0x7F:
        return _is_whitespace_byte(UInt8(cp))
    # Unicode spaces outside ASCII
    return (
        cp == 0x00A0  # NO-BREAK SPACE
        or cp == 0x1680
        or (cp >= 0x2000 and cp <= 0x200A)
        or cp == 0x202F
        or cp == 0x205F
        or cp == 0x3000
    )


@always_inline
def _is_newline(cp: Int) -> Bool:
    return cp == 0x0A or cp == 0x0D  # LF, CR


# ── Contraction matcher ────────────────────────────────────────────────────────

# Contractions: 's, 't, 're, 've, 'm, 'll, 'd (case-insensitive, ASCII only).
# We check for a leading apostrophe (0x27 or Unicode right-apostrophe 0x2019)
# followed by the suffix.


def _match_contraction(data: Span[UInt8, _], pos: Int) -> Int:
    """Try to match a contraction suffix at pos. Returns end position or -1."""
    var n = len(data)
    if pos >= n:
        return -1
    var b = data[pos]
    # Apostrophe: ASCII 0x27 or UTF-8 0xE2 0x80 0x99 (RIGHT SINGLE QUOTATION)
    var apos_len: Int
    if b == 0x27:
        apos_len = 1
    elif b == 0xE2 and pos + 2 < n and data[pos + 1] == 0x80 and data[pos + 2] == 0x99:
        apos_len = 3
    else:
        return -1

    var rest = pos + apos_len
    if rest >= n:
        return -1

    var c = data[rest] | 0x20  # lowercase ASCII

    # 'll, 're, 've (2-char suffix)
    if rest + 1 < n:
        var c2 = data[rest + 1] | 0x20
        if c == UInt8(ord('l')) and c2 == UInt8(ord('l')):
            return rest + 2
        if c == UInt8(ord('r')) and c2 == UInt8(ord('e')):
            return rest + 2
        if c == UInt8(ord('v')) and c2 == UInt8(ord('e')):
            return rest + 2

    # 's, 't, 'm, 'd (1-char suffix)
    if c == UInt8(ord('s')) or c == UInt8(ord('t')) or c == UInt8(ord('m')) or c == UInt8(ord('d')):
        return rest + 1

    return -1


# ── Main scanner ───────────────────────────────────────────────────────────────


@fieldwise_init
struct ScannerPreTok(Movable, Copyable, ImplicitlyCopyable):
    """Pure-Mojo pre-tokenizer implementing the GPT-4 family patterns.

    Yields (start, end) byte index pairs into the input — no copies.
    Both cl100k_base and o200k_base patterns are supported via the o200k flag.

    o200k differences from cl100k:
      - Non-newline whitespace run is Alt 1 (before contractions).
      - Letter alt's optional prefix char excludes whitespace.
      - Whitespace fallback is greedy (no \\s+(?!\\S) backtracking).
    """

    var use_o200k: Bool

    @staticmethod
    def cl100k() -> ScannerPreTok:
        """Create a scanner configured for cl100k_base."""
        return ScannerPreTok(False)

    @staticmethod
    def o200k() -> ScannerPreTok:
        """Create a scanner configured for o200k_base."""
        return ScannerPreTok(True)

    def split(self, text: Span[UInt8, _]) raises -> List[Tuple[Int, Int]]:
        """Split text into pieces. Returns (start, end) byte offsets.

        Args:
            text: Non-owning view of the UTF-8 input bytes.

        Returns:
            List of (start, end) pairs; piece = text[start:end].
        """
        var n = len(text)
        var pieces = List[Tuple[Int, Int]](capacity=n // 4 + 1)
        var pos = 0

        while pos < n:
            var end = self._next_piece(text, pos)
            if end <= pos:
                pos += 1
                continue
            pieces.append((pos, end))
            pos = end

        return pieces^

    def _next_piece(self, data: Span[UInt8, _], pos: Int) -> Int:
        """Return the end of the next piece starting at pos.

        cl100k_base alternatives:
          1. Contraction suffix (leading)
          2. Optional non-L/N/newline char then letter run
          3. Digit run (1-3)
          4. Optional space then punctuation run then trailing newlines
          5. Whitespace-only-newline run
          6. \\s+(?!\\S) — trailing whitespace before non-space
          7. \\s+ — whitespace fallback

        o200k_base alternatives (actual tiktoken pattern):
          1. Optional non-L/N/newline char then letter run + optional contraction suffix
          2. Digit run (1-3)
          3. Optional space then punctuation run then trailing [\\r\\n/]
          4. Whitespace-only-newline run
          5. \\s+(?!\\S) — trailing whitespace before non-space
          6. \\s+ — whitespace fallback

        Key o200k differences from cl100k:
          - No leading contraction alternative; contractions are suffixes of letter runs.
          - Space IS allowed as letter prefix (same as cl100k, not excluded).
          - Punctuation trailing includes '/' in addition to \\r\\n.
          - Same \\s+(?!\\S) backtracking whitespace behavior as cl100k.
        """
        var n = len(data)

        # Decode first codepoint.
        var cp_info = _decode_utf8(data, pos)
        var cp = cp_info[0]
        var cp_len = cp_info[1]

        if self.use_o200k:
            # o200k Alt 1: [^\r\n\p{L}\p{N}]?\p{L}+(contraction)?
            # Space IS allowed as optional prefix.
            var cur = pos
            var prefix_ok = (
                not is_letter(cp)
                and not is_number(cp)
                and not _is_newline(cp)
            )
            if prefix_ok:
                cur += cp_len
                if cur < n:
                    var nxt = _decode_utf8(data, cur)
                    if is_letter(nxt[0]):
                        cur += nxt[1]
                        while cur < n:
                            var nc = _decode_utf8(data, cur)
                            if not is_letter(nc[0]):
                                break
                            cur += nc[1]
                        # Optional contraction suffix (e.g., "it's" stays one piece).
                        var cont = _match_contraction(data, cur)
                        if cont > cur:
                            cur = cont
                        return cur
                # Prefix char not followed by letter — fall through.

            if is_letter(cp):
                cur = pos + cp_len
                while cur < n:
                    var nc = _decode_utf8(data, cur)
                    if not is_letter(nc[0]):
                        break
                    cur += nc[1]
                # Optional contraction suffix.
                var cont = _match_contraction(data, cur)
                if cont > cur:
                    cur = cont
                return cur

            # o200k Alt 2: \p{N}{1,3}
            if is_number(cp):
                var end = pos + cp_len
                var count = 1
                while count < 3 and end < n:
                    var nc = _decode_utf8(data, end)
                    if not is_number(nc[0]):
                        break
                    end += nc[1]
                    count += 1
                return end

            # o200k Alt 3: ?[^\s\p{L}\p{N}]+[\r\n/]*
            cur = pos
            if cp == 0x20:  # leading space
                cur += 1
                if cur >= n:
                    return cur

            var punc_start = cur
            while cur < n:
                var nc = _decode_utf8(data, cur)
                if is_letter(nc[0]) or is_number(nc[0]) or _is_whitespace(nc[0]):
                    break
                cur += nc[1]

            if cur > punc_start:
                # Trailing [\r\n/]*
                while cur < n:
                    var b = data[cur]
                    if b == 0x0A or b == 0x0D or b == 0x2F:  # LF, CR, /
                        cur += 1
                    else:
                        break
                return cur
            # leading space + no punctuation: fall through to whitespace alts

            # o200k Alt 4: \s*[\r\n]+
            cur = pos
            while cur < n and _is_whitespace(Int(data[cur])) and not _is_newline(Int(data[cur])):
                cur += 1
            if cur < n and _is_newline(Int(data[cur])):
                while cur < n and _is_newline(Int(data[cur])):
                    cur += 1
                return cur

            # o200k Alts 5 & 6: \s+(?!\S) | \s+
            if _is_whitespace(cp):
                var ws_end = pos + cp_len
                while ws_end < n:
                    var nc = _decode_utf8(data, ws_end)
                    if not _is_whitespace(nc[0]):
                        break
                    ws_end += nc[1]
                if ws_end >= n or _is_whitespace(_decode_utf8(data, ws_end)[0]):
                    return ws_end
                else:
                    var prev_pos = pos
                    var scan = pos + cp_len
                    while scan < ws_end:
                        prev_pos = scan
                        scan += _decode_utf8(data, scan)[1]
                    if prev_pos > pos:
                        return prev_pos
                    return ws_end

            # Fallback.
            return pos + cp_len

        # ── cl100k path ─────────────────────────────────────────────────────────

        # cl100k Alt 1: Contraction suffix (leading alternative).
        var cont_end = _match_contraction(data, pos)
        if cont_end > pos:
            return cont_end

        # cl100k Alt 2: [^\r\n\p{L}\p{N}]?\p{L}+
        var cur = pos
        var prefix_ok = (
            not is_letter(cp)
            and not is_number(cp)
            and not _is_newline(cp)
        )
        if prefix_ok:
            cur += cp_len
            if cur < n:
                var nxt = _decode_utf8(data, cur)
                if is_letter(nxt[0]):
                    cur += nxt[1]
                    while cur < n:
                        var nc = _decode_utf8(data, cur)
                        if not is_letter(nc[0]):
                            break
                        cur += nc[1]
                    return cur
            # Optional char not followed by letter — fall through.
            pass  # cur reset in Alt 4

        if is_letter(cp):
            cur = pos + cp_len
            while cur < n:
                var nc = _decode_utf8(data, cur)
                if not is_letter(nc[0]):
                    break
                cur += nc[1]
            return cur

        # cl100k Alt 3: \p{N}{1,3}
        if is_number(cp):
            var end = pos + cp_len
            var count = 1
            while count < 3 and end < n:
                var nc = _decode_utf8(data, end)
                if not is_number(nc[0]):
                    break
                end += nc[1]
                count += 1
            return end

        # cl100k Alt 4: ?[^\s\p{L}\p{N}]+[\r\n]*
        cur = pos
        if cp == 0x20:  # leading space
            cur += 1
            if cur >= n:
                return cur

        var punc_start = cur
        while cur < n:
            var nc = _decode_utf8(data, cur)
            if is_letter(nc[0]) or is_number(nc[0]) or _is_whitespace(nc[0]):
                break
            cur += nc[1]

        if cur > punc_start:
            # Consume trailing \r\n
            while cur < n and _is_newline(Int(data[cur])):
                cur += 1
            return cur
        # leading space + no punctuation: fall through to whitespace alts

        # cl100k Alt 5: \s*[\r\n]+
        cur = pos
        while cur < n and _is_whitespace(Int(data[cur])) and not _is_newline(Int(data[cur])):
            cur += 1
        if cur < n and _is_newline(Int(data[cur])):
            while cur < n and _is_newline(Int(data[cur])):
                cur += 1
            return cur

        # cl100k Alt 6: \s+(?!\S) — backtrack by one whitespace char when followed by non-space.
        # cl100k Alt 7: \s+ — greedy whitespace fallback.
        if _is_whitespace(cp):
            var ws_end = pos + cp_len
            while ws_end < n:
                var nc = _decode_utf8(data, ws_end)
                if not _is_whitespace(nc[0]):
                    break
                ws_end += nc[1]
            if ws_end >= n or _is_whitespace(_decode_utf8(data, ws_end)[0]):
                return ws_end
            else:
                var prev_pos = pos
                var scan = pos + cp_len
                while scan < ws_end:
                    prev_pos = scan
                    scan += _decode_utf8(data, scan)[1]
                if prev_pos > pos:
                    return prev_pos  # Alt 6
                return ws_end  # Alt 7: single whitespace char

        # Fallback: consume one byte (should not normally reach here).
        return pos + cp_len
