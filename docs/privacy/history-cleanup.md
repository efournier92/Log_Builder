# Commit History Cleanup

The repository history exposes the maintainer email and roughly 470 commit subjects that name personal routines. Untracking the `builds/` binaries did not remove their blobs. Full removal needs a history rewrite and a force push. This is deferred and must be run deliberately by the owner.

## What Leaks

- Author and committer email on every commit.
- An alternate handle linked to the same email.
- Commit subjects naming routines (laundry, gym, rent, billing, appointments, deployments).
- Two large binary blobs under `builds/` and the old `tags` blob.

## Preconditions

- Confirm no one else relies on clones, forks, or open pull requests.
- Take a full mirror backup first: `git clone --mirror <remote> <backup>.git`.
- Prefer `git filter-repo` (installed separately) over `git filter-branch`.
- Get explicit owner approval. The rewrite is irreversible and rewrites shared history.

## Steps

1. Back up the mirror and keep it until verified.
2. Map every old identity to the new one in a mailmap, then run `git filter-repo --mailmap mailmap.txt`.
3. Scrub commit messages with `git filter-repo --message-callback` or a replacement list, replacing routine-revealing subjects while keeping them meaningful.
4. Drop the binary and old `tags` blobs from history, but keep the current tip's snapshot: `git filter-repo --path builds/ --path tags --invert-paths`, then re-commit the current `builds/log-builder_YYYY-MM-DD` on the rewritten `main` so the drift test and `bin/install` still work and a fresh clone of the release tag passes.
5. Force push every branch: `git push --force --all`. Do not force-move pushed tags: delete the pre-rewrite release tag (`git push origin :refs/tags/vYYYY.MM.DD`) and recreate it at the rewritten merge commit, then republish the GitHub Release.
6. Ask GitHub Support to garbage collect, or delete and recreate the repository, so old objects are purged.
7. Rotate or abandon the exposed email if it is still in use.

## Verify

- `git log --format='%an <%ae>' | sort -u` shows only the new identity.
- `git log --format='%s' | rg -i 'laundry|gym|rent|billing|appointment'` returns nothing.
- `git rev-list --objects --all | rg 'builds/|tags'` returns nothing.
- The rewritten `main` tip still contains `builds/log-builder_*` after the re-commit.

## Caveats

- Fork and clone users keep the old objects until they re-clone.
- Rewriting changes every commit hash, so any open branch or pull request must be recreated.
- Any tag or GitHub Release created before the rewrite must be deleted and recreated after it; the target commit hash changes, and force-moving a pushed tag is not allowed.
- Run this only after the current branch work is merged or preserved elsewhere.
