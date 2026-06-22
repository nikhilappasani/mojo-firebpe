"""BPE Trainer — trains a vocabulary from a text corpus.

Algorithm: classic byte-level BPE (SPEC § 9).
Deterministic: tie-break by lexicographically smallest pair (SPEC § 9.2).
Incremental pair counting: only affected words recount after each merge.
"""

from .vocab import RankTable
from .core import Encoder
from .pretok.scanner import ScannerPreTok
from .loaders.encodings import CL100K_PATTERN


struct WordCount(Movable, Copyable):
    """A tokenized word (as byte-token IDs) with its corpus frequency."""

    var tokens: List[Int]
    var count: Int

    def __init__(out self, var tokens: List[Int], count: Int):
        self.tokens = tokens^
        self.count = count


struct Pair(Copyable, Movable, Equatable, Hashable):
    """An adjacent token pair (a, b)."""

    var a: Int
    var b: Int

    def __init__(out self, a: Int, b: Int):
        self.a = a
        self.b = b

    def __eq__(self, other: Self) -> Bool:
        return self.a == other.a and self.b == other.b

    def __ne__(self, other: Self) -> Bool:
        return not (self == other)

    def __hash__(self) -> UInt:
        # Cantor pairing is cheap and collision-resistant for small IDs.
        return UInt((self.a + self.b) * (self.a + self.b + 1) // 2 + self.b)


struct Trainer:
    """BPE vocabulary trainer.

    Args:
        vocab_size: Target vocabulary size (must be > 256).
        pattern: Pre-tokenizer pattern (default: CL100K_PATTERN).

    Example:
        var t = Trainer(vocab_size=8000, pattern=CL100K_PATTERN)
        var enc = t.train_from_file("corpus.txt")
        enc.save_tiktoken("my_vocab.tiktoken")
    """

    var vocab_size: Int
    var pattern: String

    def __init__(out self, vocab_size: Int, pattern: String = CL100K_PATTERN):
        self.vocab_size = vocab_size
        self.pattern = pattern

    def train_from_file(self, path: String) raises -> Encoder:
        """Train from a UTF-8 text file.

        Args:
            path: Path to the corpus file.

        Returns:
            An Encoder with the trained vocabulary.
        """
        with open(path, "r") as f:
            var text = f.read()
        return self._train(text)

    def train_from_strings(self, corpus: List[String]) raises -> Encoder:
        """Train from a list of strings.

        Args:
            corpus: List of text strings.

        Returns:
            An Encoder with the trained vocabulary.
        """
        var combined = String("")
        for si in range(len(corpus)):
            combined += corpus[si]
        return self._train(combined)

    def _train(self, text: String) raises -> Encoder:
        """Core training loop (SPEC § 9.1)."""
        if self.vocab_size <= 256:
            raise Error("vocab_size must be > 256 (256 byte tokens are the base)")

        # Step 1: Pre-tokenize and count word frequencies.
        var pretok = ScannerPreTok.cl100k()
        var text_bytes = text.as_bytes()
        var span = Span[UInt8](text_bytes)
        var pieces = pretok.split(span)

        # word_freq maps raw bytes (as List[UInt8]) → count.
        # We use a string key (join bytes) for the Dict.
        var word_freq = Dict[String, Int]()
        for pi in range(len(pieces)):
            var p_start = pieces[pi][0]
            var p_end = pieces[pi][1]
            var key = String(StringSlice(unsafe_from_utf8=span[p_start:p_end]))
            if key in word_freq:
                word_freq[key] += 1
            else:
                word_freq[key] = 1

        # Step 2: Initialize with 256 byte tokens.
        # id_to_bytes[id] = byte sequence for that token.
        var id_to_bytes = List[List[UInt8]]()
        for b in range(256):
            var blist = List[UInt8]()
            blist.append(UInt8(b))
            id_to_bytes.append(blist^)

        # Step 3: Represent each unique word as a sequence of byte tokens.
        var words = List[WordCount]()
        for entry in word_freq.items():
            var raw = entry.key.as_bytes()
            var toks = List[Int]()
            for bi in range(len(raw)):
                toks.append(Int(raw[bi]))
            words.append(WordCount(toks^, entry.value))

        # Step 4: BPE merge loop.
        var next_id = 256

        while next_id < self.vocab_size:
            # Count pair frequencies.
            var pair_counts = Dict[String, Int]()
            for wi in range(len(words)):
                for i in range(len(words[wi].tokens) - 1):
                    var key = String(words[wi].tokens[i]) + "," + String(words[wi].tokens[i + 1])
                    if key in pair_counts:
                        pair_counts[key] += words[wi].count
                    else:
                        pair_counts[key] = words[wi].count

            if len(pair_counts) == 0:
                break  # No pairs remain (SPEC § 9.1 early stop).

            # Select most frequent pair; tie-break lexicographically on bytes.
            var best_key = String("")
            var best_count = 0
            var best_a = -1
            var best_b = -1

            for entry in pair_counts.items():
                var count = entry.value
                var parts = entry.key.split(",")
                var a = Int(String(parts[0]))
                var b = Int(String(parts[1]))
                var better = False
                if count > best_count:
                    better = True
                elif count == best_count:
                    # Tie-break: lexicographically smallest pair bytes.
                    # Copy to separate locals to avoid Span aliasing.
                    var ab = id_to_bytes[a].copy()
                    var bb_ = id_to_bytes[b].copy()
                    var ba = id_to_bytes[best_a].copy()
                    var bbb = id_to_bytes[best_b].copy()
                    better = self._lex_less(
                        Span[UInt8](ab),
                        Span[UInt8](bb_),
                        Span[UInt8](ba),
                        Span[UInt8](bbb),
                    )
                if better:
                    best_count = count
                    best_key = entry.key
                    best_a = a
                    best_b = b

            if best_count == 0:
                break

            # Assign new ID.
            var new_bytes = List[UInt8]()
            for bi in range(len(id_to_bytes[best_a])):
                new_bytes.append(id_to_bytes[best_a][bi])
            for bi in range(len(id_to_bytes[best_b])):
                new_bytes.append(id_to_bytes[best_b][bi])
            id_to_bytes.append(new_bytes^)
            var new_id = next_id
            next_id += 1

            # Replace pair in all words.
            for i in range(len(words)):
                words[i].tokens = self._replace_pair(
                    words[i].tokens, best_a, best_b, new_id
                )

        # Build RankTable from id_to_bytes.
        var table = RankTable(next_id * 2)
        for id in range(next_id):
            table.insert(Span[UInt8](id_to_bytes[id]), UInt32(id))

        return Encoder(table^, self.pattern, Dict[String, Int]())

    def _replace_pair(
        self, tokens: List[Int], a: Int, b: Int, new_id: Int
    ) -> List[Int]:
        """Replace all non-overlapping occurrences of (a, b) with new_id."""
        var result = List[Int]()
        var i = 0
        while i < len(tokens):
            if i + 1 < len(tokens) and tokens[i] == a and tokens[i + 1] == b:
                result.append(new_id)
                i += 2
            else:
                result.append(tokens[i])
                i += 1
        return result^

    def _lex_less(
        self,
        a1: Span[UInt8, _],
        b1: Span[UInt8, _],
        a2: Span[UInt8, _],
        b2: Span[UInt8, _],
    ) -> Bool:
        """True if concat(a1, b1) < concat(a2, b2) lexicographically."""
        var len1 = len(a1) + len(b1)
        var len2 = len(a2) + len(b2)
        var min_len = len1 if len1 < len2 else len2

        for i in range(min_len):
            var c1: UInt8
            var c2: UInt8
            if i < len(a1):
                c1 = a1[i]
            else:
                c1 = b1[i - len(a1)]
            if i < len(a2):
                c2 = a2[i]
            else:
                c2 = b2[i - len(a2)]
            if c1 < c2:
                return True
            if c1 > c2:
                return False
        return len1 < len2
