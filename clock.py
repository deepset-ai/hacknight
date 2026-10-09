from datetime import date

from haystack.tools import tool


@tool
def today() -> str:
    """Return today's date (YYYY-MM-DD). Use it for questions like 'how many years ago'."""
    return date.today().isoformat()
