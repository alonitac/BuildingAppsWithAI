# Subagents and hooks

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

## Hooks

A **hook** is a script Cursor runs at a fixed moment in the agent's loop. Cursor hands the script a small JSON description of what is about to happen. The script prints JSON back: allow it, write it down, or refuse it.

You list your hooks in `.cursor/hooks.json`. Each entry names the moment and the script, for example: 

```json
{
  "version": 1,
  "hooks": {
    "beforeSubmitPrompt": [
      { "command": ".cursor/hooks/audit-log.sh", "timeout": 5, "failClosed": false }
    ]
  }
}
```

`failClosed: true` means a crash, a timeout, or invalid JSON counts as a refusal. A guard should fail closed.


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




### :pencil2: Audit log, secret guard, and model allow list

In this exercise we will see three hooks: an audit log, a secret guard, and a model allow list.

The scripts are in `hook_examples/`. macOS and Linux use the `.sh` file. Windows uses the `.ps1` file, because the Cursor app on Windows runs hooks in PowerShell. 


1. **Audit log**

    A security regulation may require a record of every prompt sent to an AI tool, and of every command the agent ran. 

    1. Copy the `audit-log` script into the `.cursor/hooks` folder in the ChatRAG project.

    2. Create `.cursor/hooks.json`.

        macOS and Linux:

        ```json
        {
          "version": 1,
          "hooks": {
            "beforeSubmitPrompt": [
              { "command": ".cursor/hooks/audit-log.sh", "timeout": 5, "failClosed": false }
            ],
            "beforeShellExecution": [
              { "command": ".cursor/hooks/audit-log.sh", "timeout": 5, "failClosed": false }
            ],
            "afterShellExecution": [
              { "command": ".cursor/hooks/audit-log.sh", "timeout": 5, "failClosed": false }
            ],
            "afterFileEdit": [
              { "command": ".cursor/hooks/audit-log.sh", "timeout": 5, "failClosed": false }
            ]
          }
        }
        ```

        Windows. Same moments. PowerShell is slower to start, so the timeout is 20 seconds:

        ```json
        {
          "version": 1,
          "hooks": {
            "beforeSubmitPrompt": [
              { "command": "powershell -NoProfile -ExecutionPolicy Bypass -File .cursor/hooks/audit-log.ps1", "timeout": 20, "failClosed": false }
            ],
            "beforeShellExecution": [
              { "command": "powershell -NoProfile -ExecutionPolicy Bypass -File .cursor/hooks/audit-log.ps1", "timeout": 20, "failClosed": false }
            ],
            "afterShellExecution": [
              { "command": "powershell -NoProfile -ExecutionPolicy Bypass -File .cursor/hooks/audit-log.ps1", "timeout": 20, "failClosed": false }
            ],
            "afterFileEdit": [
              { "command": "powershell -NoProfile -ExecutionPolicy Bypass -File .cursor/hooks/audit-log.ps1", "timeout": 20, "failClosed": false }
            ]
          }
        }
        ```

    3. New chat. Send:

        > List the files in this folder, then add a blank line at the end of `README.md`.

        Open `.cursor/hook-logs/audit.jsonl`.

2. **Secret guard**

    We want to avoid API keys, tokens, and private keys in an AI chat. After the prompt is sent, the key is on the model provider's side. A hook on `beforeSubmitPrompt` is the efficient control: it reads the prompt and refuses it before Cursor sends it.

    1. Copy the `sensitive-prompt-guard` script into the `.cursor/hooks` folder in the ChatRAG project.

    2. Copy the following JSON into `.cursor/hooks.json` (or ask your agent to merge it with the existing file)

        macOS and Linux:

        ```json
        {
          "version": 1,
          "hooks": {
            "beforeSubmitPrompt": [
              { "command": ".cursor/hooks/sensitive-prompt-guard.sh", "timeout": 5, "failClosed": true },
            ]
          }
        }
        ```

        Windows:

        ```json
        {
          "version": 1,
          "hooks": {
            "beforeSubmitPrompt": [
              { "command": "powershell -NoProfile -ExecutionPolicy Bypass -File .cursor/hooks/sensitive-prompt-guard.ps1", "timeout": 20, "failClosed": true }
            ],
          }
        }
        ```

    3. New chat. Send this fake key. It has the shape of an OpenAI key, and it is a fake:

        > Here is a key: sk-thisisafakeopenaikey0123456789abcd

        Expect Cursor to refuse it before sending: *This prompt appears to contain sensitive data (OpenAI API key). Remove or replace the sensitive value before resubmitting.*

3. **Model allow list**

    This hook allows a prompt only when the model you picked is on a list stored in the repo. The list is `allowed-models.txt`, next to the script. You edit that file. The script reads it on every prompt.

    1. Copy `allow-models` (both script and list file) into the `.cursor/hooks` folder in the ChatRAG project.

    2. Replace `.cursor/hooks.json` with this file. The allow-list hook is first on `beforeSubmitPrompt`, with `failClosed` set to `true`.

        macOS and Linux:

        ```json
        {
          "version": 1,
          "hooks": {
            "beforeSubmitPrompt": [
              { "command": ".cursor/hooks/allow-models.sh", "timeout": 5, "failClosed": true }
            ],
          }
        }
        ```

        Windows:

        ```json
        {
          "version": 1,
          "hooks": {
            "beforeSubmitPrompt": [
              { "command": "powershell -NoProfile -ExecutionPolicy Bypass -File .cursor/hooks/allow-models.ps1", "timeout": 20, "failClosed": true }
            ]
          }
        }
        ```

    4. New chat, still on the model you left off the list. Send any short message, such as:

        > What is the title of this repo?

