"""Python `regex` fallback pre-tokenizer (opt-in).

Only active when Encoder is constructed with use_python_regex=True.
Requires the `pyregex` pixi environment (python >=3.11, regex package).

This file is the ONLY place in firebpe that may import Python.
(RULES.md § 2 rule 4: no hidden Python on the pure-Mojo path.)
"""

from std.python import Python, PythonObject


struct PyRegexPreTok:
    """Pre-tokenizer backed by the Python `regex` module.

    This is the reference implementation used for scanner parity validation
    (RULES.md § 5.3). It is slower than ScannerPreTok due to the interop
    boundary but guarantees exact pattern semantics.

    Args:
        pattern: The regex pattern string (cl100k_base or o200k_base).
    """

    var _re: PythonObject   # compiled regex.Pattern object

    def __init__(out self, pattern: String) raises:
        var regex_mod = Python.import_module("regex")
        self._re = regex_mod.compile(pattern)

    def split(self, text: Span[UInt8]) raises -> List[Tuple[Int, Int]]:
        """Split text into (start, end) byte offset pairs.

        Converts the byte span to a Python str, runs finditer, and converts
        match byte offsets back. UTF-8 round-trip is safe here because the
        Python `regex` module also operates on str (Unicode), and the offsets
        returned are character-based — we convert back to byte offsets.
        """
        # Build a Python bytes object from the span, then decode to str.
        # We need byte offsets; Python str indexing is code-point-based.
        # Strategy: pass as bytes and use bytes pattern matching.
        var py = Python.import_module("builtins")

        # Build Python bytes from span.
        var byte_list = Python.list()
        for i in range(len(text)):
            byte_list.append(Int(text[i]))
        var py_bytes = py.bytes(byte_list)

        # Decode to str for regex (regex operates on str).
        var py_str = py_bytes.decode("utf-8", "surrogatepass")

        # Find all matches.
        var matches = self._re.finditer(py_str)
        var pieces = List[Tuple[Int, Int]]()

        # We need byte offsets, not char offsets.
        # Build a char→byte offset map.
        var n = len(text)
        var char_to_byte = List[Int]()
        var byte_pos = 0
        while byte_pos < n:
            char_to_byte.append(byte_pos)
            var b = text[byte_pos]
            var cp_len: Int
            if b < 0x80:
                cp_len = 1
            elif b < 0xC0:
                cp_len = 1
            elif b < 0xE0:
                cp_len = 2
            elif b < 0xF0:
                cp_len = 3
            else:
                cp_len = 4
            byte_pos += cp_len
        # Sentinel for end
        char_to_byte.append(n)

        for match in matches:
            var char_start = Int(match.start())
            var char_end = Int(match.end())
            var byte_start = char_to_byte[char_start]
            var byte_end = char_to_byte[char_end]
            pieces.append((byte_start, byte_end))

        return pieces^
