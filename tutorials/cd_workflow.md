# CD Workflow

In the CI/CD tutorial, CI checked every PR. But after you merged, the new code just sat in `main`. 

**CD** (Continuous Deployment) closes the loop: when a PR is merged to `main`, a machine puts the new version on the server, automatically.

We'll deploy the **Regulatory Radar** app (`RegulatoryRadarDemo`) to a Windows server, and then walk through the whole flow, from a task to a running feature.

## The server

A **server** is just a computer that is always on, and that others can reach over the network. Ours is a small Windows Server machine in AWS (a **virtual machine**).

We will connect and run commands on the server using SSH.

```console
$ ssh -i server.pem Administrator@<SERVER_IP>

PS C:\Users\Administrator> hostname
EC2AMAZ-7JN1MA8
```

SSH uses a **key pair**. Two files that belong together:

- **Private key** (`server.pem`): like a password. Whoever has it can log in. **Never commit it.**
- **Public key**: saved on the server. It lets the server recognize the private key, but it can't be used to log in, so it's safe to share.

There's also `scp` command, to copy files to the server over the same SSH connection:


> [!TIP]
> `ssh` and `scp` come with Windows, macOS and Linux. Nothing to install.

## The CD pipeline

Our server is **clean**: no Python, no app. The pipeline has to install everything it needs, and then deploy the code.

GitHub's machine needs two things to reach the server: its address, and the private key. You don't put them in the workflow file, since everyone can read it. GitHub keeps them for you:

In the repo's **Settings > Secrets and variables > Actions**:

| Tab | Name | Value |
| --- | --- | --- |
| **Secrets** | `SERVER_SSH_KEY` | The whole content of the private key file, including the `-----BEGIN` and `-----END` lines |
| **Variables** | `SERVER_HOST` | The server's IP address |


Now create a branch `ci/cd`, and in **Agent** mode, ask:

> Create a CD pipeline that deploys this app to a clean Windows Server on every push to `main`:
>
> - `scripts/deploy.ps1` runs on the server. It installs Python if it's missing, stops the app, puts the new code in `C:\app`, installs `requirements.txt` in a venv, opens port 80 in the firewall, and runs the app as a scheduled task named `RegulatoryRadar` (uvicorn on port 80, starts at boot). It fails if any step fails, and it's safe to run again.
> - `.github/workflows/cd.yml` runs on push to `main`, and manually. It copies the code and the script to the server with `scp`, runs the script with `ssh`, then checks that `http://<server>/health` answers. Use the secret `SERVER_SSH_KEY` and the variable `SERVER_HOST`. Log in as `Administrator`. The server's SSH shell is PowerShell.


> [!NOTE]
> Is it safe to deploy every merge? Yes, because `main` is protected (the `protect-main` ruleset from the CI/CD tutorial): code reaches `main` only through a PR, with green tests.


## The full workflow

Now let's put everything from the course together. We'll take one small task all the way to production:

```text
task → branch → implement → test locally → push → PR → agent review → CI → approve and merge → CD → live
```

**Before:** open `http://<SERVER_IP>/stats`. It's a 404, since the endpoint doesn't exist yet.

**1. Your task.**
:

> The RA team wants a quick overview of the data in Regulatory Radar.
> Add `GET /stats` that returns how many products and regulatory updates there are, for example `{"products": 6, "updates": 8}`. Add a test.

**2. Create a branch.**

```bash
git checkout main
git pull
git checkout -b feat/stats
```

**3. Implement.** In **Agent** mode



**4. Run the tests locally.** Don't wait for CI to find out:

```bash
python -m pytest -q
```

Or ask the `test-runner` subagent to run them.

**5. Commit and push.**

```bash
git add .
git commit -m "Add GET /stats endpoint"
git push -u origin feat/stats
```

**6. Open a PR.** On GitHub, click **Compare & pull request**, or ask the agent to open it with the GitHub MCP.

**7. Review with an agent.** Open a new chat with a **different model**:

> Review the changes on this branch compared to `main`. If you find something worth fixing, fix it, commit, and push.

**8. CI.** Every push to the PR runs `tests` and `security` again. Wait for green. If it's red, ask the agent why (*"Why did the CI fail on my PR?"*), and check **what** it changes.

**9. Approve and merge.** Read the **Files changed** tab yourself. The agent reviewed it, but you're responsible for what goes to production. In a team, a teammate clicks **Review changes > Approve** (you can't approve your own PR). Then **Merge pull request**, and delete the branch.

**10. CD.** Open the **Actions** tab. A **CD** run started by itself, for the merge commit. Open the `deploy` job and watch each step.

**After:** open `http://<SERVER_IP>/stats` again. The new feature is live, minutes after the merge, and nobody logged in to the server.



