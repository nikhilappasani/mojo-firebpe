#!/usr/bin/env python3
"""Regenerate pretok/unicode.mojo from the Unicode Character Database.

Downloads DerivedGeneralCategory.txt from unicode.org and builds compact
range tables for is_letter (L*) and is_number (N*) predicates.

Usage:
    python scripts/gen_unicode_tables.py [--unicode-version 15.1.0]

Output:
    src/firebpe/pretok/unicode.mojo  (overwrites)

This script is a build-time tool, not a runtime dependency.
Regeneration is a deliberate, reviewed change (RULES.md § 7, SPEC § 5.4).
"""

import argparse
import urllib.request
import re
import os
from typing import List, Tuple

DEFAULT_UNICODE_VERSION = "15.1.0"

LETTER_CATEGORIES = {"Lu", "Ll", "Lt", "Lm", "Lo"}
NUMBER_CATEGORIES = {"Nd", "Nl", "No"}


def download_ucd(version: str) -> str:
    url = (
        f"https://unicode.org/Public/{version}/ucd/DerivedGeneralCategory.txt"
    )
    print(f"Downloading {url}...")
    with urllib.request.urlopen(url) as r:
        return r.read().decode("utf-8")


def parse_ranges(content: str, categories: set) -> List[Tuple[int, int]]:
    """Extract [lo, hi] inclusive ranges for the given categories."""
    ranges = []
    for line in content.splitlines():
        line = line.split("#")[0].strip()
        if not line:
            continue
        m = re.match(
            r"^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*(\w+)", line, re.I
        )
        if not m:
            continue
        cat = m.group(3)
        if cat not in categories:
            continue
        lo = int(m.group(1), 16)
        hi = int(m.group(2), 16) if m.group(2) else lo
        ranges.append((lo, hi))
    ranges.sort()
    # Merge adjacent/overlapping.
    merged = []
    for lo, hi in ranges:
        if merged and lo <= merged[-1][1] + 1:
            merged[-1] = (merged[-1][0], max(merged[-1][1], hi))
        else:
            merged.append([lo, hi])
    return [(lo, hi) for lo, hi in merged]


def format_hex_list(values: List[int], per_row: int = 8) -> str:
    rows = []
    for i in range(0, len(values), per_row):
        chunk = values[i : i + per_row]
        rows.append("    " + ", ".join(f"0x{v:04X}" for v in chunk) + ",")
    return "\n".join(rows)


def generate_mojo(
    letter_ranges: List[Tuple[int, int]],
    number_ranges: List[Tuple[int, int]],
    unicode_version: str,
) -> str:
    letter_lo = [lo for lo, _ in letter_ranges]
    letter_hi = [hi for _, hi in letter_ranges]
    number_lo = [lo for lo, _ in number_ranges]
    number_hi = [hi for _, hi in number_ranges]

    return f'''"""Unicode character class tables for the pre-tokenizer.

Generated from Unicode Character Database (Unicode {unicode_version}).
Regenerate with: pixi run gen-unicode

Provides two predicates:
  is_letter(cp)  — true for General_Category = L* (Lu Ll Lt Lm Lo)
  is_number(cp)  — true for General_Category = N* (Nd Nl No)

Representation: sorted range tables (lo, hi inclusive). Linear scan.
"""

# ── Letter ranges (L*) ────────────────────────────────────────────────────────
# Unicode {unicode_version}
comptime _LETTER_RANGES_LO = List[Int]([
{format_hex_list(letter_lo)}
])

comptime _LETTER_RANGES_HI = List[Int]([
{format_hex_list(letter_hi)}
])

# ── Number ranges (N*) ────────────────────────────────────────────────────────
comptime _NUMBER_RANGES_LO = List[Int]([
{format_hex_list(number_lo)}
])

comptime _NUMBER_RANGES_HI = List[Int]([
{format_hex_list(number_hi)}
])


def _in_ranges(cp: Int, lo_table: List[Int], hi_table: List[Int]) -> Bool:
    """Returns true if cp falls in any [lo, hi] range pair."""
    var n = len(lo_table)
    for i in range(n):
        if cp < lo_table[i]:
            return False
        if cp <= hi_table[i]:
            return True
    return False


def is_letter(cp: Int) -> Bool:
    """True if Unicode code point cp is in General_Category L* (letter)."""
    return _in_ranges(cp, _LETTER_RANGES_LO, _LETTER_RANGES_HI)


def is_number(cp: Int) -> Bool:
    """True if Unicode code point cp is in General_Category N* (number)."""
    return _in_ranges(cp, _NUMBER_RANGES_LO, _NUMBER_RANGES_HI)
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--unicode-version", default=DEFAULT_UNICODE_VERSION
    )
    args = parser.parse_args()

    content = download_ucd(args.unicode_version)
    letter_ranges = parse_ranges(content, LETTER_CATEGORIES)
    number_ranges = parse_ranges(content, NUMBER_CATEGORIES)

    print(
        f"Letter ranges: {len(letter_ranges)}, Number ranges: {len(number_ranges)}"
    )

    mojo_src = generate_mojo(letter_ranges, number_ranges, args.unicode_version)

    out_path = "src/firebpe/pretok/unicode.mojo"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(mojo_src)
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
