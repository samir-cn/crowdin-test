#!/bin/bash

set -euo pipefail
if test "${RUNNER_DEBUG:-0}" == '1'; then set -x; fi

usage() {
  echo "Usage: $(basename "$0") [-p project id] [-b branch id]"
  echo "-p: project id"
  echo "-b: branch id"
  # echo "-t: personal token"
}

while getopts 'p:b:t:h' opt; do
  case "$opt" in
    p) PROJECT_ID=$OPTARG ;;
    b) BRANCH_ID=$OPTARG ;;
    # t) PERSONAL_TOKEN=$OPTARG ;;
    h) usage; exit 0 ;;
    ?) usage; exit 1 ;;
  esac
done

echo "::group::Check Crowdin branch progress"

echo "$BRANCH_ID"

if [ -n "$BRANCH_ID" ]; then
  BRANCH_PROGRESS=$(curl \
    --request GET "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/branches/$BRANCH_ID/languages/progress" \
    -H 'Content-type: application/json' \
    -H "Authorization: Bearer 5a10c8997dbe5a7783cc15bcf6ee98cd2660360c2db5dc515825527d344b329df2a6e8e486284110")
  exit_code_branch=$?

  BRANCHES=$(echo "$BRANCH_PROGRESS" | jq -r '.data')

  progress="0"

  for i in "${BRANCHES[@]}"; do
    echo "$i"
    translationProgress=$(echo "$i" | jq '.data.translationProgress')
    approvalProgress=$(echo "$i" | jq '.data.approvalProgress')
    echo "$translationProgress"
    echo "$approvalProgress"

    if [ "$translationProgress" -eq 100 ] || [ "$approvalProgress" -eq 100 ]; then
      progress="100"
      break
    fi
  done

  echo "progress=$progress" >> $GITHUB_OUTPUT
  
  if [ $exit_code_branch -ne 0 ]; then
    echo "Error with getting current branch progress from Crowdin"
    exit 1
  fi
else
  echo "Branch with this name was not found in Crowdin, couldn't get progress value for it."
  exit 1
fi

echo "::endgroup::"
