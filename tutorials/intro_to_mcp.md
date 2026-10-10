# Intro to MCP

In the CI/CD tutorial, when a check failed, you opened GitHub, clicked **Details**, scrolled through the log, found the error, and copied it back to the agent. Can't the agent just look at GitHub itself?

We'll keep working on the **Regulatory Radar** app (`RegulatoryRadarDemo`).

## How does an agent talk to an external API?

GitHub has a regular API, like the one you built in the first tutorial. Try it: list the pull requests of the course's repo:

```bash
curl "https://api.github.com/repos/alonitac/RegulatoryRadarDemo/pulls?state=all"
```

```json
[
  {
    "url": "https://api.github.com/repos/alonitac/RegulatoryRadarDemo/pulls/1",
    "id": 4744274830,
    "node_id": "PR_kwDOUzvepM8AAAABGsfjjg",
    "html_url": "https://github.com/alonitac/RegulatoryRadarDemo/pull/1",
    "number": 1,
    "state": "closed",
    "title": "fix",
    "user": {
      "login": "alonitac",
      ...
```

It works because we know the exact endpoint. 

How will the coding agent behave? the agent has to work like a developer who has never seen the API:

1. Search the web for the API docs, and read them.
2. Figure out the right endpoint, parameters and authentication.
3. Write a `curl` command, and run it.
4. Get back a huge JSON response, and dig through it.
5. Got something wrong? Back to step 1.

It works, sometimes. But it's slow, it fills the context window with docs and JSON, and the agent guesses a lot. Plus, where does it get your API key from?

## MCP: an API for agents

Regular APIs are made for **developers**: a person reads the docs once, and writes the exact request into the code. An agent has to figure it all out from scratch, every time.

**MCP** (Model Context Protocol) is a standard way for a system to offer an **API for agents**. The company behind the system (GitHub, Slack, Notion...) writes an **MCP server** that offers a short **menu of actions**. Each action says, in plain words, what it does, when to use it, and what it needs. The answers are short, and made for an agent to read.

You connect the server to Cursor once. From then on, the agent just picks an action from the menu.

The same server works in Cursor, Claude Code, ChatGPT and others, because MCP is an open standard.

### What to watch out for

- **Context cost.** Every action's description (a **tool**, in MCP terms) is sent with **every** message, even when the agent doesn't use it. Connect only the servers you need, and turn off the tools you don't need.
- **Permissions.** The server acts **as you**, with your API key. If the agent can merge PRs through it, a bad prompt can too. Give the key only the permissions you need.
- **Trust.** Like skills, only connect servers from sources you trust.


# Exercises

### :pencil2: Connect the GitHub MCP server

**Step I: create a token.** The MCP server works **as you**, so it needs a key to GitHub: a **personal access token** (PAT). We'll create one that can only touch `RegulatoryRadarDemo`, and only Actions and pull requests.

1. On GitHub, click your profile picture (top right) > **Settings**.
2. At the bottom of the left menu, click **Developer settings** > **Personal access tokens** > **Fine-grained tokens**.
3. Click **Generate new token**.
4. **Token name**: `cursor-mcp`. **Expiration**: 30 days (it's a course, no need for a token that lives forever).
5. **Repository access**: choose **Only select repositories**, and pick your `RegulatoryRadarDemo`.
6. **Permissions**: add these two, under the repository permissions:
    - **Actions**: **Read-only**. Lets the agent read CI runs and their logs.
    - **Pull requests**: **Read and write**. Lets the agent list, read, and open PRs.
7. Click **Generate token**, and copy it. You won't see it again.

> [!NOTE]
> GitHub also adds **Metadata: Read-only** by itself. Every token needs it.

**Step II: add the server in Cursor.**

1. Open **Cursor Settings**, go to the **Customize** section, then to **MCP**.
2. Click the button to add a new MCP server. Cursor opens your global `mcp.json` file (in your home folder, `~/.cursor/mcp.json`).
3. Paste this, and replace `YOUR_TOKEN` with your token:

    ```json
    {
      "mcpServers": {
        "github": {
          "url": "https://api.githubcopilot.com/mcp/",
          "headers": {
            "Authorization": "Bearer YOUR_TOKEN",
            "X-MCP-Toolsets": "context,pull_requests,actions"
          }
        }
      }
    }
    ```

4. Save the file.

What's in there:

- `url`: where GitHub's MCP server lives. It's a **remote** server, nothing to install.
- `Authorization`: your token. This is how the server knows who you are.
- `X-MCP-Toolsets`: which groups of tools to load. GitHub's server has dozens of groups (issues, discussions, projects...). We load only what we need, to keep the context small.

> [!WARNING]
> It's much better to put the token in the **global** `mcp.json`, not in the local `.cursor/mcp.json` inside the project. 


**Step III: enable and test it.**

1. Back in **Customize > MCP**, find `github` and make sure its toggle is **on**.
2. Wait for the green dot. Click the server to see its tools: `list_pull_requests`, `get_job_logs`... You can turn single tools off.
3. Open a new chat in **Agent** mode and ask:

    > List the last 3 pull requests in my repo

4. Before calling an MCP tool, the agent asks for your approval. Read which tool it wants to call and with which parameters, and approve.

You should see the PRs you opened in the previous tutorials.


You can know ask many useful quesitons, e.g.: 

> Why did the CI fail on my last PR?


> The security check failed on my PR. Investigate: what vulnerabilities were found, how serious are they, does our app actually use the vulnerable code, and what's the smallest fix?

> Do i have any warnings in the CI logs? 