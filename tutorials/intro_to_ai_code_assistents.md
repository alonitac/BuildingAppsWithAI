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

A **skill** is one or more Markdown files that teach the agent how to do one specific kind of task. 
Think of it as the onboarding document you'd hand a new team member: "here's how we do X". 

Each skills has it's own folder with a `SKILL.md` file of instructions, and it can also hold scripts for the agent to run, templates, and reference documents.

Skills are an open standard ([agentskills.io](https://agentskills.io)), so the same skill works in Cursor, Claude Code, Codex, and others.

Two kinds of skills (but many skills mix both kinds): 

- **Procedural skills** teach a *process*: which steps to take, in what order, and when to stop and ask you.
- **Knowledge skills** teach *what the model doesn't know*: your company's conventions, an internal API, or how to read FDA data. 

Here's a knowledge skill for our app:

```markdown
---
name: openfda-devices
description: How to query and interpret openFDA medical device data (recalls, classification, product codes). Use when working with FDA recalls or device classification.
---

# openFDA device data

[useful information the agent should know about how your organization works with openFDA data]
```

The header (a.k.a. **Frontmatter**) is used to identify the skill and provide a description.

The agent decides if the description fits what you asked, and loads the full `SKILL.md`, usually **automatically**. You don't have to ask for it. But if you want to, you can type `/` in the chat and pick it from the list (for example `/brainstorming`). The skill applies to that one message only.


### Built-in skills

Cursor comes with [built-in skills](https://cursor.com/docs/skills#built-in-cursor-skills), for example `/create-skill` (helps you write a new skill), `/create-rule`, `/canvas` (builds an interactive report next to the chat), and `/review`. They show up in the `/` list next to the skills you add.

### Project skills vs. user skills

Where a skill's folder lives decides where it works:

- **Project skills** live inside the project, in `.cursor/skills/` or `.agents/skills/`. They work only in this project, and since they're in the repo, everyone who clones it gets them. Use them for project knowledge, like the `openfda-devices` skill above.
- **User skills** live in your home folder, in `~/.cursor/skills/` or `~/.agents/skills/`. They work in all your projects, but only on your machine. Use them for your personal way of working.


:warning: A skill is instructions that your agent follows, often with scripts it runs on your machine. Installing a skill means trusting its author. Prefer popular, well-known repos, and **read the `SKILL.md` before you use it**.

### The `research` skill in action 

Let's install a useful skill by Matt Pocock: `/research`

```bash
npx skills add mattpocock/skills -a cursor
```

When asked, install All Matt Pocock skills, one of them is `research` (we will use many of Matt's skills later).


The `/research` skill is a single `SKILL.md` file that look like this:

```markdown
---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Spin up a **background agent** to do the research, so you keep working while it reads.

Its job:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it where the repo already keeps such notes; match the existing convention, and if there is none, put it somewhere sensible and say where.
```

Now let's see it in action. Open a new chat in **Agent** mode and send a simple question WITHOUT `/research` skill:

> What is the meaning of the product code OAE?

The agent answers the question, and even might fetch some information from the internet. 

Now try it again, but with `/research` skill:

> /research What is the meaning of the product code OAE?

The agent answers the question. But since the agent now has much more trusted information, it also points to a mismatch in the data `fda_pathway` in `portfolio.yaml`.


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

> [!WARNING]
> Ignore files limit what the agent reads with its file tools. They are **not** a security boundary.
>
> Can you think of a simple prompt to bypass this?
>
> A real secret does not belong on a machine where an agent runs terminal commands.


### :pencil2: Find related recalls, with Matt Pocock's skills set

When a device is recalled, the RA team wants to know: *could the same problem hit one of our products?* The current API doesnt provide a convenient way to know that. 

We want to add a **related recalls** endpoint.

> `GET /products/{product_id}/related-recalls` returns the recalls that may be relevant to one of our products. Each recall comes with a few facts: which product code matched, whether the recall is still open, and when it started.

The endpoint doesn't decide which recall matters most. It gathers the candidates and the facts, and a person judges. (Later in the course, when we learn MCP, an AI agent will use this endpoint and do the judging.)

It sounds simple, but "may be relevant" hides business decisions:

- Each product in `data/portfolio.yaml` has a few product codes. The first one or two describe the product itself, and the others are related devices (for example, the wires of a pacemaker). Should the endpoint return recalls for all of them?
- Some recalls are still **open**, others are already closed. Show both?
- Should a 10-year-old recall still show up?

Hand this to an agent as is, and it will make these decisions for you, silently.

[Matt Pocock](https://github.com/mattpocock/skills) publishes a set of small skills he uses every day. Each skill does one job. You call them with `/`. In this exercise you'll go through this set:

| Skill | What it does here |
|---|---|
| `/setup-matt-pocock-skills` | One-time setup: tells the other skills where to save tickets and docs. |
| `/grill-with-docs` | The agent interviews **you** until no decision is left open, and writes the decisions down. |
| `/to-spec` | Turns the interview into a spec. |
| `/to-tickets` | Splits the spec into small tickets. |
| `/implement` | Builds one ticket, test first (`/tdd`), then reviews its own code (`/code-review`). |
| `/diagnosing-bugs` | Fixes a bug by reproducing it first, not by guessing. |

You already installed Matt's skills in the `/research` section.

#### Step I: setup

New chat, **Agent** mode:

> /setup-matt-pocock-skills

For **Issue tracker**, choose **Local markdown** (tickets become files under `.scratch/`). Keep the other defaults, and choose `AGENTS.md` if asked.

#### Step II: get grilled

Open a **new** chat:

> /grill-with-docs [paste the mission above]

The agent asks you questions and usually suggests an answer. Don't just accept it, these are **your** decisions.

Watch the file tree while you answer. `CONTEXT.md` (a glossary of your terms, for example what a "related recall" is) and `docs/adr/` (an architecture decision record, if needed, depending on your project) appear. Future chats read them, so the decisions survive this chat.

The agent might suggest to implement or to write tests. But don't do it yet, we want to write a spec first.

#### Step III: write the spec

Same chat:

> /to-spec

Read the spec. I know, it is a lot of text, try to read it carefully. Is everything you decided there? Is there anything you *didn't* decide?


#### Step V: implement, one ticket per chat

Same chat:

> /implement

Implement itself invokes a few other skills

- Build the feature test-first with `/tdd` (test driven development write tests first, then the code that makes them pass)
- Run the full test suite once at the end.
- Run `/code-review`, which checks the code against the repo's standards and against the spec.


> [!TIP]
> You don't need to remember all of Matt's skills. Describe your situation to `/ask-matt`, and it tells you which skills to use, and in which order. For example: *"/ask-matt I got a pile of bug reports, where do I start?"*



### :pencil2: Migrate all API data to a database, with Superpowers skills set

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

