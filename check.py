"""Check your agent's answer format before the quiz: python3 check.py

Runs agent.py in the platform sandbox (with your `haystack-enterprise login`) on three sample
questions, sent exactly the way the quiz sends them. Passes when every reply is a single correct
letter A-D.
"""

import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SAMPLES = [
    ("What is the capital of Australia?", ["Sydney", "Melbourne", "Canberra", "Perth"], "C"),
    ("How many minutes are in a week?", ["1,440", "10,080", "8,760", "604,800"], "B"),
    ("Which planet is known as the Red Planet?", ["Mars", "Venus", "Jupiter", "Mercury"], "A"),
]


def format_question(question: str, options: list[str]) -> str:
    """The exact text the quiz sends: the question, then one `X) option` line per option."""
    return "\n".join([question, *(f"{letter}) {o}" for letter, o in zip("ABCD", options))])


def last_reply(result) -> str:
    """The text of the last assistant message anywhere in the run result."""
    replies = []

    def walk(node):
        if isinstance(node, dict):
            if str(node.get("role", node.get("_role", ""))).endswith("assistant"):
                parts = node.get("content", node.get("_content", []))
                text = parts if isinstance(parts, str) else "".join(
                    p.get("text") or "" for p in parts if isinstance(p, dict)
                )
                if text.strip():
                    replies.append(text)
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    walk(result)
    return replies[-1] if replies else ""


def main() -> int:
    agent = Path(__file__).with_name("agent.py")
    failed = 0
    for question, options, answer in SAMPLES:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "result.json"
            start = time.monotonic()
            run = subprocess.run(
                ["haystack-enterprise", "run", str(agent),
                 "--query", format_question(question, options), "--output", str(out)],
                capture_output=True, text=True,
            )
            seconds = time.monotonic() - start
            if run.returncode != 0 or not out.exists():
                print(f"❌ {question}\n   run failed:\n{run.stdout}{run.stderr}")
                failed += 1
                continue
            reply = last_reply(json.loads(out.read_text())).strip()
        if not re.fullmatch(r"[ABCD]", reply):
            print(f"❌ {question}\n   reply must be exactly one letter A-D, got: {reply!r}")
            failed += 1
        elif reply != answer:
            print(f"⚠️  {question}\n   format ok, but wrong: {reply} (expected {answer})")
        else:
            print(f"✅ {question}  →  {reply}  ({seconds:.1f}s incl. sandbox start)")
    print("\nFormat ready for the quiz." if not failed else f"\n{failed} reply(s) in the wrong format.")
    return 1 if failed else 0


if __name__ == "__main__":
    assert format_question("Q?", ["a", "b", "c", "d"]) == "Q?\nA) a\nB) b\nC) c\nD) d"
    assert last_reply({"agent": {"messages": [
        {"role": "user", "content": [{"text": "Q"}]},
        {"role": "assistant", "content": [{"text": "B"}]},
    ]}}) == "B"
    sys.exit(main())
