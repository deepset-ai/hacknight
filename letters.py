from typing import Annotated

from haystack.tools import tool


@tool
def count_letter(
    word: Annotated[str, "The word or phrase to search, e.g. strawberry"],
    letter: Annotated[str, "The single letter to count, e.g. r"],
) -> str:
    """Count how often a letter appears in a word. Use it for 'how many r's in strawberry' questions."""
    return str(word.lower().count(letter.lower()))
