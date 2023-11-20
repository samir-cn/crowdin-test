#!/bin/bash

set -euo pipefail
if test "${RUNNER_DEBUG:-0}" == '1'; then set -x; fi

usage() {
  echo "Usage: $(basename "$0") [-p project id] [-b branch id] [-t personal token]"
  echo "-p: project id"
  echo "-b: branch id"
  echo "-t: personal token"
}

while getopts 'p:b:t:h' opt; do
  case "$opt" in
    p) PROJECT_ID=$OPTARG ;;
    b) BRANCH_ID=$OPTARG ;;
    t) PERSONAL_TOKEN=$OPTARG ;;
    h) usage; exit 0 ;;
    ?) usage; exit 1 ;;
  esac
done

echo "::group::Check Crowdin branch progress"

echo "$BRANCH_ID"
echo "Test"
echo "$PERSONAL_TOKEN"

if [ -n "$BRANCH_ID" ]; then
  BRANCH_PROGRESS=$(curl \
    --request GET "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/branches/$BRANCH_ID/languages/progress" \
    -H 'Content-type: application/json' \
    -H "Authorization: Bearer $PERSONAL_TOKEN")
  exit_code_branch=$?

  BRANCHES=$(echo "$BRANCH_PROGRESS" | jq -r '.data')

  should_proceed=true

  for i in "${BRANCHES[@]}"; do
    translationProgress=$(echo "$i" | jq '.data.translationProgress')
    approvalProgress=$(echo "$i" | jq '.data.approvalProgress')

    if [ "$translationProgress" -lt 100 ] || [ "$approvalProgress" -lt 100 ]; then
      should_proceed=false
      break
    fi
  done

  echo "progress=$should_proceed" >> $GITHUB_OUTPUT
  
  if [ $exit_code_branch -ne 0 ]; then
    echo "Error with getting current branch progress from Crowdin"
    exit 1
  fi
else
  echo "Branch with this name was not found in Crowdin, couldn't get progress value for it."
  exit 1
fi

echo "::endgroup::"
