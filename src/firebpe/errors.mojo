"""Typed errors for firebpe. All recoverable failures raise from this module.

No silent failures: every error condition raises a specific typed error so
callers can distinguish causes without string-parsing.
"""


struct DisallowedSpecialToken(Writable):
    """Raised when a disallowed special token appears in input text.

    Args:
        token: The offending special token string.
        offset: Byte offset in the input where it was found.
    """

    var token: String
    var offset: Int

    def __init__(out self, token: String, offset: Int):
        self.token = token
        self.offset = offset

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            "DisallowedSpecialToken: '",
            self.token,
            "' at byte offset ",
            self.offset,
        )


struct UnsupportedConfig(Writable):
    """Raised by loaders for tokenizer configs outside v0 scope.

    Args:
        field: The JSON field or config key that is unsupported.
        value: The unsupported value found.
    """

    var field: String
    var value: String

    def __init__(out self, field: String, value: String):
        self.field = field
        self.value = value

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            "UnsupportedConfig: field '",
            self.field,
            "' has unsupported value '",
            self.value,
            "'",
        )


struct InvalidUtf8(Writable):
    """Raised by decode() when byte buffer is not valid UTF-8.

    Args:
        offset: Byte offset of the first invalid byte.
    """

    var offset: Int

    def __init__(out self, offset: Int):
        self.offset = offset

    def write_to(self, mut writer: Some[Writer]):
        writer.write("InvalidUtf8: invalid byte sequence at offset ", self.offset)


struct MalformedRankFile(Writable):
    """Raised when a .tiktoken rank file cannot be parsed.

    Args:
        line_number: 1-based line number of the bad line.
        reason: Short description of the parse failure.
    """

    var line_number: Int
    var reason: String

    def __init__(out self, line_number: Int, reason: String):
        self.line_number = line_number
        self.reason = reason

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            "MalformedRankFile: line ",
            self.line_number,
            ": ",
            self.reason,
        )


struct MalformedJson(Writable):
    """Raised when a tokenizer.json file cannot be parsed.

    Args:
        json_path: Dot-notation path to the offending field (e.g. "model.type").
        reason: Short description of the parse failure.
    """

    var json_path: String
    var reason: String

    def __init__(out self, json_path: String, reason: String):
        self.json_path = json_path
        self.reason = reason

    def write_to(self, mut writer: Some[Writer]):
        writer.write(
            "MalformedJson: at '",
            self.json_path,
            "': ",
            self.reason,
        )


def raise_disallowed_special(token: String, offset: Int) raises:
    """Raise DisallowedSpecialToken as an Error with a descriptive message."""
    raise Error(
        "DisallowedSpecialToken: '"
        + token
        + "' at byte offset "
        + String(offset)
    )


def raise_unsupported_config(field: String, value: String) raises:
    """Raise UnsupportedConfig as an Error with a descriptive message."""
    raise Error(
        "UnsupportedConfig: field '"
        + field
        + "' has unsupported value '"
        + value
        + "'"
    )


def raise_invalid_utf8(offset: Int) raises:
    """Raise InvalidUtf8 as an Error with a descriptive message."""
    raise Error("InvalidUtf8: invalid byte sequence at offset " + String(offset))


def raise_malformed_rank_file(line_number: Int, reason: String) raises:
    """Raise MalformedRankFile as an Error with a descriptive message."""
    raise Error(
        "MalformedRankFile: line "
        + String(line_number)
        + ": "
        + reason
    )


def raise_malformed_json(json_path: String, reason: String) raises:
    """Raise MalformedJson as an Error with a descriptive message."""
    raise Error("MalformedJson: at '" + json_path + "': " + reason)
