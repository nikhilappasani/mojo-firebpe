"""Encoder — the public face of firebpe.

Orchestrates: special-token scan → pre-tokenizer → byte_pair_merge → IDs.

SPEC § 3.2 / § 3.3 / § 10.
"""

from .vocab import RankTable
from .merge import byte_pair_merge
from .special import SpecialTable, SpecialPolicy
from .pretok.scanner import ScannerPreTok
from .errors import raise_invalid_utf8
from .loaders.tiktoken import load_tiktoken_ranks
from .loaders.hf_json import load_hf_json, load_hf_json_full
from .loaders.encodings import pattern_for, special_tokens_for, O200K_PATTERN


struct Encoder(Movable):
    """Byte-level BPE tokenizer (tiktoken-compatible).

    Encode text to token IDs; decode IDs back to text.
    Load from .tiktoken rank files or HuggingFace tokenizer.json.

    Example:
        var enc = Encoder.from_tiktoken(
            "cl100k_base.tiktoken", CL100K_PATTERN, cl100k_special_tokens()
        )
        var ids = enc.encode("Hello, world!")
        var text = enc.decode(ids)
    """

    var ranks: RankTable
    var pattern: String
    var specials: SpecialTable
    var _pretok: ScannerPreTok

    def __init__(
        out self,
        var ranks: RankTable,
        pattern: String,
        specials: Dict[String, Int],
    ):
        self.ranks = ranks^
        self.pattern = pattern
        self.specials = SpecialTable(specials)
        self._pretok = ScannerPreTok(pattern == O200K_PATTERN)

    # ── Loaders ──────────────────────────────────────────────────────────────

    @staticmethod
    def from_tiktoken(
        ranks_path: String,
        pattern: String,
        special_tokens: Dict[String, Int],
    ) raises -> Encoder:
        """Load an Encoder from a .tiktoken rank file.

        Args:
            ranks_path: Path to the .tiktoken file.
            pattern: Pre-tokenizer regex pattern (use CL100K_PATTERN etc.).
            special_tokens: Map of special token string → ID.

        Returns:
            A ready-to-use Encoder.

        Raises:
            MalformedRankFile on parse errors.
            Error on IO failures.
        """
        var table = load_tiktoken_ranks(ranks_path)
        return Encoder(table^, pattern, special_tokens)

    @staticmethod
    def from_hf_json(path: String) raises -> Encoder:
        """Load an Encoder from a HuggingFace tokenizer.json file.

        Args:
            path: Path to tokenizer.json.

        Returns:
            A ready-to-use Encoder.

        Raises:
            UnsupportedConfig for unsupported tokenizer configs.
            MalformedJson for missing/invalid fields.
            Error on IO failures.
        """
        var specials = Dict[String, Int]()
        var table = load_hf_json_full(path, specials)
        return Encoder(table^, "ByteLevel", specials^)

    # ── Encode ────────────────────────────────────────────────────────────────

    def encode(self, text: String) raises -> List[Int]:
        """Encode text to token IDs using the default (allow_none) policy.

        Raises DisallowedSpecialToken if any known special token appears.
        """
        return self._encode_impl(text, SpecialPolicy.allow_none())

    def encode(
        self, text: String, allowed_special: SpecialPolicy
    ) raises -> List[Int]:
        """Encode text to token IDs with a custom special-token policy.

        Args:
            text: Input text (UTF-8).
            allowed_special: Controls whether special tokens are matched/emitted.

        Returns:
            List of integer token IDs.
        """
        return self._encode_impl(text, allowed_special)

    def encode_batch(self, texts: List[String]) raises -> List[List[Int]]:
        """Encode a batch of texts. Each text is encoded independently.

        Args:
            texts: List of input strings.

        Returns:
            List of token ID lists, one per input.
        """
        var results = List[List[Int]]()
        for i in range(len(texts)):
            results.append(self._encode_impl(texts[i], SpecialPolicy.allow_none()))
        return results^

    def _encode_impl(
        self, text: String, policy: SpecialPolicy
    ) raises -> List[Int]:
        """Core encode implementation."""
        var out = List[Int]()
        var text_bytes = text.as_bytes()
        var n = len(text_bytes)
        var pos = 0

        while pos < n:
            # Try special token match at current position (if table non-empty).
            if not self.specials.is_empty():
                var m = self.specials.match_at(text, pos, policy)
                var tok = m[0]
                var end = m[1]
                if end > pos:
                    var id_opt = self.specials.id_of(tok)
                    if id_opt:
                        out.append(id_opt.value())
                    pos = end
                    continue

            # Find end of non-special span (up to next special or end of text).
            var span_end = n
            if not self.specials.is_empty() and not policy.is_none():
                span_end = self._next_special_pos(text, pos, n)

            # Pre-tokenize the non-special span.
            var span = Span[UInt8](text_bytes)[pos:span_end]
            var pieces = self._pretok.split(span)

            for pi in range(len(pieces)):
                var p_start = pieces[pi][0]
                var p_end = pieces[pi][1]
                var piece = span[p_start:p_end]
                var piece_ids = byte_pair_merge(piece, self.ranks)
                for ki in range(len(piece_ids)):
                    out.append(piece_ids[ki])

            pos = span_end

        return out^

    def _next_special_pos(self, text: String, start: Int, end: Int) -> Int:
        """Find the byte offset of the next special token at or after start."""
        var n = text.byte_length()
        var pos = start
        var text_bytes = text.as_bytes()
        while pos < end:
            for ti in range(len(self.specials._tokens)):
                var t = self.specials._tokens[ti]
                var t_bytes = t.as_bytes()
                var t_len = t.byte_length()
                if pos + t_len > n:
                    continue
                var matches = True
                for i in range(t_len):
                    if text_bytes[pos + i] != t_bytes[i]:
                        matches = False
                        break
                if matches:
                    return pos
            pos += 1
        return end

    # ── Decode ────────────────────────────────────────────────────────────────

    def decode(self, ids: List[Int]) raises -> String:
        """Decode token IDs to text (strict UTF-8).

        Args:
            ids: List of token IDs from encode.

        Returns:
            The decoded UTF-8 string.

        Raises:
            InvalidUtf8 if the concatenated bytes are not valid UTF-8.
        """
        var raw = self._ids_to_bytes(ids)
        return self._bytes_to_string_strict(raw)

    def decode_lossy(self, ids: List[Int]) -> String:
        """Decode token IDs to text, replacing invalid UTF-8 with U+FFFD.

        Never raises. For any encode() output, this is identical to decode().
        """
        var raw = self._ids_to_bytes(ids)
        return self._bytes_to_string_lossy(raw)

    def _ids_to_bytes(self, ids: List[Int]) -> List[UInt8]:
        var raw = List[UInt8]()
        for i in range(len(ids)):
            var tok_bytes = self.ranks.bytes_of(ids[i])
            for j in range(len(tok_bytes)):
                raw.append(tok_bytes[j])
        return raw^

    def _bytes_to_string_strict(self, raw: List[UInt8]) raises -> String:
        """Convert bytes to String, raising on invalid UTF-8."""
        # Validate UTF-8 before building the String.
        var i = 0
        var n = len(raw)
        while i < n:
            var b = raw[i]
            var seq_len: Int
            if b < 0x80:
                seq_len = 1
            elif b < 0xC0:
                raise_invalid_utf8(i)
                seq_len = 1  # unreachable
            elif b < 0xE0:
                seq_len = 2
            elif b < 0xF0:
                seq_len = 3
            else:
                seq_len = 4

            if i + seq_len > n:
                raise_invalid_utf8(i)

            for j in range(1, seq_len):
                if raw[i + j] < 0x80 or raw[i + j] >= 0xC0:
                    raise_invalid_utf8(i)

            i += seq_len

        return String(StringSlice(unsafe_from_utf8=Span[UInt8](raw)))

    def _bytes_to_string_lossy(self, raw: List[UInt8]) -> String:
        """Convert bytes to String, replacing invalid UTF-8 with U+FFFD."""
        var out = List[UInt8]()
        var i = 0
        var n = len(raw)

        while i < n:
            var b = raw[i]
            var seq_len: Int
            if b < 0x80:
                seq_len = 1
            elif b < 0xC0:
                # Lone continuation byte.
                out.append(0xEF); out.append(0xBF); out.append(0xBD)
                i += 1
                continue
            elif b < 0xE0:
                seq_len = 2
            elif b < 0xF0:
                seq_len = 3
            else:
                seq_len = 4

            var valid = True
            if i + seq_len > n:
                valid = False
            else:
                for j in range(1, seq_len):
                    if raw[i + j] < 0x80 or raw[i + j] >= 0xC0:
                        valid = False
                        break

            if valid:
                for j in range(seq_len):
                    out.append(raw[i + j])
                i += seq_len
            else:
                out.append(0xEF); out.append(0xBF); out.append(0xBD)
                i += 1

        return String(StringSlice(unsafe_from_utf8=Span[UInt8](out)))

    # ── Vocab info ────────────────────────────────────────────────────────────

    def n_vocab(self) -> Int:
        """Total vocabulary size (mergeable tokens + special tokens)."""
        return self.ranks.n_vocab() + len(self.specials._str_to_id)

    # ── Save ──────────────────────────────────────────────────────────────────

    def save_tiktoken(self, path: String) raises:
        """Save the encoder's rank table as a .tiktoken file.

        Format: one line per token: <base64(bytes)> <rank>
        Special tokens are NOT written (they are supplied by encoding defs).
        """
        var content = String("")
        var n = self.ranks.n_vocab()
        for id in range(n):
            var tok_bytes = self.ranks.bytes_of(id)
            var b64 = _base64_encode(Span[UInt8](tok_bytes))
            content += b64 + " " + String(id) + "\n"

        with open(path, "w") as f:
            f.write(content)


def _base64_encode(data: Span[UInt8, _]) -> String:
    """Encode bytes to base64 string."""
    comptime TABLE: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    var result = String("")
    var n = len(data)
    var i = 0

    while i + 2 < n:
        var b0 = Int(data[i])
        var b1 = Int(data[i + 1])
        var b2 = Int(data[i + 2])
        result += String(TABLE[byte=(b0 >> 2)])
        result += String(TABLE[byte=((b0 & 3) << 4) | (b1 >> 4)])
        result += String(TABLE[byte=((b1 & 0xF) << 2) | (b2 >> 6)])
        result += String(TABLE[byte=(b2 & 0x3F)])
        i += 3

    if i + 1 == n:
        var b0 = Int(data[i])
        result += String(TABLE[byte=(b0 >> 2)])
        result += String(TABLE[byte=(b0 & 3) << 4])
        result += "=="
    elif i + 2 == n:
        var b0 = Int(data[i])
        var b1 = Int(data[i + 1])
        result += String(TABLE[byte=(b0 >> 2)])
        result += String(TABLE[byte=((b0 & 3) << 4) | (b1 >> 4)])
        result += String(TABLE[byte=(b1 & 0xF) << 2])
        result += "="

    return result
