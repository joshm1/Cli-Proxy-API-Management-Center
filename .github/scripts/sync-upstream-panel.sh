#!/usr/bin/env bash
set -euo pipefail

upstream=router-for-me/Cli-Proxy-API-Management-Center
tag="$(gh api "repos/$upstream/releases/latest" --jq .tag_name)"
if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::Unexpected upstream release tag: $tag"
  exit 1
fi

ref="refs/tags/$tag"
git fetch --no-tags "https://github.com/$upstream.git" "$ref:$ref"
upstream_commit="$(git rev-parse "$ref^{commit}")"
if git merge-base --is-ancestor "$upstream_commit" HEAD; then
  echo "$tag is already merged."
  if [[ "$GITHUB_EVENT_NAME" == schedule ]]; then
    released="$(gh api "repos/$GITHUB_REPOSITORY/releases/latest" --jq .target_commitish || true)"
    if [[ "$released" == "$(git rev-parse HEAD)" ]]; then
      echo "skip=true" >> "$GITHUB_OUTPUT"
    fi
  fi
  exit 0
fi

git config --local user.name 'github-actions[bot]'
git config --local user.email '41898282+github-actions[bot]@users.noreply.github.com'
if ! git merge --no-ff --no-commit "$upstream_commit"; then
  git rev-parse -q --verify MERGE_HEAD >/dev/null
fi
# Keep the fork's release automation under its own control.
git restore --source=HEAD --staged --worktree -- .github/workflows
if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
  echo "::error::Upstream $tag conflicts with the fork. Resolve the listed files before releasing."
  git diff --name-only --diff-filter=U
  exit 1
fi

git commit -m "Merge upstream panel $tag"
echo "SYNCED_UPSTREAM_TAG=$tag" >> "$GITHUB_ENV"
