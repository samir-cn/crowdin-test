#!/bin/bash

set -euo pipefail
if test "${RUNNER_DEBUG:-0}" == '1'; then set -x; fi

usage() {
  echo "Usage: $(basename "$0") [-p project id] [-b branch name] [-t personal token]"
  echo "-p: project id"
  echo "-b: branch name"
  echo "-t: personal token"
}

while getopts 'p:b:t:h' opt; do
  case "$opt" in
    p) PROJECT_ID=$OPTARG ;;
    b) BRANCH_NAME=$OPTARG ;;
    t) PERSONAL_TOKEN=$OPTARG ;;
    h) usage; exit 0 ;;
    ?) usage; exit 1 ;;
  esac
done

echo "::group::Delete Crowdin branch"

BRANCHES=$(curl -s \
  --request GET "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/branches?name=$BRANCH_NAME" \
  -H 'Content-type: application/json' \
  -H "Authorization: Bearer $PERSONAL_TOKEN")
exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "Error with getting current branch from Crowdin"
  exit 1
fi

BRANCH=$(echo "$BRANCHES" | jq -r '.data[0]')

if [ -n "$BRANCH" ]; then
  BRANCH_ID=$(echo "$BRANCH" | jq -r '.data.id')

  if [ -n "$BRANCH_ID" ]; then

    curl \
      --request DELETE "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/branches/$BRANCH_ID" \
      -H 'Content-type: application/json' \
      -H "Authorization: Bearer $PERSONAL_TOKEN"
    exit_code_branch=$?
    
    if [ $exit_code_branch -ne 0 ]; then
      echo "Error with deleting current branch from Crowdin"
      exit 1
    fi
  else
    echo "Branch with this name was not found in Crowdin, couldn't delete it."
    exit 1
  fi
else
  echo "Branch with this name was not found in Crowdin, couldn't delete it."
  exit 1
fi

echo "::endgroup::"
