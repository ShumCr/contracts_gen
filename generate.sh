#!/usr/bin/env bash
set -euo pipefail

ITERATIONS=${ITERATIONS:-500}
MAIN_BRANCH=${MAIN_BRANCH:-main}
REMOTE=${REMOTE:-origin}

# Get "now" and "6 months ago" in epoch seconds
NOW=$(date +%s)
SIX_MONTHS_AGO=$(date -d "84 months ago" +%s)

for i in $(seq 1 "$ITERATIONS"); do
  BRANCH="feature/eth-contract-rl-${i}"
  CONTRACT_DIR="contracts_rl"
  CONTRACT_FILE="${CONTRACT_DIR}/SimpleStorage_r_${i}.cpp"

  echo
  echo "=== Iteration $i: branch $BRANCH ==="

  git checkout "$MAIN_BRANCH"
  git pull "$REMOTE" "$MAIN_BRANCH"
  git checkout -b "$BRANCH"

  mkdir -p "$CONTRACT_DIR"

  cat > "$CONTRACT_FILE" <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public value;
    event ValueChanged(uint256 indexed newValue, address indexed changedBy);

    function set(uint256 _value) external {
        value = _value;
        emit ValueChanged(_value, msg.sender);
    }
}
EOF

  git add "$CONTRACT_FILE"

  # Pick a random timestamp between 6 months ago and now
  RAND_TS=$((RANDOM * RANDOM))   # get a big random number
  RANGE=$((NOW - SIX_MONTHS_AGO))
  RAND_OFFSET=$((RAND_TS % RANGE))
  COMMIT_EPOCH=$((SIX_MONTHS_AGO + RAND_OFFSET))

  # Convert to Git-friendly date format
  COMMIT_DATE=$(date -d "@$COMMIT_EPOCH" --rfc-3339=seconds)

  echo "Using random commit date: $COMMIT_DATE"

  GIT_AUTHOR_DATE="$COMMIT_DATE" \
  GIT_COMMITTER_DATE="$COMMIT_DATE" \
  git commit -m "feat: add SimpleStorage contract ($i)"

  git push "$REMOTE" "$BRANCH"

  git checkout "$MAIN_BRANCH"
  git pull "$REMOTE" "$MAIN_BRANCH"
  git merge --no-ff "$BRANCH" -m "Merge ${BRANCH} into ${MAIN_BRANCH}"
  git push "$REMOTE" "$MAIN_BRANCH"

  git branch -d "$BRANCH"
  git push "$REMOTE" --delete "$BRANCH" || true

  echo "=== Iteration $i done ==="
done
