"""firebpe — Fast byte-level BPE tokenizer for Mojo (tiktoken-compatible).

Public API (SPEC § 10):
  Encoder  — encode / decode / batch
  Trainer  — train a vocabulary from text
  Patterns — CL100K_PATTERN, O200K_PATTERN
  Helpers  — cl100k_special_tokens, o200k_special_tokens
"""

from .core import Encoder
from .trainer import Trainer
from .special import SpecialPolicy
from .loaders.encodings import (
    CL100K_PATTERN,
    O200K_PATTERN,
    CL100K_NAME,
    O200K_NAME,
    cl100k_special_tokens,
    o200k_special_tokens,
    pattern_for,
    special_tokens_for,
)
from .errors import (
    raise_disallowed_special,
    raise_unsupported_config,
    raise_invalid_utf8,
    raise_malformed_rank_file,
    raise_malformed_json,
)
