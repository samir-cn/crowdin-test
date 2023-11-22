#!/bin/bash

set -euo pipefail
if test "${RUNNER_DEBUG:-0}" == '1'; then set -x; fi

usage() {
  echo "Usage: $(basename "$0") [-p project id] [-b branch id]"
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

if [ -n "$BRANCH_ID" ]; then
  BRANCH_NAME=""
  BRANCH_DATA=$(curl -s \
    --request GET "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/branches/$BRANCH_ID" \
    -H 'Content-type: application/json' \
    -H "Authorization: Bearer $PERSONAL_TOKEN")
  BRANCH_NAME=$(echo "$BRANCH_DATA" | jq -r ".data.name")

  echo "$BRANCH_NAME"
  echo "branch-name=$BRANCH_NAME" >> $GITHUB_OUTPUT
else
  echo "Branch with this name was not found in Crowdin, couldn't get progress value for it."
  exit 1
fi

echo "::endgroup::"
