---
name: pr-review
description: 'Deep-read a GitHub pull request to rebuild working context and review it. Reads the PR description and the full diff, reconstructs what was done and why (typically work pushed from another machine), shows where the work stopped, and runs a full code review with findings. Use when the user runs /pr-review with a PR number, #id, owner/repo#id or PR URL, or asks to "review PR 12", "catch me up on this PR", "what did I do on the other machine", "load context from the PR", "analyze the changes in <PR link>". Read-only. Never fetches, checks out, comments, approves or merges.'
argument-hint: '<PR number | #id | owner/repo#id | PR URL>'
---

# PR Review

Rebuild a pull request's context on a machine that did not write it, then review it the way a fresh reviewer would. The author is usually the user, working on another machine. So the first job is a handoff: what was done, why, and where it stopped. The second is an honest review: what is wrong or risky in the diff. Both come from two sources only: the PR description and the full diff.

## Ground rules

- **Read-only.** Do not `git fetch`, `git checkout`, `gh pr checkout`, stash, or edit files. Do not comment, review, approve, label or merge on GitHub. Read the PR through `gh`. Touch the local clone only with read-only commands (`git status`, `git rev-parse`, `git cat-file`, `git remote`). If the user wants to continue the work here, give them the command and do not run it.
- **Two sources.** Read the PR description and the diff. Do not pull conversation comments, review threads, commit history, CI results or linked issues unless the user asks for them. You may read whole files at the PR head to understand a hunk (step 3). That still counts as reading the diff, not a new source.
- **Evidence over memory.** Every statement in the report must point to the description or to a `path:line` in the diff. If the two sources cannot answer something, write "unknown from the PR" instead of guessing.

## 1. Resolve the argument

| Input | Call |
|---|---|
| `12` or `#12` | `gh pr view 12` (repo comes from the current clone) |
| `owner/repo#12` | `gh pr view 12 --repo owner/repo` |
| `https://github.com/owner/repo/pull/12` | `gh pr view <url>` (trim anything after the number, such as `/files` or `#discussion…`) |
| nothing | `gh pr view` (the PR for the current branch). Say so. If there is none, ask for the PR. |

If you get a bare number and the shell is not inside a git clone, ask which repo.

Fetch the metadata once and reuse it:

```bash
gh pr view <ref> --json number,title,url,state,isDraft,author,baseRefName,baseRefOid,headRefName,headRefOid,additions,deletions,changedFiles,body
```

Take `<owner>/<repo>` from `url`. Pass `--repo <owner>/<repo>` and the PR number on every later call, so every call hits the same PR no matter where the shell is.

**When `gh` fails:**

- `Could not resolve to a Repository` or a 404 usually means the active `gh` account cannot see the repo. It rarely means the PR is missing. Run `gh auth status`. If another account is logged in, tell the user and offer `gh auth switch --user <login>`. Do not switch silently, because that changes their global `gh` state.
- If `gh` is missing or not authenticated, stop and tell the user how to fix it (`winget install GitHub.cli`, `gh auth login`). If a GitHub MCP server with pull-request read tools is available, you can use it for the same data. Never call the API with tokens scraped from git's credential store.

## 2. Read the description as the author's claims

Parse the body before you look at code. Pull out the summary or intent, any **Instructions for the reviewer**, **What I verified**, **Not covered** and **Follow-ups** sections (the `rebase-and-pr` skill writes these), checkboxes, and TODOs. Treat each item as a claim to check against the diff in step 4, not as a fact. An empty body is a Low finding in its own right, because the diff then has to tell the whole story.

## 3. Read the full diff

Map it first:

```bash
gh pr diff <n> --repo <owner>/<repo> --name-only
gh api "repos/<owner>/<repo>/pulls/<n>/files" --paginate --jq '.[] | {filename, status, additions, deletions, previous_filename}'
```

Classify every file as source, tests, config/infra, docs/specs, or generated (lockfiles, build output, snapshots, minified or vendored code). Skim generated files for surprises, such as an unexpected new package or a major version jump, but do not review them line by line.

Then read the diff with `gh pr diff <n> --repo <owner>/<repo>`:

- If the diff is too large to read in one pass, save it to a temp file outside the repo and read it in ranges. Delete the file when you are done.
  - PowerShell: `gh pr diff <n> --repo <owner>/<repo> | Set-Content -Encoding utf8 "$env:TEMP\pr-<n>.diff"`
  - bash: `gh pr diff <n> --repo <owner>/<repo> > "${TMPDIR:-/tmp}/pr-<n>.diff"`
- GitHub refuses diffs over 20,000 lines with HTTP 406. In that case, use per-file patches from `pulls/<n>/files` (`--jq '.[] | select(.filename=="<path>") | .patch'`). That endpoint leaves out `patch` for very large files. Read those files at both refs instead (see below). If one is still unreadable, list it under **Not reviewed**.

A hunk carries only a few lines of context, which is rarely enough to judge it. When a hunk depends on code outside it (the function it sits in, a type it uses, a caller), read the whole file at the PR head. Do not use the local clone for this, because it may be on another commit.

```bash
gh api "repos/<owner>/<repo>/contents/<path>?ref=<headRefOid>" -H "Accept: application/vnd.github.raw"
```

To get the version before the change, use `<baseRefOid>`. In PowerShell, quote the URL and write `${path}?ref=`, not `$path?ref=`, because `?` is a legal variable-name character there. To find callers of a changed export in files the PR does not touch, search the local clone if it is the same repo, and note that the result reflects the local HEAD, not the PR head.

Read every non-generated file. Do not sample. If size forces you to skip a file, name it in the report.

## 4. Analyze

Work in this order. The handoff depends on understanding the changes, and the review depends on the handoff.

**Reconstruct the work.** Group changes by concern, not by file. For example, "added the X hook and wired it into Y and Z" or "tightened the CSP and documented why". Identify the entry points and data flow, and list the public surface that changed: exports, routes, config keys, schemas, environment variables and dependencies.

**Compare the description with the diff.** For each claim in the description, find it in the diff and mark it as matched, partial or missing. For each significant change in the diff, check whether the description mentions it. Unmentioned changes (drive-by edits, leftover debug code, reformatting of unrelated files) are where handoff surprises hide.

**Find where the work stopped.** These signals mean the work is unfinished:

- the PR is a draft
- unchecked boxes in the body, or in task or spec files inside the diff
- `TODO`, `FIXME` or `XXX` on added lines
- stubs, such as empty handlers or a `not implemented` throw
- commented-out code
- tests marked `.skip` or `.only`
- items in the **Not covered** and **Follow-ups** sections

**Review the code.** Read it as a reviewer who is seeing it for the first time:

- **Correctness.** Logic errors, wrong conditions, off-by-one errors, unhandled null, undefined or error paths, race conditions, and broken async such as a missing `await` or an unhandled promise.
- **Contracts.** Signatures, exports or config that changed without updating their callers, and removed things that are still referenced.
- **Security.** Input that reaches a query, HTML, URL, shell or `eval`. Secrets in code or in public environment variables. Permissions or CSP that got looser.
- **Tests.** Behavior that changed with no test change, and tests that cannot fail.
- **Leftovers.** Debug logs, `.only`, commented-out blocks, and hardcoded local paths, usernames or machine names. These are common when the work was done on another machine.
- **Dependencies.** New packages, major version bumps, and a lockfile that disagrees with the manifest.

**Check the project rules.** Apply them to added (`+`) lines only, so that pre-existing code is not blamed on this PR. Use the repo's own rule files at the PR head, if they exist: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, and every file in `.agents/instructions/` (or `.agent/instructions/`). A review file there, such as `review.instruction.md`, may list grep-able violation signals and rows of grandfathered code; honor both. Read these files with the contents API at `<headRefOid>`. A 404 means the file is absent.

Then apply the user's global rules in `~/.agents/instructions/` wherever the repo sets no rule of its own: `review.instruction.md` lists grep-able violation signals, and `core`, `frontend`, `api` and `desktop` hold the conventions it cites. Each file states its scope, so apply it only when the repo matches. If they disagree with the repo's rules, the repo's rules win, and you should mention the conflict.

Report only findings you can point at and explain. Give each one a severity and a confidence (1–10):

| Severity | Meaning |
|---|---|
| Critical | Breaks the build, loses data, or opens a security hole |
| High | Wrong behavior on a normal path |
| Medium | Edge-case bug, changed behavior with no test, or a project-rule violation |
| Low | Maintainability, documentation or naming |

Move anything with confidence below 6 to **Questions for the author**. Skip style nitpicks unless a project rule names them.

## 5. Relate the PR to this machine (read-only)

This step applies only when the shell is in a clone of the same repo (`git remote get-url origin` matches `<owner>/<repo>`):

```bash
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
git status --short
git cat-file -e <headRefOid>      # succeeds only if the PR head commit is already local
```

Report:

- whether this machine is on the PR branch
- whether HEAD equals the PR head, or the PR head commit is not local yet (which means a fetch is needed)
- any uncommitted changes that would block a checkout

Suggest the command to continue, `gh pr checkout <n> --repo <owner>/<repo>`, but do not run it.

## 6. Report in chat

Size the report to the PR; a four-line docs change gets a short report. Link each `path:line` to `https://github.com/<owner>/<repo>/blob/<headRefOid>/<path>#L<line>` so it opens the exact version you reviewed. Take line numbers from the new side of the hunk header: in `@@ -a,b +c,d @@`, the first new line is `c`.

```markdown
## PR #<n> — <title>
<state>[, draft] · `<head>` → `<base>` · @<author> · +<additions> −<deletions> in <changedFiles> files · head `<sha7>`
<url>

### Context handoff
**Intent:** one or two sentences, in the author's terms.
**What changed:** bullets grouped by concern, each with its key files.
**State:** done, in progress, or blocked, with the evidence.
**Pick up here:** concrete next steps, drawn from Follow-ups, TODOs, unchecked tasks and the findings below.
**This machine:** branch and HEAD compared with the PR head, dirty files, and the command to continue.

### Review findings
| # | Severity | File:line | Finding | Confidence |
|---|---|---|---|---|

For each finding: what is wrong, why it matters, and a suggested fix (a short snippet when that is clearer).
If there are none, write "No findings" and list what was checked. Do not invent findings.

### Description vs diff
- Matched: …
- Partial: …
- Missing (claimed, not in the diff): …
- Unmentioned (in the diff, not claimed): …

### Questions for the author
- what the PR does not answer, including findings below the confidence threshold

### Not reviewed
- skipped generated or oversized files, and the sources deliberately not read (comments, reviews, commits, CI, linked issues)
```

Delete any temp files you created. Leave out narration of steps that went as expected.
