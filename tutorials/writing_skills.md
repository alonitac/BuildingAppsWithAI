# Writing Skills

So far you've used skills that other people wrote. In this tutorial you'll write your own.

Remember what a skill is: a folder with a `SKILL.md` file that teaches the agent how to do one kind of task. The agent sees only the skill's **description** all the time. It loads the rest of the file only when the description matches what you asked.

We'll keep working on the **Regulatory Radar** app (`RegulatoryRadarDemo`).

## Where skills live

```text
.cursor/skills/              # project skills: committed, the whole team gets them
  git-workflow/
    SKILL.md                 # the instructions (required)
~/.cursor/skills/            # user skills: only on your computer, in all your projects
```


`SKILL.md` might be looking like (the folder name and the `name` in the file must be the same, `git-workflow`.)

```markdown
---
name: git-workflow
description: How we use git and GitHub in this project. Use whenever you're about to change code, commit, push, or open a pull request.
---

# Git workflow

## Before you change code
1. ...
```

The part between the `---` lines is the **frontmatter**:

| Field | What it's for |
| --- | --- |
| `name` | Lowercase, with dashes. Same as the folder name. |
| `description` | **The most important line.** The agent decides whether to load the skill based on it alone. |
| `disable-model-invocation` | Optional. `true` means the skill runs only when you type `/name`, never automatically. |
| `paths` | Optional. Load the skill only when working on matching files, like `tests/**`. |

## How to write a good skill

**1. The description says *what* and *when*.** "Git helper" won't load when it should. "How we use git and GitHub in this project. Use whenever you're about to change code, commit, push, or open a pull request." will. Mention the words people actually use when asking. Be a bit pushy: agents tend to skip skills, not overuse them.

**2. Short.** The agent is already smart. Write only what it **doesn't** know: your team's rules, your names, your order of steps. Keep `SKILL.md` well under 100-200 lines. Move long reference material to `references/` and point to it ("for the full list of product codes, read `references/product-codes.md`").

**3. Explain why.** "Never commit to `main`" works. "Never commit to `main`: it's protected, and the push will be rejected" works better. When the agent understands the reason, it handles situations you didn't think of.

**4. Concrete steps and examples.** Numbered steps for a process. A real example of a good output (a branch name, a commit message, a PR description) is worth a paragraph of explanations.

**5. Say when to stop and ask.** "If the tests fail, don't push. Show me the failure and ask."

## Tools for writing skills

You don't have to write skills from scratch. Let an agent interview you and write the first draft:

- **`/create-skill`** (built into Cursor): asks what the skill should do, and creates the folder and `SKILL.md` in the right place. Start here.
- **`skill-creator`** (by Anthropic): goes further. It interviews you about edge cases, writes the skill, and then **tests it with evals** (see below). Install it:

    ```bash
    npx skills add anthropics/skills --skill skill-creator -a cursor
    ```

    Some of its advanced parts (like the automatic description tuning) were built for Claude Code, and may not run in Cursor. Writing the skill and running the evals work fine.

Whatever tool you use, **read the result**. It's your team's process, not the agent's.

## Skill evals

How do you know your skill works? You test it, like code. An **eval** is a test for a skill:

1. **A prompt**, like a real user would write: *"Add a `/version` endpoint"*.
2. **What should happen**, as checks you can verify: "a new branch starting with `feat/` was created", "nothing was committed to `main`".
3. **Run it with the skill and without it**, and compare. If the result is the same, the skill doesn't add anything.

Evals check two things: that the skill **loads** when it should (and doesn't when it shouldn't), and that once it's loaded, the agent **does the right thing**.

### How evals are graded

You ran the prompt. Now who decides if it passed? There are three ways, and good evals mix them:

- **Code checks.** Anything you can check with a command, check with a command. Is the current branch `feat/...`? Run `git branch --show-current`. Is `main` untouched? Run `git log origin/main..main` (empty means no new commits). It's fast, free, and always gives the same answer. Use it whenever you can.

- **LLM as a judge.** Some things a command can't check: "is the PR description clear?", "did the agent explain why the tests failed?". So you give **another model** the output, plus the checks, and ask it to grade: pass or fail for each check, and the **evidence** (a quote from the output). It's flexible, but the judge is an LLM too, so it can be wrong.

- **Human review.** You read some of the results yourself. Especially at the start, to make sure the judge grades like you would.

Agents are not deterministic, so one good run proves little. Run each eval a few times, and look at the **pass rate** (for example, 5 of 6 runs passed), with and without the skill.

`skill-creator` automates all this. It keeps the evals in `evals/evals.json` inside the skill folder. For each prompt, it starts two subagents, one with the skill and one without, then a **grader** agent (an LLM judge) checks each assertion, and writes a report with pass rates, time, and tokens:

```json
{
  "skill_name": "git-workflow",
  "evals": [
    {
      "id": 1,
      "prompt": "Add a GET /version endpoint that returns the app version.",
      "expected_output": "Work happens on a new feat/ branch, tests run before pushing, and a PR is opened.",
      "assertions": [
        "A branch starting with feat/ was created",
        "No commit was made on main",
        "The tests ran before the push"
      ]
    }
  ]
}
```

Every time you change the skill, run the evals again, to make sure you didn't break something that worked.


# Exercises

### :pencil2: A git workflow skill

In the previous tutorials, you did the git flow by hand: create a branch, commit, push, open a PR, wait for CI. Let's teach the agent to do it on its own, every time it writes code.

New chat, **Agent** mode:


> /create-skill A project skill called `git-workflow` that makes the agent follow our git workflow every time it changes code:
> - Never work on `main`. Before changing code, pull `main` and create a branch: `feat/...` for features, `fix/...` for bugs, `docs/...` for docs.
> - Never commit `.env` or other secrets.
> - When the work is done, push the branch and open a PR to `main`, with a short description: what changed, why, and how it was tested.
> - Never merge the PR. A person merges, after review and green CI.


Read the `SKILL.md` it created, and check it against the guidelines above.

> [!NOTE]
> How does the agent open a PR? For now, it can push the branch and give you the link to open the PR on GitHub. In the next tutorial (MCP), you'll let it open the PR by itself.

Commit the skill. It's a project skill, so after you merge it, everyone on the team gets it.

Let's try it. Start on `main`. New chat:

> Add a `GET /health/details` endpoint that also returns the number of products and updates.

Don't mention git at all. Did the agent create a branch on its own? Commit? Run the tests? Push?

### :pencil2: Skills evals

Does your `git-workflow` skill really work? Let's ask `skill-creator` to test it.

New chat, **Agent** mode:

> /skill-creator Write evals for the `git-workflow` skill. If possible, use code checks. Otherwise, use an LLM as a judge. Run the evals, with and without the skill.

Look at what it created (usually an `evals/evals.json` folder inside the skill):

- **The prompts.** Are they realistic? Is there at least one prompt where the skill should **not** load?
- **The checks.** Which ones are code checks (a command like `git branch --show-current`), and which ones need a judge? Could any of the judge checks be a code check?

Missing something? Ask it to add it.

If an eval failed, improve the skill (usually the description), and run **all** the evals again. A change that fixes one eval can break another.

