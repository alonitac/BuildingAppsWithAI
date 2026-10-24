# Subagents

## The problem: a full context window

Every file the agent reads, every search and every command output stays in the chat's **context window**. Ask it to *"review the whole app"*, and after 30 files the context is full of code that isn't needed anymore. The agent gets slower, more expensive, and starts to forget what you asked at the beginning.

## How a subagent helps

A **subagent** is an agent that your main agent starts to do one focused job. It has its **own, fresh context window**.

- The subagent might read 30 files and run 10 commands. Your main chat gets back only its **short report**. Your main context stays clean.
- Several subagents can run **in parallel**.
- A subagent can use a different (cheaper, faster) model, or be restricted to read-only.

The trade-off: the main agent sees only the report, not the work. If the report is wrong, the main agent won't know. And every subagent costs tokens.

## Ad-hoc subagents: just ask

You don't need to set anything up. Ask:

> Use a subagent to find every place where ChatRAG calls the RAGFlow API, and report back the endpoint, the method and the file.

Cursor then:

1. **Writes a prompt** for the subagent: the task, and the context it needs from your chat.
2. **Hands it** to the subagent, which starts with an empty context.
3. **Lets it run**: it reads, searches and runs commands, on its own.
4. **Gets back the report**, and continues your conversation with it.

Click on the subagent in the chat to see the prompt Cursor wrote for it, and what it did.

Cursor also has built-in subagents. The most common is **Explore**, a fast read-only code searcher, which the agent often uses without you asking.

## Custom subagents

When you give the same kind of job again and again, define a subagent once: a markdown file in `.cursor/agents/` (or `~/.cursor/agents/` for all your projects).

```markdown
---
name: my-subagent
description: What it does, and when to use it. The main agent reads this to decide when to call it.
model: inherit       # or: fast
readonly: false      # true: it can't edit files
---

The instructions: the steps it follows, and exactly what to report back.
```

Like a skill, the `description` decides when it's used: the agent calls it when the description matches the task, or when you ask by name (*"use the my-subagent subagent"*). The difference: a skill adds instructions to **your** context, a subagent does the job in **its own** context.

You can also type `/create-subagent` and let Cursor write the file for you.

# Exercises


### :pencil2: An accessibility subagent

In the Next.js tutorial you checked the app for accessibility with axe. Every change to the UI can break it again, so let's give this job to a subagent.

1. Create `.cursor/agents/a11y-fixer.md`:

    ```markdown
    ---
    name: a11y-fixer
    description: Checks the app for accessibility (WCAG 2.2 AA) with axe, and fixes the violations. Use proactively after every change to the UI.
    model: inherit
    ---

    1. If there's no axe test yet, add `@axe-core/playwright` and write a Playwright test in
       `tests/a11y.spec.ts` that checks the main pages, with a chat open, for WCAG 2.2 AA
       violations. Fail on serious and critical violations.
    2. Run `npx playwright test tests/a11y.spec.ts`.
    3. Fix each violation in the code. Never change the test to make it pass.
    4. Run the test again, until it passes. Then run `npm run lint` and `npm run build`.

    Report back very shortly: which violations you found, and which files you changed.
    ```

2. Break it on purpose. New chat:

    > Add a "Clear chat" button with only a 🗑️ icon in it, next to the Send button. Make the placeholder text of the input light gray.

    Did the agent call `a11y-fixer` by itself? If not, ask it to. What did the subagent find (hint: a button with no name, and low contrast), and what came back to the main chat?
3. Review the diff. Did it fix the code, or did it change the test?




### :pencil2: Hooks: stop secrets from leaking to the LLM

Everything the agent reads is sent to the LLM provider: every file, every command output, every message you write. That includes `.env.local`, with your RAGFlow API key.

A rule (*"never read `.env` files"*) is a **request**. The model usually follows it. A **hook** is a script Cursor runs before the agent acts, and the script can refuse.

`.cursorignore` only stops the file reader. The terminal is a separate door.

| Hook | Runs before... | Can |
| --- | --- | --- |
| `beforeReadFile` | the agent reads a file | Block the read |
| `beforeShellExecution` | the agent runs a terminal command | Block the command |
| `beforeSubmitPrompt` | your message is sent | Block the message |

**Step I: without the hook.** `.env.local` can already be in `.cursorignore`. Open a new chat anyway:

> Run `cat .env.local`

On Windows: *Run `type .env.local`*.

The agent runs the command. The reply includes the file, API key and all. That output is part of the chat, so the key has been sent to the LLM provider. `.cursorignore` only limits the file reader. This request went through the shell, so the key still left the machine.

**Step II: have the agent write the hook.** New chat. Paste this, and let the agent create the files:

> Write a Python hook for this project that stops secrets from reaching the LLM. Create `.cursor/hooks/protect-secrets.py` and register it in `.cursor/hooks.json` on `beforeReadFile`, `beforeShellExecution`, and `beforeSubmitPrompt`. Block reading secret files (`.env`, `.env.local`, `.pem`, and anything in `secrets/`; allow `.env.example`), block a terminal command that touches those files, and block a chat message that contains an API key or a private key. Also block a file whose contents look like a key, whatever its name. If the script crashes, block the action (`failClosed: true`). Use the Python installed on this machine. Explain each check in plain language.

Save, and restart Cursor if the hook does not appear under **Hooks** in settings.

**Step III: the same prompt, with the hook.** New chat:

> Run `cat .env.local`

The command never starts. Cursor shows that the hook blocked it. The chat has no key in it.

Commit `.cursor/hooks.json` and the Python script. Every teammate gets the same protection. To protect all your projects, put the same files in `~/.cursor/` instead.


A hook is a strong guardrail. The strongest protection is to keep production secrets off a laptop where an agent can run commands.