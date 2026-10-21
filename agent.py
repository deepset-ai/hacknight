"""The quiz agent: answers multiple-choice questions with a single letter.

Plain Haystack. An `Agent` is a chat model in a loop: it reads the question, may call a tool,
reads the result, and answers. Make it faster and cheaper -- but keep it right.

Two things the platform cares about:
- A bare `Agent` deploys as-is: the CLI wraps it in a one-component pipeline called `agent`.
- The OpenAI key is never in this file. It serializes as an env-var reference that the platform
  fills in from your workspace, so you need no key of your own.
"""

from haystack.components.agents import Agent
from haystack.components.generators.chat import OpenAIChatGenerator
from haystack.utils import Secret

# One @tool per file: the CLI copies each tool's file into the deployed agent.
from calculator import calculate
from letters import count_letter

# Try a smaller one. Any OpenAI chat model with tool calling works.
MODEL = "gpt-5.1"

SYSTEM_PROMPT = (
    "You answer multiple-choice quiz questions. Each question has options A, B, C and D. "
    "Use the calculate tool for any arithmetic. "
    "Use count_letter only when the question asks how many times a letter appears in a word. "
    "Reply with ONLY the letter of the correct option: A, B, C or D. No other text."
)

agent = Agent(
    # strict=False: the key only has to exist on the platform, not on your machine.
    chat_generator=OpenAIChatGenerator(
        model=MODEL,
        api_key=Secret.from_env_var("OPENAI_API_KEY", strict=False),
        # Reasoning model with thinking switched off: smart, but fast and cheap.
        # include_usage: the platform streams, and a stream only reports token usage when asked.
        generation_kwargs={
            "reasoning_effort": "none",
            "max_completion_tokens": 50,
            "stream_options": {"include_usage": True},
        },
    ),
    tools=[calculate, count_letter],
    system_prompt=SYSTEM_PROMPT,
    max_agent_steps=3,
)
