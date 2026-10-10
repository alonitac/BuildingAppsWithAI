# CI/CD in Brief

In the previous tutorial, you and a second model reviewed a pull request. But did anyone run the tests? People forget. And agents sometimes say "all tests pass" without running them.

So let a machine do it:

- **CI** (Continuous Integration): on every PR, a machine runs the tests and scans automatically.
- **CD** (Continuous Deployment): when a PR is merged to `main`, a machine deploys the app automatically.

We'll use **GitHub Actions**, which is built into GitHub, on the **Regulatory Radar** app (`RegulatoryRadarDemo`).

## GitHub Actions

A **workflow** is a YAML file in the `.github/workflows/` folder **in your repository**. GitHub runs it when something happens, like a push or a new PR.

| Word | Meaning |
| --- | --- |
| **Trigger** (`on`) | When to run: on push, on a PR, manually... |
| **Job** | A list of steps that runs on one machine. Jobs run in parallel, unless one `needs` another. |
| **Runner** (`runs-on`) | The machine. GitHub gives you a fresh machine for every job: `ubuntu-latest`, `windows-latest`... |
| **Step** | One thing to do. Either `run:` (a command) or `uses:` (a ready-made action someone published). |

Here's a first workflow. Create `.github/workflows/hello.yml`:

```yaml
name: Hello

on:
  push:                 # run on every push
    branch:
      - main
  workflow_dispatch:    # also allow running it manually from the Actions tab

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5     # get the repo's code onto the machine
      - name: Say hello
        run: |
          echo "Hello from GitHub Actions"
          echo "Commit ${{ github.sha }} pushed by ${{ github.actor }}"
          ls
```

- In YAML, **indentation matters**. Use spaces, never tabs.
- `-` starts a list item, and `|` means the next lines are a multi-line command.
- GitHub fills in `${{ ... }}` before running the step. `github.sha` is the commit's hash, `github.actor` is who pushed.

Commit and push. On GitHub, open the **Actions** tab, click the run, then the `hello` job, and open each step to see its output.

> [!TIP]
> Agents are good at writing workflows. Still, read every line before you commit. A workflow runs code on every push, and it can access your secrets.


# Exercises

Delete `hello.yml` before you start.

### :pencil2: Run the tests on every pull request

1. Create a Git branch called `ci/tests`.
2. In **Agent** mode, ask:

> Create a GitHub Actions workflow `.github/workflows/ci.yml` that runs the tests on (only!) every pull request to `main`. Name the job `tests`.

Read the file before you commit. Check that:

- It runs on `pull_request`, not on every push.
- The steps are the same ones you did on your computer in the first tutorial: get the code, set up Python, install `requirements.txt`, run `python -m pytest`.

Don't understand a line? Ask the agent to explain it.

3. Commit and push the branch. Then open a PR. The workflow starts right away, and you'll see its result at the bottom of the PR. Merge it when it's green.

### :pencil2: Protect `main`

Right now CI only *reports*. You can still merge a red PR - this means you merge into `main` code that does not pass tests.

Also, if you think about it, anyone (a human or an agent) can push straight to `main`, without a PR and without CI.

Try it. On `main`, change something in `README.md`, commit, and `git push`. It works. Nobody reviewed it, and no test ran.

Let's block it. In the repo's **Settings > Rules > Rulesets**, click **New ruleset > New branch ruleset**:

- **Ruleset name**: `protect-main`.
- **Enforcement status**: **Active**.
- **Target branches**: **Add target > Include default branch**.
- Enable **Require a pull request before merging**.
- Enable **Require status checks to pass**, click **Add checks**, and choose `tests`.
- Click **Create**.

**Test 1: push to `main`.** Change something else on `main`, commit, and `git push`. GitHub rejects it:

```text
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Changes must be made through a pull request.
```

Now your commit is stuck on your local `main`. You can reset your local `main` branch back to GitHub's version (be careful it's irreversible):

```bash
git reset --hard origin/main
```

**Test 2: a red PR.** 

A teammate wants to watch one more device type for `pulse-dr`, and makes a typo. Create a branch `feat/pulse-dr-codes`, and in `data/portfolio.yaml` add a code to the end of the `pulse-dr` list:

```yaml
    product_codes:
      - DTBB # typo!
```

Make sure your agent indeed made the mistake for you and didn't fix it. We want to introduce this bug intentionally!

Commit, push the branch, and open a PR on GitHub. CI fails, and you can't merge.

Click **Details** next to the failed check, and find which test failed and on which line. Why did it fail? Is the code wrong, or the test?

Here, the test is right: FDA product codes are always 3 uppercase letters, and the test checks exactly that. Don't "fix" the test to make it pass. Ask the agent to fix it, push, and watch the check turn green. Now you can merge.

> [!TIP]
> When CI fails, it's tempting to ask the agent to "make the tests pass". Agents sometimes do it by changing the test. Always check **what** it changed.

### :pencil2: Security: scan the Python packages

The app uses packages other people wrote (`requirements.txt`). When someone finds a security problem in a package, it's published in a public database with an ID (this database is called **CVE**).

[`pip-audit`](https://github.com/pypa/pip-audit) checks your packages against that database. On a new branch, ask the agent:

> Add a job named `security` to `ci.yml` that scans `requirements.txt` for known vulnerabilities with pip-audit.

Check that `security` is a separate job next to `tests`, not a step inside it. Open a PR. Both jobs run at the same time.

Now let's say a teammate adds an old version of a package. Add this line to `requirements.txt`:

```text
flask==0.5
```

Push. The `security` job fails. Read its output: what did it find, and which version fixes it? Fix `requirements.txt` and push again.

Add the `security` check to your `protect-main` ruleset too.

> [!TIP]
> GitHub can also watch your packages for you. In **Settings > Advanced Security** (or **Code security**), turn on **Dependabot alerts** and **Dependabot security updates**. When a new problem is found in one of your packages, Dependabot opens a PR that upgrades it.

### :pencil2: Visualize the test results

The test output is long and hard to read. Let's turn it into a report.

`pytest` can save its results to a file in a standard format (**JUnit XML**). The [`dorny/test-reporter`](https://github.com/dorny/test-reporter) action turns that file into a nice report on GitHub. Ask the agent:

> In the `tests` job of `ci.yml`, save the pytest results as JUnit XML and publish them as a report with dorny/test-reporter. The report should be published even when tests fail.

Open a PR. You should see a new check with the report. Open it: a table of every test, whether it passed, and how long it took. Break a test on purpose and see how a failure looks.

**Bonus: coverage.** In a previous tutorial, you asked the agent for 100% test coverage. Ask the agent to show the coverage on every run:

> Measure test coverage with pytest-cov in the `tests` job, and write a markdown coverage table to the job summary


