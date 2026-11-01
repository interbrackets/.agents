---
name: rebase-and-pr
description: Commit the current work, bring the branch up to date with main by fetching and rebasing, resolve conflicts, push, and open a pull request with reviewer instructions. Use whenever the user asks to commit and push, "pull main and rebase", "sync my branch with main", "fix the conflicts", "open a PR", "create a pull request", or any mix of these ("commit, rebase, push and open a PR"), even when they only name one step. Also use when a branch has fallen behind main and the user wants it caught up before review.
---

# Rebase and PR

Take a working branch from "changes on disk" to "pull request open on top of current main". The steps are simple; the value is in checking state before each one, so a rebase never silently throws work away and a push never rewrites history someone else may have.

## 1. Look before touching anything

Run these first and read the output:

```bash
git status --short
git branch -vv
git fetch origin
git rev-list --left-right --count HEAD...origin/<base>     # ahead  behind
git log --oneline HEAD..origin/<base>                       # what is incoming
git diff --stat HEAD...origin/<base>                        # which files it touches
```

`<base>` is `main` unless the repo says otherwise (`git symbolic-ref refs/remotes/origin/HEAD`). If you are on the base branch itself, create a branch before committing; never commit or push work straight to base.

Compare the incoming files against your own changes. Overlap is where conflicts will come from, and the incoming commit messages often tell you why (for example, the change you are about to commit may already have landed upstream).

## 2. Commit deliberately

Stage files by name, not `git add -A`. Working trees collect things that are not the user's work, and a commit is hard to undo once pushed:

- **Intended changes:** commit them.
- **Tool-rewritten files** (a build step that reformats a manifest, editor noise, line-ending churn): restore them with `git checkout -- <file>` instead of committing.
- **Generated files that should be tracked** (a lockfile that was never committed): commit them as their own commit, so the reason is visible and they can be dropped or regenerated independently.
- **Secrets and local files** (`.env*`, tokens): never stage them. If they appear untracked, say so.

Match the repo's commit style (read `git log --oneline -10`) and follow any attribution trailer the session or `CLAUDE.md` specifies. Write the message from a heredoc so multi-line bodies survive the shell. Explain why in the body, not only what.

## 3. Rebase onto the base branch

```bash
git rebase origin/<base>
```

Rebase instead of merging, so the PR reads as your commits on top of current main.

When it stops on a conflict, read the hunk (`git diff --diff-filter=U`) and decide which of three situations it is:

1. **Upstream already contains your change.** Both sides edit the same line to the same result, or upstream has a fuller version of what you wrote. Keep upstream's version. If your commit is then empty, `git rebase --skip` it. This is safe because nothing is lost, but say so in the final report, since the user's commit disappears from the branch.
2. **Upstream moved or renamed the file.** Git usually follows the rename and reports the conflict at the new path. Resolve there; do not recreate the old path.
3. **Both sides changed the same thing differently.** This is a real conflict between two intents. Stop and ask the user, showing both versions, rather than choosing. Picking a side silently can reverse someone's work.

Never `git rebase --abort` away progress without telling the user, and never resolve by deleting a hunk you do not understand.

After the rebase finishes, check what the incoming commits did to files you generate:

- A lockfile or manifest-derived file you committed may now be stale (upstream added a dependency). Refresh it with the tool's command that keeps existing pins (for Cargo, `cargo metadata`; for pnpm, `pnpm install --frozen-lockfile` to check, `pnpm install` to update), not one that re-resolves everything to latest. Commit the refresh separately.
- Re-run the project's quick checks (lint, type check or build) if the incoming changes touch code your commits depend on, or say plainly that you did not. If you verified something earlier in the session on pre-rebase code, that result no longer covers the new base.

## 4. Push without rewriting shared history

Check whether the push is a fast-forward:

```bash
git merge-base --is-ancestor origin/<branch> HEAD && echo fast-forward
```

If it is, `git push origin <branch>` is fine. If the remote branch already has commits your rebase rewrote, the push would need `--force-with-lease`. That replaces history others may have pulled, so ask the user first and say which commits will be replaced. Never use plain `--force`, and never force-push the base branch.

## 5. Open the pull request

Check for an existing PR first (`gh pr list --head <branch> --state all`) and update it instead of opening a duplicate.

Write the body to a file and pass it with `--body-file`; long bodies pass through shell quoting badly. Write it for the reviewer, not for the author, and include a section of **instructions for the reviewer**: the exact commands to run and what they should see, plus what "before" looked like when the PR fixes a visible defect. A reviewer who cannot reproduce the check cannot approve it. Suggested shape:

```markdown
## Summary
- what changed and why, one bullet per commit-sized idea

## Instructions for the reviewer
1. numbered, copy-pasteable steps
   - **Expect:** the observable result
   - **Before this PR:** what was wrong

## What I verified
| Check | Result |   <- only things actually run, with honest failures

## Not covered
- checks not run and why

## Follow-ups
- things deliberately left out

<PR attribution line from the session or CLAUDE.md>
```

Create it with `gh pr create --repo <owner/repo> --base <base> --head <branch> --title "<title>" --body-file <file>`. Titles follow the repo's commit style.

**If `gh` is missing or unauthenticated:** on Windows it is often installed but absent from the bash PATH, so check PowerShell first, refreshing PATH from the Machine and User environment variables. If it truly is not there, do not call the GitHub API with credentials scraped from git's credential store: the user granted git access, not API access. Instead leave the body file on disk, give the compare link (`https://github.com/<owner>/<repo>/compare/<base>...<branch>?expand=1`) and say how to install and log in (`winget install GitHub.cli`, `gh auth login`). Offer to retry once they have.

## 6. Report

End with what the user needs in order to walk away:

- the branch state (commits ahead of base, pushed or not) and the PR URL
- anything dropped or changed in the rebase, and why (skipped commits, regenerated files, files restored instead of committed)
- what was not re-verified after the rebase
- anything left unfinished or needing their decision

Leave out narration of steps that went as expected.
