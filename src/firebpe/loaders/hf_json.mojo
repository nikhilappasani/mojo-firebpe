"""Loader for HuggingFace tokenizer.json files.

Supports: model.type == "BPE" with ByteLevel pre_tokenizer (SPEC § 7.2).
Non-BPE models or unsupported normalizers raise UnsupportedConfig.

At load time, all token strings are inverted through the GPT-2
bytes_to_unicode map so the in-memory RankTable keys on raw bytes.

Public API:
  load_hf_json(path) -> RankTable            — just the rank table
  load_hf_json_full(path, mut specials)      — table + fills specials dict
"""

from std.python import Python, PythonObject
from ..vocab import RankTable
from ..errors import raise_malformed_json, raise_unsupported_config
from .byte_unicode import hf_token_str_to_bytes


def load_hf_json_full(
    path: String,
    mut specials: Dict[String, Int],
) raises -> RankTable:
    """Load a HuggingFace tokenizer.json into a RankTable, filling specials.

    Args:
        path: Path to tokenizer.json.
        specials: Output dict filled with special token string → ID mappings.

    Returns:
        RankTable with all mergeable tokens.

    Raises:
        UnsupportedConfig for non-BPE model or unsupported pre-tokenizer.
        MalformedJson for missing/invalid fields.
        Error for IO failures.
    """
    var json_mod = Python.import_module("json")

    # Read file.
    var content = String()
    with open(path, "r") as f:
        content = f.read()

    var data = json_mod.loads(content)

    # Validate model type.
    var model = data.get("model")
    if model is None:
        raise_malformed_json("model", "field is missing")
    var model_type = String(py=model.get("type", ""))
    if model_type != "BPE":
        raise_unsupported_config("model.type", model_type)

    # Check pre_tokenizer (must be ByteLevel or Sequence containing ByteLevel).
    var pretok = data.get("pre_tokenizer")
    if pretok is not None:
        var pretok_type = String(py=pretok.get("type", ""))
        if pretok_type == "Sequence":
            var found_byte_level = False
            for item in pretok.get("pretokenizers", []):
                if String(py=item.get("type", "")) == "ByteLevel":
                    found_byte_level = True
                    break
            if not found_byte_level:
                raise_unsupported_config(
                    "pre_tokenizer.type",
                    "Sequence without ByteLevel is not supported in v0",
                )
        elif pretok_type != "ByteLevel" and pretok_type != "":
            raise_unsupported_config("pre_tokenizer.type", pretok_type)

    # Check normalizer (only None / NFC / identity supported).
    var normalizer = data.get("normalizer")
    if normalizer is not None:
        var norm_type = String(py=normalizer.get("type", ""))
        if (
            norm_type != "NFC"
            and norm_type != "NFKC"
            and norm_type != "Precompiled"
            and norm_type != ""
        ):
            raise_unsupported_config("normalizer.type", norm_type)

    # Load vocab: token_str → id.
    var vocab = model.get("vocab")
    if vocab is None:
        raise_malformed_json("model.vocab", "field is missing")

    var table = RankTable(131072)

    for item in vocab.items():
        # Python dict.items() yields (key, value) tuples; use index access.
        var token_str = String(py=item[0])
        var token_id = Int(py=item[1])
        var raw_bytes = hf_token_str_to_bytes(token_str)
        table.insert(Span[UInt8](raw_bytes), UInt32(token_id))

    # Collect special (added) tokens into specials (mut).
    var added_tokens = data.get("added_tokens", [])
    for tok in added_tokens:
        var is_special = Bool(py=tok.get("special", False))
        if is_special:
            var tok_str = String(py=tok.get("content", ""))
            var tok_id = Int(py=tok.get("id", -1))
            if tok_str.byte_length() > 0 and tok_id >= 0:
                specials[tok_str] = tok_id

    return table^


def load_hf_json(path: String) raises -> RankTable:
    """Load a HuggingFace tokenizer.json into a RankTable (table only).

    Special tokens are discarded. Use Encoder.from_hf_json for full loading.
    """
    var specials = Dict[String, Int]()
    return load_hf_json_full(path, specials)^
