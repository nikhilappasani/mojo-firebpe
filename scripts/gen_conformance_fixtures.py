#!/usr/bin/env python3
"""Generate conformance fixtures using the real tiktoken library.

Requires: pip install tiktoken

Usage:
    python scripts/gen_conformance_fixtures.py

Output:
    tests/conformance/cl100k_fixtures.json
    tests/conformance/o200k_fixtures.json

Fixtures record: tiktoken version, encoding name, and for each test case
the input text and expected token IDs. firebpe must produce byte-exact
identical output (RULES.md § 5.2).
"""

import json
import os
import sys

try:
    import tiktoken
except ImportError:
    print("ERROR: tiktoken not installed. Run: pip install tiktoken", file=sys.stderr)
    sys.exit(1)

# Test cases covering the full edge-case set from RULES.md § 5.4.
TEST_CASES = [
    # Basic
    "Hello, world!",
    "The quick brown fox jumps over the lazy dog.",
    # Unicode
    "你好世界",
    "🌍🌎🌏",
    "こんにちは",
    "مرحبا بالعالم",
    # Contractions
    "it's a wonderful life",
    "they're going to do it",
    "I've been waiting",
    # Numbers
    "123",
    "1234",
    "12345",
    "3.14159",
    # Whitespace
    "   ",
    "\n\n\n",
    "\t\t",
    " hello",
    "hello ",
    # Punctuation
    "Hello! How are you?",
    "one... two... three...",
    # Control bytes (only those safe in strings)
    "line1\nline2\nline3",
    "tab\there",
    # High bytes (Latin-1)
    "café",
    "naïve",
    "résumé",
    # Empty
    "",
    # Long text
    "a" * 1000,
    " ".join(["hello"] * 100),
    # Mixed
    "GPT-4 uses cl100k_base tokenization with vocab_size=100277.",
    "  leading and trailing spaces  ",
    "ALLCAPS AND mixed Case",
]


def gen_fixtures(encoding_name: str, output_path: str) -> None:
    enc = tiktoken.get_encoding(encoding_name)
    cases = []
    for text in TEST_CASES:
        ids = enc.encode(text, allowed_special="all")
        cases.append({"input": text, "expected_ids": ids})

    fixture = {
        "tiktoken_version": tiktoken.__version__,
        "encoding": encoding_name,
        "cases": cases,
    }

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(fixture, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(cases)} cases to {output_path}")


if __name__ == "__main__":
    gen_fixtures(
        "cl100k_base", "tests/conformance/cl100k_fixtures.json"
    )
    gen_fixtures(
        "o200k_base", "tests/conformance/o200k_fixtures.json"
    )
    print("Done. Run: mojo run tests/conformance/test_conformance.mojo")
