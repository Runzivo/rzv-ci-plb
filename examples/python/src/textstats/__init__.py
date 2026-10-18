"""Small text statistics used by the CI example."""

import re

_WORD = re.compile(r"[A-Za-z0-9']+")


def word_count(text: str) -> int:
    """Return the number of words in text."""
    if not isinstance(text, str):
        raise TypeError("text must be a string")
    return len(_WORD.findall(text))


def top_words(text: str, limit: int = 3) -> list[tuple[str, int]]:
    """Return the most frequent lowercase words, ties sorted alphabetically."""
    if limit < 1:
        raise ValueError("limit must be at least 1")
    counts: dict[str, int] = {}
    for word in _WORD.findall(text.lower()):
        counts[word] = counts.get(word, 0) + 1
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:limit]
