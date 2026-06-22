"""Benchmarks for firebpe hot paths.

Measures:
  - Pre-tokenizer (ScannerPreTok.split)
  - BPE merge (byte_pair_merge)
  - Full encode (Encoder.encode)
  - is_letter / is_number (unicode classification)

Run from project root:
    pixi run bench

Requires the real cl100k_base.tiktoken file at:
    tests/conformance/cl100k_base.tiktoken
"""

from std.time import perf_counter_ns
from firebpe.core import Encoder
from firebpe.vocab import RankTable
from firebpe.merge import byte_pair_merge
from firebpe.pretok.scanner import ScannerPreTok
from firebpe.pretok.unicode import is_letter, is_number
from firebpe.special import SpecialPolicy
from firebpe.loaders.encodings import CL100K_PATTERN, cl100k_special_tokens
from firebpe.loaders.tiktoken import load_tiktoken_ranks


# ── Helpers ──────────────────────────────────────────────────────────────────


def _ns_to_ms(ns: UInt) -> Float64:
    return Float64(Int(ns)) / 1_000_000.0


def _ns_per_byte(ns: UInt, n_bytes: Int) -> Float64:
    return Float64(Int(ns)) / Float64(n_bytes)


def _report(name: String, ns: UInt, iters: Int, n_bytes: Int):
    var ms = _ns_to_ms(ns)
    var avg_ms = ms / Float64(iters)
    var ns_per_byte = _ns_per_byte(ns // UInt(iters), n_bytes)
    print(
        name,
        "| avg",
        avg_ms,
        "ms |",
        ns_per_byte,
        "ns/byte | iters",
        iters,
    )


# ── Benchmark cases ──────────────────────────────────────────────────────────

comptime SMALL_TEXT = "Hello, world! How are you today?"
comptime MEDIUM_TEXT = """The quick brown fox jumps over the lazy dog. \
Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump! \
The five boxing wizards jump quickly. Sphinx of black quartz, judge my vow. \
Two driven jocks help fax my big quiz. Five quacking zephyrs jolt my wax bed. \
The jay, pig, fox, zebra and my wolves quack! Blowzy red vixens fight for a quick jump."""


# ── Pre-tokenizer benchmark ───────────────────────────────────────────────────


def bench_pretok_small(iters: Int) raises:
    var pretok = ScannerPreTok.cl100k()
    var text_bytes = SMALL_TEXT.as_bytes()
    var span = Span[UInt8](text_bytes)

    var t0 = perf_counter_ns()
    for _ in range(iters):
        var _ = pretok.split(span)
    var t1 = perf_counter_ns()

    _report("pretok_small", t1 - t0, iters, len(text_bytes))


def bench_pretok_medium(iters: Int) raises:
    var pretok = ScannerPreTok.cl100k()
    var text_bytes = MEDIUM_TEXT.as_bytes()
    var span = Span[UInt8](text_bytes)

    var t0 = perf_counter_ns()
    for _ in range(iters):
        var _ = pretok.split(span)
    var t1 = perf_counter_ns()

    _report("pretok_medium", t1 - t0, iters, len(text_bytes))


# ── Unicode classification benchmark ─────────────────────────────────────────


def bench_is_letter(iters: Int) raises:
    """Time is_letter over a range of codepoints."""
    var n_cps = 1000
    var t0 = perf_counter_ns()
    for _ in range(iters):
        var acc = False
        for cp in range(n_cps):
            acc = acc or is_letter(cp)
        _ = acc
    var t1 = perf_counter_ns()

    _report("is_letter_1k", t1 - t0, iters, n_cps)


# ── BPE merge benchmark ───────────────────────────────────────────────────────


def bench_merge_base(iters: Int) raises:
    """BPE merge on a plain-ASCII piece with only base-byte ranks."""
    var table = RankTable.with_base_bytes()
    var piece_bytes = SMALL_TEXT.as_bytes()
    var span = Span[UInt8](piece_bytes)

    var t0 = perf_counter_ns()
    for _ in range(iters):
        var _ = byte_pair_merge(span, table)
    var t1 = perf_counter_ns()

    _report("merge_base_small", t1 - t0, iters, len(piece_bytes))


# ── Full encode benchmarks ────────────────────────────────────────────────────


def bench_encode_base(iters: Int) raises:
    """Full encode with base-byte table (no real merges)."""
    var table = RankTable.with_base_bytes()
    var enc = Encoder(table^, CL100K_PATTERN, cl100k_special_tokens())

    var t0 = perf_counter_ns()
    for _ in range(iters):
        var _ = enc.encode(MEDIUM_TEXT, SpecialPolicy.allow_all())
    var t1 = perf_counter_ns()

    _report("encode_base_medium", t1 - t0, iters, MEDIUM_TEXT.byte_length())


def bench_encode_cl100k(iters: Int) raises:
    """Full encode with the real cl100k_base vocabulary."""
    var enc = Encoder.from_tiktoken(
        "tests/conformance/cl100k_base.tiktoken",
        CL100K_PATTERN,
        cl100k_special_tokens(),
    )

    # Warm up
    var _ = enc.encode(MEDIUM_TEXT, SpecialPolicy.allow_all())

    var t0 = perf_counter_ns()
    for _ in range(iters):
        var _ = enc.encode(MEDIUM_TEXT, SpecialPolicy.allow_all())
    var t1 = perf_counter_ns()

    _report("encode_cl100k_medium", t1 - t0, iters, MEDIUM_TEXT.byte_length())


# ── Runner ────────────────────────────────────────────────────────────────────


def main() raises:
    comptime PRETOK_ITERS = 10000
    comptime MERGE_ITERS = 10000
    comptime ENCODE_BASE_ITERS = 1000
    comptime ENCODE_CL100K_ITERS = 100

    print("=== firebpe benchmarks ===")
    print()

    print("--- pre-tokenizer ---")
    bench_pretok_small(PRETOK_ITERS)
    bench_pretok_medium(PRETOK_ITERS)
    print()

    print("--- unicode classification ---")
    bench_is_letter(MERGE_ITERS)
    print()

    print("--- BPE merge (base-byte table) ---")
    bench_merge_base(MERGE_ITERS)
    print()

    print("--- full encode ---")
    bench_encode_base(ENCODE_BASE_ITERS)
    bench_encode_cl100k(ENCODE_CL100K_ITERS)
    print()

    print("=== done ===")
