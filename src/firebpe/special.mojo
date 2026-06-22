"""Special token handling (SPEC SS 6).

Special tokens are matched on raw text before pre-tokenization, using
longest-match-wins at each position. They are never produced by the merge path.

SpecialPolicy governs encode behavior:
  - ALLOW_ALL: match and emit all known special tokens.
  - ALLOW_NONE (default): do not match special tokens; raise
    DisallowedSpecialToken if a known special string appears in input.
  - ALLOW_SET: match only the specified subset; raise for others.
"""

from .errors import raise_disallowed_special


struct SpecialPolicy(Movable, Copyable):
    var _mode: Int  # 0=none, 1=all, 2=set
    var _allowed: List[String]

    def __init__(out self, mode: Int, var allowed: List[String]):
        self._mode = mode
        self._allowed = allowed^

    @staticmethod
    def allow_all() -> SpecialPolicy:
        return SpecialPolicy(1, List[String]())

    @staticmethod
    def allow_none() -> SpecialPolicy:
        return SpecialPolicy(0, List[String]())

    @staticmethod
    def allow_set(tokens: List[String]) -> SpecialPolicy:
        return SpecialPolicy(2, tokens.copy())

    def is_allowed(self, token: String) -> Bool:
        if self._mode == 1:
            return True
        if self._mode == 0:
            return False
        for i in range(len(self._allowed)):
            if self._allowed[i] == token:
                return True
        return False

    def is_all(self) -> Bool:
        return self._mode == 1

    def is_none(self) -> Bool:
        return self._mode == 0


struct SpecialTable(Movable):
    """Bidirectional special token mapping: string SS ID.

    Matching uses longest-match-wins scan (SPEC SS 6).
    """

    var _str_to_id: Dict[String, Int]
    var _id_to_str: Dict[Int, String]
    var _tokens: List[String]  # sorted by length descending for longest-match

    def __init__(out self):
        self._str_to_id = Dict[String, Int]()
        self._id_to_str = Dict[Int, String]()
        self._tokens = List[String]()

    def __init__(out self, mapping: Dict[String, Int]):
        self._str_to_id = mapping.copy()
        self._id_to_str = Dict[Int, String]()
        self._tokens = List[String]()
        for entry in mapping.items():
            self._id_to_str[entry.value] = entry.key
            self._tokens.append(entry.key)
        self._sort_tokens_by_length_desc()

    def _sort_tokens_by_length_desc(mut self):
        """Insertion sort (small N)."""
        var n = len(self._tokens)
        for i in range(1, n):
            var key = self._tokens[i]
            var j = i - 1
            while j >= 0 and self._tokens[j].byte_length() < key.byte_length():
                self._tokens[j + 1] = self._tokens[j]
                j -= 1
            self._tokens[j + 1] = key

    def contains(self, token: String) -> Bool:
        return token in self._str_to_id

    def id_of(self, token: String) raises -> Optional[Int]:
        if token in self._str_to_id:
            return self._str_to_id[token]
        return None

    def str_of(self, id: Int) -> Optional[String]:
        if id in self._id_to_str:
            return self._id_to_str[id]
        return None

    def is_empty(self) -> Bool:
        return len(self._tokens) == 0

    def match_at(
        self,
        text: String,
        pos: Int,
        policy: SpecialPolicy,
    ) raises -> Tuple[String, Int]:
        """Try to match a special token at byte position pos in text.

        Returns (token_string, end_pos) or ("", -1) if none.
        Raises DisallowedSpecialToken if a disallowed special is found.
        """
        var n = text.byte_length()
        var text_bytes = text.as_bytes()
        var best_token = String("")
        var best_end = -1

        for ti in range(len(self._tokens)):
            var t = self._tokens[ti]
            var t_bytes = t.as_bytes()
            var t_len = t.byte_length()
            if pos + t_len > n:
                continue
            var ok = True
            for i in range(t_len):
                if text_bytes[pos + i] != t_bytes[i]:
                    ok = False
                    break
            if not ok:
                continue

            if policy.is_allowed(t):
                if t_len > best_end - pos:
                    best_token = t
                    best_end = pos + t_len
            else:
                raise_disallowed_special(t, pos)

        return (best_token, best_end)
