# Multica

So far your agents have lived inside Cursor: one chat, one repo, on your laptop. **Multica** is a shared workspace where people and agents work the same list of issues. You write the requirement as an issue and assign it. The agent posts progress and a result on that issue.

Multica records and coordinates the work. A computer you connect does the execution, with a coding tool already installed there (Claude Code, Codex, or another tool Multica detects).

The work in this tutorial is on **ChatRAG**, the app from the UI tutorial. Use your own copy of that repo.


## The pieces

| Piece | What it is |
| --- | --- |
| **Workspace** | The team's home. Issues, agents, and repositories belong to one workspace. |
| **Runtime** | A computer you connect. An online runtime claims a run and starts the coding tool. |
| **Agent** | A teammate with a name, a model, and instructions. You assign it issues and `@`-mention it. |
| **Issue** | The unit of work: description, status, assignee, comments, and linked pull requests. |
| **Squad** | A named group with a leader. You assign the issue to the squad; the leader hands out the work. |
| **Skill** | A reusable method (`SKILL.md`). Same idea as a Cursor skill. Attach it to any agent. |
| **Autopilot** | A schedule or a webhook that starts a run for you. |

A run has five steps. The issue holds the context. Multica creates a run. A runtime on your computer claims it. The coding tool works locally. Results are written back onto the issue.
Agents start only when something triggers them: you assign an issue, you `@`-mention them, you chat with them, or an Autopilot fires.

## Create a helper

The first agent handles workspace chores: creating issues, changing status, answering what is going on. Code stays out of its job.

Open **Agents** under **AI Team** and click **New agent**. Choose the runtime: one of the coding tools on the computer you connected. Then fill in:

- **Name**: `Multica helper`
- **Model**: an everyday model on that tool. The official walkthrough uses Sonnet.
- **Instructions**:

```text
You are the helper of this workspace.

Members ask you, in issues and in chat, to create or update issues,
change statuses, and answer questions about the workspace.

Keep replies short. When you finish, reply with one line saying what
you did. Leave code and repositories alone. If a request is unclear,
ask before you act.
```

Leave the other fields at their defaults and click **Create agent**. On the Agents page, the helper should show as online.

## Create an engineer from chat

ChatRAG needs an agent that writes code. The workspace already has an agent, so the helper can create the next one.

Open **Chat**, select Multica helper, and send:

> Create an agent named Engineer on the same runtime as you. Use a stronger coding model (Opus). Engineer builds and maintains ChatRAG, a Next.js chat app. It may change code and open pull requests. It does not manage other agents. It must never read, print, or commit `.env.local` or any API key.

The helper creates the agent on that computer and replies with the name and model. A new agent can be run by its creator. Leave that as it is.

Open **Agents → Engineer**. Check the model, and read the instructions the helper wrote (what it owns, how it gets the repository, how it submits changes). Edit them whenever you want.

## Register ChatRAG

ChatRAG is already on GitHub, from the UI tutorial. Agents pick a repository from **Settings → Code**, so register your copy.

In **Chat**, select Engineer. Put your own GitHub address in the message:

> Register my existing ChatRAG repository in this workspace:
>
> `multica repo add --url https://github.com/<your-username>/ChatRAG`
>
> Do not create a new repository. Reply with the address you registered.

Open **Settings → Code** and confirm ChatRAG is in the list. You can also add it yourself on that page with **Pick from GitHub**.

Then click **Connect GitHub** and authorize that repository. After that, a pull request whose title or branch contains the issue id (for example `MUL-1`) links to the issue, and the issue shows pull-request state and CI results.

## The first issue

From here, day-to-day work is an issue handed to an agent. ChatRAG already runs. This issue changes the screen, and leaves the chat behavior alone.

Click **New Issue** at the top of the sidebar (shortcut `C`). In the default agent mode there is no title box. Choose Engineer under **Created by**, and write the description. Multica generates the title when you submit. Switch to manual mode if you want to write the title yourself.

```text
Work in the ChatRAG repository registered in this workspace.

ChatRAG is an internal assistant that answers questions about our
company's documents. Change the screen only. Do not change the API
routes or the RAGFlow calls. Do not read, print, or commit .env.local
or any API key.

The screen needs:

- A header with the product name and one sentence about what it answers
- An empty chat that says what to ask, with two example questions the
  user can click to fill the input
- An input placeholder that says what kind of question to type
- A layout that stays usable on a phone

Design: quiet and careful, for an internal tool. Show that through
layout, type, and spacing. Keep the words "premium" and "high-end"
out of the copy. Choose the fonts yourself.

Run `npm run lint` and `npm run build`. Open a pull request when it
is ready.
```

The description carries three kinds of information: a constraint (screen only, leave the API alone), the content, listed item by item, and an open choice (the look). Write the intent and the boundaries. Leave the implementation to the agent.

Submit. Multica creates the issue (`MUL-1`, with a generated title) and assigns Engineer. The status moves to **In Progress**.

The right side of the issue holds the status, the assignee, linked pull requests, and the execution log. Open the current run from the status badge next to the title, or from **Execution log**. **Agent** rows are the agent's own narration. **Bash**, **Read**, and **Edit** are the commands it ran and the files it read and wrote. The info button in the log shows the computer, the coding tool, and the working directory for this run.

The run takes a few minutes.

## Review it in chat

When the run ends, Engineer moves the status to **In Review**. A notification lands in your **Inbox**, and Engineer posts a completion comment, often with screenshots of the pages.

Screenshots are a sketch. Open ChatRAG in a browser. A chat button sits in the bottom-right of any page; it is the same chat as **Chat** in the sidebar. Open it, select Engineer, type `@`, and pick the current issue so the conversation carries that issue. Then send:

> Start ChatRAG on this computer with `npm run dev` and give me the address to open. This issue asked for a pull request. If the Pull requests panel on the issue is empty, say why, and fix the link.

Read the reply. Open the address. A pull request often fails to link because the title, branch, and body omit `MUL-1`, so Multica has nothing to match. Once the id is on the pull request, a card appears on the right of the issue, with state and the size of the change. Click it to open the pull request on GitHub. Repositories with CI also show check results there.

## Write the correction into the instructions

This review usually surfaces two habits: a long run of screenshots at the end, and pull requests that omit the issue id. Both will happen on the next issue too. Change the instructions. Leave this issue as it is.

In the same conversation:

> Add two rules to your own instructions with `multica agent update`.
> 1. Skip screenshot checks of your own work. A person reviews ChatRAG in a browser.
> 2. The branch name or the title of every pull request must include the issue id, such as MUL-1, so the pull request links to the issue.

Engineer updates itself and will tell you the cost of the first rule: visual problems in the app are now yours to catch in the browser. Open **Agents → Engineer** and confirm both rules are in the instructions. They apply on every later run.

When the same mistake keeps coming back, write the correction into the instructions so you can stop repeating it in chat.

## Add a reviewer

Some problems Engineer will not see in its own work. Review goes to a new agent, with a fresh context, checking the code against the issue.

Ask Multica helper in chat:

> Create an agent named Reviewer. Use a different coding tool and model from Engineer if this computer has one (the official walkthrough uses Codex with GPT-5.6 Sol). Reviewer only reviews. It reads the pull request's real state, writes findings as issue comments with file and line, and never edits code.

Open **Agents → Reviewer** and read the instructions the helper wrote.

Review needs no new issue and no change of assignee. On `MUL-1`, in the comment box:

> @Reviewer Review the pull request against this issue. Write each finding as a comment, with the file and line. Do not change any code.

A hint under the box says Reviewer starts when you send. A few minutes later the review comment arrives: findings grouped by kind (code conventions, and whether the page matches the issue), each with a file location, plus what the reviewer checked itself (typecheck, lint, build).

Then, in the comment box:

> @Engineer Fix every finding in that review. Push the fixes to the same pull request.

The badge next to the title and the execution log both show the new run. When Engineer reports back, mention Reviewer again for a second pass.

One issue now holds two agents. Your short comments are the hand-offs.

## Merge

Merging is another comment:

> @Engineer Merge the pull request, delete the branch, and move this issue to Done.

Engineer merges and reports back. The issue status becomes **Done**, and a completion notification arrives in the Inbox. The path from the requirement to the merge sits on one timeline.

**Completed** on a run means that run finished. The issue can still take another comment, another requirement, or another agent. **Done** is the issue status, and you decide when it is earned.

## Form a squad

On `MUL-1` you were the coordinator. You mentioned Reviewer, then Engineer, then Reviewer again. A **squad** takes that job.

A squad is a named group of agents and people, led by one agent. Assign an issue to the squad and the leader reads it, delegates, and moves the status. When a member replies, the leader wakes up and chooses the next step. At the end it reports the result to you. Each member has a one-line role the leader reads when it delegates.

For ChatRAG:

- **Lead** (new): assigns work, moves status, and reports to you. It does the management, and leaves the building and the review to the others.
- **Engineer**: development.
- **Reviewer**: reviews every pull request.
- **You**: final sign-off.

Tell Multica helper:

> Create a squad named ChatRAG Team, and a leader agent for it.
> - Lead manages the squad. It assigns work, moves issue status, and reports to me. It does not write code or review it.
> - Engineer builds ChatRAG.
> - Reviewer reviews every pull request and does not edit code.
> - I sign off before anything merges.
> Squad instructions: development goes to Engineer. The work is ready for me only after the pull request passes review. Engineer merges only after I say so. Never read, print, or commit .env.local or any API key.
> Attach one skill to Lead and one skill to Engineer: a reporting style for Lead, and a way of building for Engineer.

The helper applies the configuration with the CLI. Open **Squads → ChatRAG Team** and check the leader, the members, and the role lines. You can also create a squad from a form on this page. Details: [Squads](https://multica.ai/docs/squads).

## Skills

The two rules you wrote into Engineer's instructions belong to Engineer alone. A **skill** is how you share a method across agents, or reuse one someone else already wrote.

A skill is a `SKILL.md` file plus optional supporting files. It tells the agent how to handle one kind of task. Multica uses the Agent Skills format, the same shape as the skills you wrote for Cursor. Attach a skill to an agent and Multica syncs it to the runtime when a run starts. The agent decides when to load it from the skill's description.

Open the **Skills** page. The two skills from the squad step should be there, with the agents they are attached to.

- The one on **Engineer** is a way of building. In the official walkthrough this is **tdd**: write a failing test first, then the change that makes that test pass.
- The one on **Lead** is a way of reporting. In the official walkthrough this is **i-have-adhd**: the first line is the next action, multi-step items are numbered, and progress stays visible. The leader's output is a report to you, so this skill decides what you read.

**New skill** offers four routes:

| Route | When to use it |
| --- | --- |
| Create manually | Write a `SKILL.md` from a blank page. |
| Import from local | A folder with `SKILL.md`, or a `.skill` / `.zip` file on this computer. |
| Import from URL | A skill published on GitHub, ClawHub, or Skills.sh. |
| Copy from a runtime | A skill already installed on a connected computer. |

A copy from a runtime is a snapshot. Later edits on your computer do not flow back; import again, or edit the skill in Multica. See [Skills](https://multica.ai/docs/skills).

Read a third-party skill before you import it. Multica does not review or sandbox skill files. The coding tool receives them as written.

Instructions and skills answer different questions:

| | Instructions | Skill |
| --- | --- | --- |
| Belongs to | One agent, on every run | Any agents you attach it to |
| Holds | That agent's job and its boundaries | Steps and material for one kind of work |
| Example | "Review only. Never edit code." | A review checklist and a report template |

## Hand the next issue to the squad

Give the squad a whole piece of work on the same app. The two example questions from `MUL-1` are generic. Replace them with three a teammate would actually ask about company documents, for example the VPN setup, the expense policy, and who owns the on-call rota. Keep the layout. Add one line to the README that matches the header. Leave the API routes and the RAGFlow calls alone, and leave `.env.local` alone.

Describe that to Lead in **Chat**, and create the issue with **Create with agent**, assigned to **ChatRAG Team**. A squad can be chosen anywhere an assignee can.

On the new issue, the description is already structured, and the badge shows the leader has taken it. Lead adds constraints of its own (the same questions in the empty state and the README, no API changes), then hands the work to Engineer. Engineer reports the pull request on the same timeline. Reviewer comments. Lead delivers: it mentions you, leads with the conclusion, then the pull request link, what changed, and what still needs your judgment. Nothing merges until you approve.

Sign off the same way as on `MUL-1`. Ask for `npm run dev` if you want to look in the browser. **Done** stays yours: reply to merge, or change the status yourself.

## Autopilot

Assigning, mentioning, and chatting all start because you did something. **Autopilot** is a fourth trigger. It starts work on a schedule, or from a webhook.

Tell Multica helper:

> Every Monday at 09:00, in this workspace's timezone, have Reviewer check the ChatRAG repository for dead code, repeated code, and structure that fights the project's conventions. Write the findings as comments on a new issue. Change no code. Never print .env.local or any API key.

Open the **Autopilot** page. Check the executor, the prompt, and the schedule (a cron expression plus a timezone).

Two run modes:

- **Create Issue** (the default). Each trigger opens an issue first, so the work lands on the board with the same history and comments as any other issue.
- **Run only**. The run executes and leaves a record on the autopilot's history. A run that finds nothing stays off the board.

A weekly check uses **Create Issue**. Click **Run now** to fire it once today. From then on, the same check opens a new issue every Monday.

The executor can be a squad, and a trigger can be a webhook. See [Autopilots](https://multica.ai/docs/autopilots).

## Other people

Under **Settings → Members**, invite teammates by email. They create issues, `@`-mention agents, and join squads the same way you do.

## What you are left doing

You described the requirement and signed off on the result. Agents built, reviewed, and reported. When a mistake came back, you wrote it into instructions or a skill, so the next run already knew.

When the issue list gets long, a **Project** groups related issues and tracks them as one unit. See [Projects](https://multica.ai/docs/projects).

The objects on one page: [Core concepts](https://multica.ai/docs/concepts).

## Exercises

### 1. Walk the first issue

Follow this tutorial through **Merge**, in a workspace of your own.

When `MUL-1` is **Done**, you should be able to point at all of these:

- your computer, online, under **Runtimes**
- Engineer's instructions, including the two rules you added after review
- the GitHub pull request, linked on the issue
- Reviewer's findings and Engineer's fix, on the same timeline

### 2. Let the squad run one change

Create the ChatRAG Team squad and hand it the example-questions issue from **Hand the next issue to the squad**.

Leave Engineer and Reviewer alone. Wait for Lead's report. Open the app or the pull request, then tell Lead to merge, or send the work back.

### 3. Run the Monday check today

Create the Autopilot above and click **Run now**.

Read the issue it opened. In one sentence, say whether you would hand the findings to Engineer, or leave them.
