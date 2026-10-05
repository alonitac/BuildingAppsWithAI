# Intro to AI Code Assistants

In the previous tutorial you vibe coded a feature and saw the problem: the agent silently made a domain decision for you, and the result *looked* right but wasn't.

The usual reaction is to pick the strongest model and hope. This tutorial is about the alternative: learning to **work with** a coding agent the way a good engineer works. You give it the right context, you constrain it, you make it plan before it codes, and you **verify** everything it delivers.

We'll keep working on the **Regulatory Radar** app (`RegulatoryRadarDemo`).

Before you start, we need a clean git state. Every exercise starts from a clean project, so you can always compare and throw away the agent's changes:

1. Open the **Source Control** tab (git icon in the left sidebar, or `Ctrl+Shift+G`).
2. Under **Changes**, click the **Discard All Changes** icon (curved arrow) next to the "Changes" header, and confirm.


## Models and effort

In the chat panel you can pick a model, and for many models also an **effort** level (low / medium / high), which controls how long the model thinks before it answers.

**Which model?** With time, and as you get to know your project, you'll develop a feel for which model fits the task in front of you, based on how complex and how large it is. 

**What effort?** Work with the default, usually medium. If you run into trouble, try a higher effort.

**But don't focus on this.** Today the understanding is that the model is rarely the problem. Current models are very capable at most tasks. The problem is the **harness**: the prompt you write, the skills you use, the context you give the agent, the guardrails, and how you test the result. That's where your effort should go, and it's what the rest of this tutorial is about.

Even the strongest model has the same three problems - (1) It has a knowledge cutoff, (2) It's not deterministic, (3) It's eager to please you.

It's worth noting that there are exceptions, where a specific model is part of the recipe. For example, later we'll see subagent-driven development, where different roles (planning, coding, reviewing) can deliberately run on different models.


## Context management

The **context window** is everything the model sees in a single request: the system prompt, your rules, the tool definitions, the files it read, the terminal output, and the **whole conversation so far**. It has a hard size limit (hundreds of thousands of tokens), and you pay for all of it **on every message**.

Here is what Cursor actually sends to the model. It's shortened (`...`) but the structure is real.

```json
{
  "model": "claude-sonnet-...",
  "max_tokens": 32000,

  "system": "You are an AI coding assistant, powered by Claude. You operate in Cursor.\nYour main goal is to follow the USER's instructions...\n- Before editing a file, read it first.\n- Never commit to git unless the user asks you to.\n- Prefer the dedicated file tools over terminal commands like cat or sed.\n... (several pages of behavior, formatting and safety rules)\n\n<environment>\nOS: Windows 11. Shell: powershell.\nWorkspace: C:\\Users\\you\\RegulatoryRadarDemo. Git repo: yes.\nOpen files: app/main.py (cursor on line 52), tests/test_api.py\n</environment>\n\n<user_rules>\nI'm not a developer. Explain changes in plain language.\n</user_rules>\n\n<project_rules file=\"AGENTS.md\">\n# Regulatory Radar\n- Run the tests with: python -m pytest\n- Never call the real OpenFDA API in tests; use data/fixtures/.\n- Dates are always YYYY-MM-DD.\n</project_rules>\n\n<available_skills>\n- tdd: Test-driven development. Use when the user wants to fix bugs test-first...\n- code-review: Review the changes since a fixed point...\n</available_skills>",

  "tools": [
    {
      "name": "Read",
      "description": "Reads a file from the local filesystem. You can optionally specify a line offset and limit...",
      "input_schema": {
        "type": "object",
        "properties": {
          "path":   { "type": "string", "description": "The absolute path of the file to read." },
          "offset": { "type": "integer", "description": "The line number to start reading from." },
          "limit":  { "type": "integer", "description": "The number of lines to read." }
        },
        "required": ["path"]
      }
    },
    {
      "name": "Shell",
      "description": "Executes a given command in a shell session...",
      "input_schema": {
        "type": "object",
        "properties": { "command": { "type": "string" } },
        "required": ["command"]
      }
    },
    {
      "name": "StrReplace",
      "description": "Performs exact string replacements in files...",
      "input_schema": {
        "type": "object",
        "properties": {
          "path":       { "type": "string" },
          "old_string": { "type": "string" },
          "new_string": { "type": "string" }
        },
        "required": ["path", "old_string", "new_string"]
      }
    },
    { "name": "Grep", "description": "...", "input_schema": { "...": "..." } },
    { "name": "WebSearch", "description": "...", "input_schema": { "...": "..." } },
    { "name": "github_create_pull_request", "description": "(from the GitHub MCP server) ...", "input_schema": { "...": "..." } }
  ],

  "messages": [
    {
      "role": "user",
      "content": "<attached_files>\napp/main.py (lines 42-57)\n...\n</attached_files>\n\n/updates?since=2025-01-01 returns updates from 2024. Why?"
    },
    {
      "role": "assistant",
      "content": [
        { "type": "text", "text": "Let me look at the filter and the date parser." },
        { "type": "tool_use", "id": "call_1", "name": "Read", "input": { "path": "app/main.py" } }
      ]
    },
    {
      "role": "user",
      "content": [
        {
          "type": "tool_result",
          "tool_use_id": "call_1",
          "content": "     1| \"\"\"FastAPI app and routes for Regulatory Radar.\n ...\n    42| @app.get(\"/updates\")\n    43| def updates(\n    44|     jurisdiction: str = Query(\"\", description=\"FDA or EU; empty for both\"),\n ...\n    55|         items = [u for u in items if _parse_update_date(u.date) >= since]\n ... (the whole file, ~150 lines)"
        }
      ]
    },
    {
      "role": "assistant",
      "content": [
        { "type": "tool_use", "id": "call_2", "name": "Shell", "input": { "command": "python -m pytest tests/test_api.py" } }
      ]
    },
    {
      "role": "user",
      "content": [
        {
          "type": "tool_result",
          "tool_use_id": "call_2",
          "content": "============================= test session starts =============================\ncollected 9 items\ntests/test_api.py ...F.....                                              [100%]\n================================== FAILURES ===================================\n>   assert \"fda-udi-requirements\" not in [u[\"id\"] for u in items]\nE   AssertionError: ...\n... (full traceback)\n========================= 1 failed, 8 passed in 0.41s ========================="
        }
      ]
    },
    {
      "role": "assistant",
      "content": [
        { "type": "text", "text": "Found it. `_parse_update_date` tries the format \"%Y%d%m\" (year-day-month) first, so \"2024-12-01\" is read as January 12th... Here's the fix: ..." },
        { "type": "tool_use", "id": "call_3", "name": "StrReplace", "input": { "path": "app/main.py", "old_string": "...", "new_string": "..." } }
      ]
    },
    {
      "role": "user",
      "content": [
        { "type": "tool_result", "tool_use_id": "call_3", "content": "The file app/main.py has been updated successfully." }
      ]
    },
    {
      "role": "user",
      "content": "Great, now run the tests again and commit."
    }
  ]
}
```


Notice the proportions: your new message is about **30 tokens**, and everything above it is about **18,000**. All of it is sent again with every message. `system` and `tools` are there before you type a word, which is why adding many rules, skills, and MCP servers has a cost. `messages` keeps growing: every file the agent reads and every terminal output it sees stays in the window until the chat ends or gets summarized.

Also notice that the model doesn't *run* anything. It only answers with a `tool_use` block ("please run this command"). Cursor runs it on your machine and sends the output back as a `tool_result`, in a new request that contains everything again.

**When the window is almost full, Cursor summarizes** older messages automatically. Summaries lose details, such as the exact decision you made 40 messages ago.

The **context ring** next to the prompt box shows how full the window is. Click it to see what's taking the space: rules, skills, MCP tools, and conversation.


## AGENTS.md: steering the agent

`AGENTS.md` is a plain markdown file in the project root. The harness adds it to **every** conversation in this project.

It's an open standard (<https://agents.md>), read by Cursor, Codex, Copilot, and many others.

Because `AGENTS.md` is loaded on every message, it costs tokens every time. Keep it short and only include things that apply to (almost) every task.

### The Karpathy guidelines

In early 2026 Andrej Karpathy (a founding member of OpenAI and former head of AI at Tesla) [posted a list](https://x.com/karpathy/status/2015883857489522876) of the ways LLM coding agents misbehave: they make wrong assumptions silently, overcomplicate code, and change things they shouldn't. Someone turned his observations into a single instructions file, and [the repo](https://github.com/forrestchang/andrej-karpathy-skills) went viral. The file has four principles:

1. **Think Before Coding:** Don't assume. Don't hide confusion. Surface tradeoffs.
2. **Simplicity First:** Minimum code that solves the problem. Nothing speculative.
3. **Surgical Changes:** Touch only what you must. Clean up only your own mess.
4. **Goal-Driven Execution:** Define success criteria. Loop until verified.

Keep in mind what this file is and isn't. It **doesn't make the model smarter**. It won't teach it FDA product codes or fix a hard algorithm. It's a **behavioral constraint**: it makes the agent stay inside the lines you drew, and ask when the lines are unclear. If your problem is an agent that overreacts to ambiguous instructions, it helps a lot. If your problem is missing domain knowledge, it won't help (skills will, see below).


## Skills

A **skill** is a folder with a `SKILL.md` file: instructions (and sometimes scripts and reference files) that teach the agent *how* to do a specific kind of task. For example: how to brainstorm a feature, how to do TDD, or how your organization reads FDA data.

The main difference from `AGENTS.md` is **when it loads**:

- `AGENTS.md` is loaded into **every** request.
- A skill is loaded **only when it's needed**. The agent sees only each skill's name and one-line description. When a task matches the description (or you type `/the-skill-name`), the full instructions are loaded. That's why you can install dozens of skills without filling the context window.

Cursor reads skills from `.cursor/skills/` and `.agents/skills/` in the project, from `~/.cursor/skills/` for all your projects. Type `/` in the chat to see the skills available to you.

You'll write your own skills in a later tutorial. Before writing one, check whether someone already wrote it.

:warning: A skill is instructions that your agent follows, often with scripts it runs on your machine. Installing a skill means trusting its author. Prefer popular, well-known repos, and **read the `SKILL.md` before you use it**.




# Exercises


### :pencil2: 100% test coverage, with vs. without AGENTS.md guidelines

**What is test coverage?** It's the percentage of your code lines that run when the tests run. A line of code without an associated test is a line nobody checks. If it breaks, you won't know.

A test can pass and still miss things. In `RegulatoryRadarDemo`, `test_recalls_since_keeps_only_newer_recalls` checks the `since` filter on `/recalls`. But no test sends a recall with a **missing or broken date**. The code that handles that case never runs in the tests, so we don't know how it behaves.

We will to have a 100% coverage tests (sometime it is impossible, but we should try to get as close as possible).

Let's see how does the coding agent behaves first with a simple vibe coding, and then with the Karpathy's guidelines in `AGENTS.md`.

#### Without AGENTS.md

Make sure there's no `AGENTS.md` in the project. Open a new chat in **Agent** mode and send:

> Write tests with 100% coverage

Let it finish without helping. Make sure the tests are 100% coverage. Then ask it:

> How many lines of code did you add?

Then discard the changes. 

#### With AGENTS.md

Download the Karpathy guidelines as your `AGENTS.md`:

```bash
curl -o AGENTS.md https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md
```

Open a **new** chat (the file is read when a chat starts), same model, and send the same prompt. When it's done,  make sure the tests are 100% coverage. Then ask the same question.

You should see about **30-40% fewer lines**, with the same coverage.


> [!TIP]
> `AGENTS.md` is usually for things about *your* project: business rules, how to run the tests, what not to touch. The Karpathy guidelines are general and fit any project, so a **Cursor rule** may be a better home for them.
>
> To make it as a rule (for this project only):
>
> 1. Open **Cursor Settings** and go to **Rules** (under **Customize**).
> 2. In the dropdown menu (where **All** is selected), select only your projects' workspace. 
> 3. Name it `karpathy`.
> 4. Copy everything from `AGENTS.md` and paste it into the rule.
> 5. Set it to **Always Apply**, so it's added to every chat, just like `AGENTS.md`.
> 6. Clean up `AGENTS.md`, so the guidelines aren't loaded twice.
>
> The rule is saved in the project's `.cursor/rules/` folder, so it applies only to this project.






### :pencil2: Keep sensitive data away from the agent

Put a fake key in your `.env`:

```ini
OPENFDA_API_KEY=fake-key-12345
```

New chat, **Agent** mode: *"What's the OpenFDA API key configured in this project?"*

The agent opens `.env` and answers `fake-key-12345`. You just asked it to do so. 

**This is a leak.** Remember how the agent works, the agent sends the file's content to the LLM provider, and the answer it writes (with the key in it) becomes part of the chat. 

**With a real key, you would have to revoke it and create a new one.**


A good direction is to block that door with a `.cursorignore` file in the project root:

```text
.env
```

The chat you just used already holds the key, so open a **new** chat. Ask for the API key again. The read tool should refuse `.env`. 

Ignore files limit what the agent reads with its file tools. They are **not** a security boundary. A real secret does not belong on a machine where an agent runs terminal commands.





### :pencil2: Migrate all our data to a database, with Superpowers

Today the app reads its own data from files: products from `data/portfolio.yaml`, updates from `data/updates/*.md`. 

Your mission: migrate the data into a database. According to the requirements below: 

1. Product portfolio, updates, and fixture openFDA data should be loaded into the database.
2. The existing endpoints must keep behaving **exactly** the same.
3. When running the app locally or during tests, it should use a SQLite database file `data/radar.db`. When running in production, it should work with an existing PostgreSQL database. To switch between the two, the app should read the database URL from the environment variable `DATABASE_URL`.


Quite a large and risky change. 
It touches loading, models, tests, and setup, and the existing endpoints must keep behaving **exactly** the same. 

That's where vibe coding will get you into trouble! 

We'll use [Superpowers](https://github.com/obra/superpowers), it is a complete **development process** done by senior engineers as set of skills that call each other.

#### Setp I

First let's install the skill. **When asked, install ALL skills.**

```bash
npx skills add obra/superpowers -a cursor
```

#### Setp II

To work with Superpowers, you usually start with a **brainstorming process** with the agent. 
New chat, **Agent** mode, choose a strong model for brainstorming. 

Type `/brainstorming` to load the skill, and then send the short requirements.

The agent will ask you questions like *When should the portfolio, updates and fixture data be loaded into the database?*. These are **your** decisions.

At the end, the skill writes a **design document** and asks you to approve it. Read it. Is everything you decided there? Is anything there that you *didn't* decide? Fix it before you approve.

#### Setp III

Next, Superpowers writes an implementation plan. A plan is a list of **small**, **simple** tasks with a clear "done" check.

Once you approve the plan, Superpowers is ready to execute the tasks. Two options ahead: 

- **Subagent-Driven (recommended)**: using the `/subagent-driver-development` skill - a fresh subagent handles each task, followed by a two-stage review (subagents will be discussed later on in the course)
- **Inline Execution**: using `/executing-plans` skill - tasks run in the current coversation session . 


> [!TIP]
> Depending on the amount of work, but you might want to execute the plan with relatievly a cheap model, since the plan is just a list of simple tasks.


> [!NOTE]
> Cursor also has a built in Plan mode. It is not as powerful as Superpowers, use it when you need a lightweight planing process. 










### :pencil2: Implement the recalls spec

Take the spec you wrote with `grill-me` and `to-spec`, and implement it with Superpowers. Start a new chat and `@`-mention the spec file. Pay attention to the moment the brainstorming skill asks things the spec already answers. That's the value of writing decisions down.

Verify the result yourself: `pulse-dr` (a pacemaker) must get pacemaker recalls and must **not** get defibrillator or ablation catheter recalls. Write that check as a test.




















### :pencil2: A file bigger than the context window

`data/archive/news_dump.jsonl` is about 4 MB, roughly **1,000,000 tokens**. That's more than any model's context window.

New chat, **Agent** mode:

> Which regulator appears most often in `data/archive/news_dump.jsonl`, and in which year were there the most news items?

Watch what the agent does and keep an eye on the context ring:

- Did it try to read the whole file? Or did it read only the first few lines to learn the format, and then write a small script (or a terminal command) to count?
- Click the context ring. How much of the window did this question use?

If it struggled, open a new chat and give it a better prompt:

> `data/archive/news_dump.jsonl` is too big to read. Look at its first 3 lines to learn the format, then write and run a short Python script that answers: which regulator appears most often, and which year had the most news items?

Check one number yourself. This command counts the FDA items: `grep -c '"jurisdiction": "FDA"' data/archive/news_dump.jsonl` (Windows PowerShell: `(Select-String '"jurisdiction": "FDA"' data/archive/news_dump.jsonl).Count`).








### :pencil2: Get grilled before you build

Remember the vibe-coded `GET /products/{product_id}/recalls` endpoint from the previous tutorial? The hard part wasn't the code. It was the decision about what counts as a "relevant" recall, and the agent made that decision without asking.

`grill-me` reverses the roles: the agent interviews **you**, one question at a time, until the plan has no open decisions.

New chat, **Agent** mode:

> /grill-me I want an endpoint `GET /products/{product_id}/recalls` that returns the recalls relevant to each product in our portfolio.

Answer the questions. When you don't know an answer, say so and ask the agent to research it. Hints:

- In the FDA world a device type is identified by a 3-letter **product code**, and every recall carries one (`product_code`). Our products in `data/portfolio.yaml` have empty `product_codes` lists. Who fills them in, and from what? (Look at `data/fixtures/classification.json`.)
- Should recalls of *any* company count, or only our competitors'? How far back?

When the interview is done, run `/to-spec` to turn the conversation into a written spec. If it asks you to run `/setup-matt-pocock-skills` first, do that. Read the spec and commit it. We implement it in the exercises at the end of this tutorial.

Compare: how many decisions are in this spec that the vibe-coding run made silently?








### skills.sh

[skills.sh](https://skills.sh) is a public directory of agent skills (run by Vercel), with a leaderboard of the most installed ones. It comes with a CLI:

```bash
npx skills find <topic>                  # search for skills
npx skills add <owner/repo> -a cursor    # install skills from a GitHub repo for Cursor
npx skills list -a cursor                # list what's installed
```
