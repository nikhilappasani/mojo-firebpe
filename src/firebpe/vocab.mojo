"""RankTable — the central token↔bytes mapping for firebpe.

Architecture note (ARCHITECTURE.md § 2.1):
  SpanDict is a purpose-built open-addressing hash map keyed on byte spans.
  A generic Dict[String, Int] would force a String allocation on every get_rank
  call inside the merge loop — fatal for throughput. SpanDict hashes bytes
  in-place (FNV-1a) and compares by byte equality.

Hot-path rule: rank_of / id_of must never allocate. They receive Span[UInt8, _]
and return a UInt32 without constructing any intermediate container.
"""

# Sentinel value: no rank exists for this byte span.
comptime RANK_MAX: UInt32 = 0xFFFF_FFFF

# FNV-1a 32-bit constants.
comptime FNV_OFFSET: UInt32 = 2166136261
comptime FNV_PRIME: UInt32 = 16777619


@always_inline
def fnv1a_hash(data: Span[UInt8, _]) -> UInt32:
    """FNV-1a 32-bit hash over a byte span. No allocation."""
    var h: UInt32 = FNV_OFFSET
    for i in range(len(data)):
        h = (h ^ UInt32(data[i])) * FNV_PRIME
    return h


struct SpanEntry(Movable, Copyable):
    """One slot in the SpanDict open-addressing table."""

    var key: List[UInt8]   # owned copy of the key bytes
    var value: UInt32      # rank / token id
    var occupied: Bool

    def __init__(out self):
        self.key = List[UInt8]()
        self.value = 0
        self.occupied = False

    def __init__(out self, key: Span[UInt8, _], value: UInt32):
        self.key = List[UInt8]()
        for i in range(len(key)):
            self.key.append(key[i])
        self.value = value
        self.occupied = True


struct SpanDict(Movable):
    """Open-addressing hash map keyed on byte spans.

    Keys are stored as owned List[UInt8] copies. Lookups hash the query span
    in place — no intermediate String or List allocation.

    Load factor is kept <= 0.7; the table doubles when exceeded.
    """

    var _slots: List[SpanEntry]
    var _count: Int
    var _capacity: Int

    def __init__(out self, initial_capacity: Int = 256):
        # Round up to next power of two for fast modulo via bitwise AND.
        var cap = 16
        while cap < initial_capacity:
            cap *= 2
        self._capacity = cap
        self._count = 0
        self._slots = List[SpanEntry]()
        for _ in range(cap):
            self._slots.append(SpanEntry())

    def _slot_index(self, h: UInt32) -> Int:
        return Int(h & UInt32(self._capacity - 1))

    def _key_eq(self, slot_key: List[UInt8], query: Span[UInt8, _]) -> Bool:
        """Compare slot key bytes against query span."""
        if len(slot_key) != len(query):
            return False
        for i in range(len(query)):
            if slot_key[i] != query[i]:
                return False
        return True

    def insert(mut self, key: Span[UInt8, _], value: UInt32) raises:
        """Insert or overwrite a key→value mapping.

        Resizes (doubles) when load factor exceeds 0.7.
        """
        if self._count * 10 >= self._capacity * 7:
            self._resize()

        var h = fnv1a_hash(key)
        var idx = self._slot_index(h)
        var probe = 0
        while probe < self._capacity:
            if not self._slots[idx].occupied:
                self._slots[idx] = SpanEntry(key, value)
                self._count += 1
                return
            if self._key_eq(self._slots[idx].key, key):
                self._slots[idx].value = value
                return
            idx = (idx + 1) & (self._capacity - 1)
            probe += 1
        raise Error("SpanDict: table full (should not happen after resize)")

    @always_inline
    def get(self, key: Span[UInt8, _]) -> UInt32:
        """Look up a key; returns RANK_MAX if absent. No allocation."""
        var h = fnv1a_hash(key)
        var idx = self._slot_index(h)
        var probe = 0
        while probe < self._capacity:
            if not self._slots[idx].occupied:
                return RANK_MAX
            if self._key_eq(self._slots[idx].key, key):
                return self._slots[idx].value
            idx = (idx + 1) & (self._capacity - 1)
            probe += 1
        return RANK_MAX

    def _resize(mut self) raises:
        """Double the table capacity and rehash all entries."""
        var new_cap = self._capacity * 2
        var new_slots = List[SpanEntry]()
        for _ in range(new_cap):
            new_slots.append(SpanEntry())

        for i in range(self._capacity):
            if self._slots[i].occupied:
                var h = fnv1a_hash(Span[UInt8](self._slots[i].key))
                var idx = Int(h & UInt32(new_cap - 1))
                var probe = 0
                while probe < new_cap:
                    if not new_slots[idx].occupied:
                        new_slots[idx] = self._slots[i].copy()
                        break
                    idx = (idx + 1) & (new_cap - 1)
                    probe += 1

        self._slots = new_slots^
        self._capacity = new_cap

    def __len__(self) -> Int:
        return self._count


struct RankTable(Movable):
    """Maps token bytes ↔ rank/ID in both directions.

    Forward (bytes → rank): SpanDict for allocation-free hot-path lookups.
    Reverse (id → bytes): List[List[UInt8]] indexed by token ID.

    rank == id for tiktoken-format vocabs; this struct keeps them in sync.
    """

    var _bytes_to_rank: SpanDict
    var _id_to_bytes: List[List[UInt8]]
    var _n_vocab: Int

    def __init__(out self):
        self._bytes_to_rank = SpanDict(512)
        self._id_to_bytes = List[List[UInt8]]()
        self._n_vocab = 0

    def __init__(out self, capacity: Int):
        """Pre-size for a known vocab."""
        self._bytes_to_rank = SpanDict(capacity * 2)
        self._id_to_bytes = List[List[UInt8]]()
        self._n_vocab = 0

    def insert(mut self, token_bytes: Span[UInt8, _], rank: UInt32) raises:
        """Add a token. rank must equal the desired token ID.

        For the 256 base byte tokens, call insert_byte(b) instead.
        """
        self._bytes_to_rank.insert(token_bytes, rank)
        # Extend _id_to_bytes to accommodate this rank as index.
        while len(self._id_to_bytes) <= Int(rank):
            self._id_to_bytes.append(List[UInt8]())
        # Store the bytes at position `rank`.
        var blist = List[UInt8]()
        for i in range(len(token_bytes)):
            blist.append(token_bytes[i])
        self._id_to_bytes[Int(rank)] = blist^
        if Int(rank) + 1 > self._n_vocab:
            self._n_vocab = Int(rank) + 1

    def insert_byte(mut self, b: UInt8) raises:
        """Insert one of the 256 base byte tokens (rank == b)."""
        var arr = List[UInt8]()
        arr.append(b)
        self.insert(Span[UInt8](arr), UInt32(b))

    @always_inline
    def rank_of(self, span: Span[UInt8, _]) -> UInt32:
        """Return the rank (= ID for tiktoken) of a byte span, or RANK_MAX."""
        return self._bytes_to_rank.get(span)

    @always_inline
    def id_of(self, span: Span[UInt8, _]) -> Int:
        """Return the token ID for a byte span. RANK_MAX cast to Int if absent."""
        return Int(self._bytes_to_rank.get(span))

    def bytes_of(self, id: Int) -> List[UInt8]:
        """Return the bytes for a token ID as an owned copy."""
        return self._id_to_bytes[id].copy()

    def n_vocab(self) -> Int:
        return self._n_vocab

    @staticmethod
    def with_base_bytes() raises -> RankTable:
        """Build a RankTable pre-populated with the 256 base byte tokens."""
        var t = RankTable(512)
        for b in range(256):
            t.insert_byte(UInt8(b))
        return t^
