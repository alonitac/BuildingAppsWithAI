# SDLC with Git

A coding agent can change 20 files in a minute. If something breaks, you want to know what changed, and you want a way back.

That's what **git** gives you. It also lets a team work on the same project without stepping on each other. Together with **GitHub**, it's how a change goes from an idea to a reviewed and released version. This process is called the **SDLC** (Software Development Life Cycle).

We'll keep working on the **Regulatory Radar** app (`RegulatoryRadarDemo`).

You've actually used git already: `git clone` got you the app, and **Discard All Changes** threw away the agent's work.

## Every commit is a snapshot

A **commit** is a snapshot of the whole project at a point in time. It also saves who made it, when, a message, and a unique ID (a **hash**, like `a1b2c3d`).

Your project history is a chain of these snapshots. You can go back to any of them, or compare two of them.

![][git_versions]

Git doesn't copy files that didn't change, it just links to the previous copy (the dashed files above). So commits are cheap. Commit often.

Everything is stored in a hidden `.git` folder in the project. That folder **is** the repository.

> [!TIP]
> On your first commit, git may ask who you are. Set it once:
>
> ```bash
> git config --global user.name "Your Name"
> git config --global user.email "you@example.com"
> ```

## The three areas

![][git_areas]

- **Working tree**: the files you (and the agent) edit.
- **Staging area**: the changes you picked for the next commit.
- **Repository** (`.git`): the saved commits.

The flow is always: edit → **stage** (`git add`) → **commit** (`git commit`).

Why stage? Because you don't always want to commit everything. Say the agent fixed a bug *and* reformatted three other files. You can stage only the fix.

### File status

| Status | Meaning | In Cursor |
| --- | --- | --- |
| **Untracked** | A new file git doesn't know yet. | `U` |
| **Modified** | Changed since the last commit, not staged yet. | `M` |
| **Staged** | Will go into the next commit. | under **Staged Changes** (`A` for a new file) |
| **Unmodified** | Same as in the last commit. | not shown |
| **Deleted** | Removed. | `D` |

### Let's try it

Open a terminal in `RegulatoryRadarDemo`:

```console
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

Now change the first line of `README.md` to `# Regulatory Radar - Acme MedTech`, and create a new file `CHANGELOG.md`:

```markdown
# Changelog

## v1.0.0
- First version of Regulatory Radar.
```

```console
$ git status
On branch main
Changes not staged for commit:
        modified:   README.md

Untracked files:
        CHANGELOG.md
```

> [!TIP]
> **In Cursor:** open the **Source Control** tab (`Ctrl+Shift+G`). The **Changes** list shows the same files, with their status letter.

`git diff` shows what changed, line by line:

```console
$ git diff
-# Regulatory Radar
+# Regulatory Radar - Acme MedTech
```

> [!TIP]
> **In Cursor:** click a file in the **Changes** list to see its diff side by side.

Stage both files:

```console
$ git add README.md CHANGELOG.md
$ git status
On branch main
Changes to be committed:
        new file:   CHANGELOG.md
        modified:   README.md
```

> [!TIP]
> **In Cursor:** hover a file and click **+** to stage it. The file moves to **Staged Changes**.

> [!NOTE]
> `git add` stages the file **as it is right now**. If you edit it again, you need to `git add` it again.

Commit:

```console
$ git commit -m "Add changelog and company name in README"
[main 4e1f2a9] Add changelog and company name in README
 2 files changed, 5 insertions(+), 1 deletion(-)
 create mode 100644 CHANGELOG.md
```

> [!TIP]
> **In Cursor:** write the message in the box at the top of the Source Control tab and click **Commit**. The sparkle icon writes the message for you.
>
> A good commit message says **why**. "Fix date filter returning June updates" is much better than "fix".

To undo changes you **haven't committed yet**:

| Command | What it does |
| --- | --- |
| `git restore <file>` | Throw away the unstaged changes in the file. **There's no way back.** |
| `git restore --staged <file>` | Unstage. Your changes stay in the file. |
| `git restore .` | Throw away **all** unstaged changes. |

So to fully undo a staged change, first unstage it, then restore it.

> [!TIP]
> **In Cursor:** hover a file and click **−** to unstage it, or the curved arrow to discard its changes.

## .gitignore

Some files should never be committed: secrets (`.env`), the virtual environment (`.venv/`, it's huge and anyone can recreate it), and cache files.

List them in a `.gitignore` file, and git ignores them. Here's the one in `RegulatoryRadarDemo`:

```text
# Secrets and local settings
.env

# Virtual environments
.venv/
venv/

# Python build and cache files
__pycache__/
*.pyc
.pytest_cache/
```

Ignored files don't show up in `git status`, and Cursor shows them greyed out. To check why a file is ignored:

```console
$ git check-ignore -v .env
.gitignore:2:.env       .env
```

`.gitignore` itself **is** committed, so the whole team ignores the same files.

> [!WARNING]
> `.gitignore` doesn't affect files that are already committed. You'll fix that in the exercises.

## Branches

A **branch** is a separate line of work. You commit on it as much as you want, and `main` doesn't change until you merge.

Usually you open a branch for each feature or fix, like `feat/version-endpoint` or `fix/updates-since-filter`. Branches are also great for agent experiments: don't like the result? Delete the branch.

```bash
git branch                           # list branches (* is the current one)
git checkout -b feat/version-endpoint  # create a branch and switch to it
git checkout main                      # switch back to main
```

When you switch branches, git changes your files to match that branch. So commit (or discard) your changes before you switch.

> [!TIP]
> **In Cursor:** the current branch is shown at the bottom-left corner. Click it to switch, or to create a new branch.


## Tags

A **tag** is a name for one commit, usually a release, like `v1.0.0`. Unlike a branch, a tag never moves.

Versions usually look like `MAJOR.MINOR.PATCH` (this is called **semantic versioning**):

- **PATCH** (`v1.0.1`): a bug fix.
- **MINOR** (`v1.1.0`): a new feature, nothing breaks.
- **MAJOR** (`v2.0.0`): something breaks, for example an endpoint was removed.

Tag your current commit as the first release:

```bash
git tag -a v1.0.0 -m "First release of Regulatory Radar"
git tag            # list tags
git show v1.0.0    # see the tag and its commit
```

`-a` saves who created the tag, when, and a message. Use it for releases.

## GitHub

So far everything was only on your computer. **GitHub** keeps a copy of the repository (a **remote**) that the team shares. When you cloned, git named it `origin`.

Your computer and GitHub don't sync by themselves. Your commits stay on your computer until you push them.

### push and pull

```bash
git push                 # send your commits to GitHub
git pull                 # get new commits from GitHub
git push origin v1.0.0   # tags are not pushed with git push, push them like this
```

The first push of a new branch is a bit different, since GitHub doesn't have it yet:

```bash
git push -u origin feat/version-endpoint
```

After that, `git push` and `git pull` just work on this branch.

> [!TIP]
> **In Cursor:** the button at the top of the Source Control tab says **Publish Branch** for a new branch, and **Sync Changes** (pull + push) for an existing one.

> [!TIP]
> Pull before you start working, so you start from the team's latest code.

### Pull requests

In a team, you don't push straight to `main`. You push your branch and open a **pull request** (PR): *"please review my branch and merge it into `main`"*.

In a PR:

- **Review**: teammates read your changes in the **Files changed** tab and comment on specific lines.
- **Checks**: tests and scans run automatically (next tutorial: CI/CD).
- **Merge**: when it's approved and the checks pass, click **Merge pull request**. Now your commits are in `main`.

The full flow:

```text
pull main
  → create a branch
    → commit (many times)
      → push the branch
        → open a PR → review + checks → fix → push again
          → merge into main
            → tag a release
```

# Exercises


### :pencil2: Your first pull request

Now let's build a feature, the right way:

1. Create a branch `feat/version-endpoint`.
2. In **Agent** mode: *"Add a `GET /version` endpoint that returns `{"version": "1.1.0"}`, with a test."*
4. Commit the changes and push the branch.
5. On GitHub, click **Compare & pull request**. Write a title and a short description (or ask the agent to write it).
6. **Review.** Open a new chat with a **different model** than the one that wrote the code, and ask:

> Review the changes on this branch compared to `main`. If you finds something worth fixing, fix it, commit, and push.

7. Watch the PR update.
8. Merge the PR on GitHub, and delete the branch (GitHub shows a button for it).
9. Back in Cursor, update your `main`

    ```bash
    git checkout main
    git pull
    ```

10. Let's say you want to tag this version as a stable release:

    ```bash
    git tag -a v1.1.0 -m "Add /version endpoint"
    git push origin v1.1.0
    ```


### :pencil2: (Optional) Back to an old version: detached HEAD

Let's create another commit just to be able to demonstrate the scenario in this exercise: 

```bash
# Write a new file named 'file1' with 'blabla' in it
echo 'blabla' > file1

# Add and commit
git add file1
git commit -m "dummy file"
```

Some of your users reports a problem in `v1.1.0`, the version they use. Let's look at the code of that version:

```bash
git checkout v1.1.0
```

Notice that `file1` isn't there. You're really looking at the old code.

Now change something in `README.md` and commit. Then go back:

```bash
git checkout main
```

Read git's warning. What happened? Your commit was lost.

So detached HEAD is fine for **looking around**, not for working. To work on an old version, create a branch from it:

```bash
# First checkout v1.1.0
git checout v1.1.0

# And from that branch, create a new branch
git checkout -b fix/v1.1.0
```

Now you're on a real branch. You can work as usual. 

[git_versions]: https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/img/git_versions.png
[git_areas]: https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/img/git_areas.png
