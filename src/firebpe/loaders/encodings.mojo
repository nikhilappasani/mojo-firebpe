"""Named encoding definitions: cl100k_base and o200k_base.

Each encoding bundles:
  - The pre-tokenization regex pattern (as a String constant).
  - The special token map (token string → ID).
  - The URL for the .tiktoken rank file (informational; not fetched here).

SPEC § 5.2 and § 7.1: the rank file contains only mergeable ranks; the
pattern and special tokens are supplied by this module.
"""

# ── cl100k_base ───────────────────────────────────────────────────────────────

comptime CL100K_PATTERN: String = (
    "(?i:'s|'t|'re|'ve|'m|'ll|'d)"
    "|[^\\r\\n\\p{L}\\p{N}]?\\p{L}+"
    "|\\p{N}{1,3}"
    "| ?[^\\s\\p{L}\\p{N}]+[\\r\\n]*"
    "|\\s*[\\r\\n]+"
    "|\\s+(?!\\S)"
    "|\\s+"
)


def cl100k_special_tokens() -> Dict[String, Int]:
    """Return the special token map for cl100k_base."""
    var d = Dict[String, Int]()
    d["<|endoftext|>"] = 100257
    d["<|fim_prefix|>"] = 100258
    d["<|fim_middle|>"] = 100259
    d["<|fim_suffix|>"] = 100260
    d["<|endofprompt|>"] = 100276
    return d^


# ── o200k_base ────────────────────────────────────────────────────────────────

# o200k uses an extended pattern that also handles emoji and some additional
# Unicode categories. The pattern below matches tiktoken's o200k_base.
comptime O200K_PATTERN: String = (
    "[^\\S\\r\\n][^\\S\\r\\n]*"
    "|(?i:'s|'t|'re|'ve|'m|'ll|'d)"
    "|[^\\r\\n\\p{L}\\p{N}\\s]?\\p{L}+"
    "|\\p{N}{1,3}"
    "| ?[^\\s\\p{L}\\p{N}]+[\\r\\n]*"
    "|\\s*[\\r\\n]+"
    "|\\s+"
)


def o200k_special_tokens() -> Dict[String, Int]:
    """Return the special token map for o200k_base."""
    var d = Dict[String, Int]()
    d["<|endoftext|>"] = 199999
    d["<|endofprompt|>"] = 200018
    return d^


# ── Pattern selector ──────────────────────────────────────────────────────────

comptime CL100K_NAME: String = "cl100k_base"
comptime O200K_NAME: String = "o200k_base"


def pattern_for(name: String) raises -> String:
    """Return the pre-tokenizer pattern for a named encoding.

    Raises:
        Error for unknown encoding names.
    """
    if name == CL100K_NAME:
        return CL100K_PATTERN
    if name == O200K_NAME:
        return O200K_PATTERN
    raise Error("Unknown encoding: '" + name + "'")


def special_tokens_for(name: String) raises -> Dict[String, Int]:
    """Return the special token map for a named encoding.

    Raises:
        Error for unknown encoding names.
    """
    if name == CL100K_NAME:
        return cl100k_special_tokens()
    if name == O200K_NAME:
        return o200k_special_tokens()
    raise Error("Unknown encoding: '" + name + "'")
