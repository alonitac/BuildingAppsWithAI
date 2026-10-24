# The Cursor Agents Window

So far you've worked with **one agent, in one repo, inside the IDE**. The **Agents Window** is a different view of Cursor. It's not built around files. It's built around **agents**: you start them, watch them, review what they did, and merge it.

Open it from the Command Palette (`Ctrl+Shift+P` → **Agents Window**). The editor is still there; you can jump back to it any time.

## Why use it

**1. Many repos in one place.** The sidebar lists all your agents, grouped by repository. One agent can work on `ChatRAG`, another on the RAGFlow docs, a third on a backend repo. You don't need to open three editor windows.

**2. Many agents in parallel.** Each agent runs in its own place.

**3. Cloud agents.** A cloud agent runs on a computer in Cursor's cloud, with its own copy of the repo. It can build and test the app while your laptop is closed. Start one here, watch it in the sidebar, and pull it back to your computer when you want to try the changes yourself.

**4. Automations.** An automation starts a cloud agent for you, on a schedule or when something happens (a pull request, a Slack message, a webhook). You create it in this window, and every run shows up in the same sidebar. The **Automations** section below shows how.

## Projects

A chat is good for one task. Some work is too big for one chat: a new feature, a migration, a whole app. That's what a **Project** is for.

In a Project, you talk to a **coordinator** agent. The coordinator **doesn't write code**. It plans the work, starts other agents to do the coding, and brings their results back to you.

A Project has:

- **The coordinator**: the agent you chat with.
- **Agents**: the coding agents it started. Click one to see what it's doing or to talk to it directly.
- **Shared context**: files that every agent in the Project can read: research, notes about the codebase, your preferences. A new agent doesn't need to learn everything from scratch.
- **Subscriptions**: things the coordinator listens to and reacts to by itself: a Slack channel, a schedule, pull request activity. Ask for one in the chat ("every time CI fails on `main`, start an agent to fix it"). A **Listening** pill appears above the chat input.

**Why use it:** the Project remembers the context for weeks, runs many agents under one conversation, and runs in the cloud, so the work continues when your laptop is closed.

**Create one:** in the sidebar, **Projects** → **New Project**. Pick a name, a repository under **Workspace**, and the coordinator's model under **Model**. Then describe the work in the chat.


## Automations

An **automation** is a cloud agent that starts by itself when a **trigger** fires. You write the prompt once; Cursor runs it every time.

| Trigger | Example |
| --- | --- |
| **Scheduled** | Every Monday at 08:00 (a cron expression). |
| **GitHub** | Pull request opened, pull request merged, push to branch, CI completed... |
| **Slack / Linear / Sentry / PagerDuty** | New message in a channel, Linear issue created, Sentry error... |
| **Webhook** | Anything that can send an HTTP `POST`. |

An automation also has **tools** it's allowed to use (open a pull request, comment on a pull request, send to Slack, an MCP server) and a **repository** setting (no repository, one repository, or several).


### Example: a weekly dependency check

| Setting | Value |
| --- | --- |
| Trigger | **Scheduled**, cron `0 8 * * 1` (every Monday at 08:00) |
| Repository | `ChatRAG`, branch `main` |
| Tools | Pull request creation |

Prompt:

```text
Check the npm dependencies of this repo.

1. Run `npm outdated` and `npm audit`.
2. Update only patch and minor versions. Never update a major version:
   those can break the app, and a human should decide.
3. Run `npm run build` and `npm run lint`. If either fails, undo the update
   that broke it.
4. If anything changed, open one pull request titled
   "chore: weekly dependency update", and list every package you updated
   (old version -> new version) in the description.
5. If nothing needs updating, don't open a pull request.
```

Every Monday you get one small PR to review, or nothing.

> [!TIP]

Automations have **memory** (`MEMORIES.md`) between runs. Useful ("last week I skipped `next` 16 because..."), but don't let untrusted input write into it.

## Exercises

### Exercise 1: connect GitHub

Cloud agents and automations work on GitHub, not on your laptop. They need access to your repo.

1. In the Agents Window, open **Settings** → **Integrations** → **GitHub** → **Connect**. (Or go to [cursor.com/dashboard](https://cursor.com/dashboard) → **Integrations**.)
2. GitHub asks you to install the **Cursor GitHub App**. Choose **Only select repositories** and pick your `ChatRAG` repo. Give the agent only the repos it needs.
3. Check it works: start a **Cloud** agent on `ChatRAG` and ask:

   > Add a short "Troubleshooting" section to README.md about what to do when RAGFLOW_URL is wrong. Open a pull request.

4. Watch the agent in the sidebar. When it's done, open the pull request on GitHub and review it.


