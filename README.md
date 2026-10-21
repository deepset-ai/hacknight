# The Quiz Agent Challenge

Build the **fastest, cheapest agent that answers quiz questions correctly.** At the end we run a
live quiz: every question goes to every participant's agent at the same moment, and the
leaderboard is on the screen.

## ⚡ Quick start

Paste this into a terminal. It clones the repo, installs the CLI, logs you in, deploys your
agent and prints the link to chat with it. Each step waits for Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/deepset-ai/hacknight/main/setup.sh | bash
```

Done? Skip to [What you have now](#-what-you-have-now). Prefer doing it by hand? Read on.

## 1 · Install the CLI

```bash
curl -fsSL https://raw.githubusercontent.com/deepset-ai/haystack-enterprise-sdk/main/install.sh | bash
```

Open a new terminal afterwards, then check: `haystack-enterprise --version`.

Then set up the project. The installer also gave you [uv](https://docs.astral.sh/uv/); this
creates `.venv/` with Haystack in it, which the CLI uses to load your agent:

```bash
git clone https://github.com/deepset-ai/hacknight.git && cd hacknight
uv sync
```

> Seeing `ModuleNotFoundError: No module named 'haystack'`? You skipped `uv sync`, or you're not
> running the CLI from inside the `hacknight` folder.

## ✅ What you have now

After `setup.sh` (or step 4 by hand), your agent is live: `agent.py` runs as a service called
**`quiz`** in your workspace on the [Haystack Enterprise Platform](https://cloud.deepset.ai). A
service is your agent in the cloud behind an API endpoint, and that endpoint is what the quiz
calls with each question.

- **Chat with it:** open the *Shared prototype link* the script printed.
- **See it on the platform:** open the service link the script printed, or go to
  [cloud.deepset.ai](https://cloud.deepset.ai) → your workspace → **Gateway → Services → `quiz`**.

Each `haystack-enterprise deploy agent.py quiz` updates this same service.

## 2 · The task

Your agent gets a multiple-choice question, always in this shape:

```
How many minutes are in a week?
A) 1,440
B) 10,080
C) 8,760
D) 604,800
```

It must reply with **exactly one letter**: `A`, `B`, `C` or `D`. Nothing else, no full stop, no
explanation. Anything else counts as wrong.

**The leaderboard**

| | Rule |
| --- | --- |
| ⏱ | Each agent gets **15 seconds** per question. Late counts as wrong. |
| ✅ | Most correct answers wins... |
| 🪙 | ...ties go to the **fewest tokens** spent... |
| 🏎️ | ...then to the **fastest** total time. |

Your agent must be deployed as a service called **`quiz`** in your workspace.

## 3 · The starting agent

[`agent.py`](agent.py) already solves the task. It is a Haystack `Agent` with two tools,
[`calculate`](calculator.py) and [`today`](clock.py), and a system prompt that enforces the
one-letter format. Then make it better:

- **Model:** `MODEL` at the top of `agent.py`. Smaller is cheaper and faster. Is it still right?
- **Prompt:** every token in `SYSTEM_PROMPT` is paid on every question.
- **Tools:** each tool's description goes into every call, and each tool call is another round
  trip. Drop what doesn't earn its place, or add one that does (one `@tool` per file).
- **Steps:** `max_agent_steps` caps how long it can loop.

## 4 · Log in and deploy

```bash
haystack-enterprise login
haystack-enterprise deploy agent.py quiz
```

Redeploy after every change with the same `deploy` command.

## 5 · Check your format

```bash
uv run python check.py
```

Runs your agent on three sample questions, sent exactly the way the quiz sends them. All ✅ means
you're ready.
