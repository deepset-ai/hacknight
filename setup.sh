#!/usr/bin/env bash
# Workshop setup in one line:
#   curl -fsSL https://raw.githubusercontent.com/deepset-ai/hacknight/main/setup.sh | bash
# Clones the repo, installs the CLI, logs you in and deploys the quiz agent. Safe to re-run.

REPO_URL="${REPO_URL:-https://github.com/deepset-ai/hacknight.git}"
CLI_INSTALLER="https://raw.githubusercontent.com/deepset-ai/haystack-enterprise-sdk/main/install.sh"
SERVICE="quiz"
TOTAL=6
export PATH="$HOME/.local/bin:$PATH"  # where the installer puts the CLI and uv

BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'; CYAN=$'\e[36m'; RESET=$'\e[0m'
LINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SUMMARY=()
N=0

step() {  # step "🧰" "Title" "what happens"
  N=$((N + 1)); TITLE="$2"
  printf '\n%s%s%s\n%s  %s  Step %d/%d · %s%s\n%s%s%s\n' \
    "$CYAN" "$LINE" "$RESET" "$BOLD" "$1" "$N" "$TOTAL" "$2" "$RESET" "$CYAN" "$LINE" "$RESET"
  printf '%s\n\n' "$3"
  read -r -p "👉 Press Enter to continue " _
  echo
}

ok() {
  printf '\n%s✅ %s%s\n' "$GREEN" "${1:-Done}" "$RESET"
  SUMMARY+=("✅ $N. $TITLE")
}

fail() {  # fail "what broke" "how to fix"
  printf '\n%s%s%s\n' "$RED" "$LINE" "$RESET"
  printf '%s%s  ❌❌❌  STEP %d FAILED: %s%s\n' "$RED" "$BOLD" "$N" "$TITLE" "$RESET"
  printf '%s  %s%s\n' "$RED" "$1" "$RESET"
  printf '%s  💡 %s%s\n' "$RED" "$2" "$RESET"
  printf '%s  Carrying on with the next step...%s\n' "$RED" "$RESET"
  printf '%s%s%s\n' "$RED" "$LINE" "$RESET"
  SUMMARY+=("❌ $N. $TITLE")
}

main() {
  printf '\n%s🎉  Welcome to the Quiz Agent Challenge!%s\n' "$BOLD" "$RESET"
  printf '%sSix steps, each waits for Enter. Ctrl+C quits any time.%s\n' "$DIM" "$RESET"

  # 1 · Clone ------------------------------------------------------------------
  step "📦" "Get the code" "Clones $REPO_URL into ./hacknight (or uses the folder you're in)."
  if [[ -f agent.py && -f check.py ]]; then
    ok "Already inside the project: $PWD"
  elif [[ -d hacknight/.git ]] || git clone "$REPO_URL" hacknight; then
    cd hacknight && ok "Project ready in $PWD"
  else
    fail "git clone failed." "Check your internet connection and that git is installed (git --version)."
  fi

  # 2 · CLI --------------------------------------------------------------------
  step "🧰" "Install the haystack-enterprise CLI" "Installs the CLI (and uv) unless you already have it."
  if command -v haystack-enterprise >/dev/null; then
    ok "CLI already installed: $(haystack-enterprise --version 2>&1)"
  elif curl -fsSL "$CLI_INSTALLER" | bash && command -v haystack-enterprise >/dev/null; then
    ok "CLI installed: $(haystack-enterprise --version 2>&1)"
  else
    fail "The CLI installer did not finish." "Run it by hand: curl -fsSL $CLI_INSTALLER | bash"
  fi

  # 3 · uv sync ----------------------------------------------------------------
  step "🐍" "Install Haystack" "Runs 'uv sync' to create .venv/ — the CLI loads your agent from it."
  if uv sync; then
    ok "Haystack installed in .venv/"
  else
    fail "uv sync failed." "Run 'uv sync' inside the hacknight folder and read the error above."
  fi

  # 4 · Login ------------------------------------------------------------------
  step "🔐" "Log in" "Opens your browser to log in to the Haystack Enterprise Platform."
  if haystack-enterprise whoami >/dev/null 2>&1; then
    ok "Already logged in."
  elif haystack-enterprise login; then
    ok "Logged in."
  else
    fail "Login did not complete." "Run 'haystack-enterprise login' and finish the login in the browser."
  fi

  # 5 · Deploy -----------------------------------------------------------------
  step "🚀" "Deploy your agent" "Deploys agent.py as the service '$SERVICE' and creates a chat link. Takes a minute."
  local log; log=$(mktemp)
  haystack-enterprise deploy agent.py "$SERVICE" --share --no-share-login-required | tee "$log"
  if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    ok "Deployed!"
    printf '\n%s👀 Open the "Shared prototype link" above to chat with your agent.%s\n' "$BOLD" "$RESET"
    # The CLI prints the endpoint's model as "<workspace>/<service id>"; that's all the UI link needs.
    local model; model=$(grep -oE '"model": "[^"/]+/[0-9a-f-]+"' "$log" | head -1 | cut -d'"' -f4)
    [[ -n $model ]] && printf '%s🖥️  Your service on the platform: https://cloud.deepset.ai/workspace/%s/services/%s%s\n' \
      "$BOLD" "${model%%/*}" "${model#*/}" "$RESET"
  else
    fail "Deploy failed." "Fix the error above, then run: haystack-enterprise deploy agent.py $SERVICE"
  fi

  # 6 · Next steps -------------------------------------------------------------
  step "🎯" "Make it faster and cheaper" "🏆 Your agent is live. Now modify agent.py to win the quiz!"
  cat <<EOF
📁 Your project:   ${BOLD}$PWD${RESET}
🔁 Redeploy:       ${BOLD}haystack-enterprise deploy agent.py $SERVICE${RESET}

🧪 How to test (no deploy needed, runs in the platform sandbox):
   • All sample questions, format + answers:
     ${BOLD}uv run python check.py${RESET}
   • One question of your own:
     ${BOLD}haystack-enterprise run agent.py --query \$'How many days are in a leap year?\nA) 365\nB) 366\nC) 364\nD) 367'${RESET}
   • Your deployed agent: chat with it via the shared prototype link from step 5.

🤖 Paste this into your coding assistant to get going:
${CYAN}$LINE${RESET}
In agent.py, make the quiz agent cheaper and faster without losing accuracy:
try a smaller MODEL, shorten SYSTEM_PROMPT, drop tools that don't earn their
place, and lower max_agent_steps. After each change run
\`uv run python check.py\` and keep only changes where every answer stays ✅.
Then redeploy with \`haystack-enterprise deploy agent.py $SERVICE\`.
${CYAN}$LINE${RESET}
EOF
  ok "Have fun!"

  printf '\n%s📋 Summary%s\n' "$BOLD" "$RESET"
  printf '   %s\n' "${SUMMARY[@]}"
  [[ " ${SUMMARY[*]} " == *"❌"* ]] && printf '\n%sSome steps failed: scroll up for the red boxes, fix them, then re-run the one-liner.%s\n' "$RED" "$RESET"
  printf '\n👉 Next: %scd %s%s\n\n' "$BOLD" "$PWD" "$RESET"
}

# Under `curl | bash` stdin is the script, so prompts read from the terminal. `; exit` stops bash
# reading further script lines after main.
main "$@" </dev/tty; exit
