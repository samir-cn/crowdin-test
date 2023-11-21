#!/bin/bash

set -euo pipefail
if test "${RUNNER_DEBUG:-0}" == '1'; then set -x; fi

usage() {
  echo "Usage: $(basename "$0") [-f format type] [-b branch name]"
  echo "-f: format type"
  echo "-b: branch name"
}

while getopts 'f:b:h' opt; do
  case "$opt" in
    f) FORMAT_TYPE=$OPTARG ;;
    b) BRANCH_NAME=$OPTARG ;;
    h) usage; exit 0 ;;
    ?) usage; exit 1 ;;
  esac
done

echo "::group::Format branch for $FORMAT_TYPE"

FORMATTED_BRANCH=""

if [ FORMAT_TYPE == "crowdin" ]; then
  BRANCH_WITHOUT_DASH=${BRANCH_NAME//\-/_}
  BRANCH_WITHOUT_SLASH=${BRANCH_WITHOUT_DASH//\//-}
  FORMATTED_BRANCH=$BRANCH_WITHOUT_SLASH
elif [ FORMAT_TYPE == "github" ]; then
  BRANCH_WITH_SLASH=${BRANCH_NAME//\-/\/}
  BRANCH_WITH_DASH=${BRANCH_WITH_SLASH//\_/-}
  FORMATTED_BRANCH=$BRANCH_WITH_DASH
else
  echo "Format type not supported"
  exit 1
fi

echo "formatted-branch=$FORMATTED_BRANCH" >> $GITHUB_OUTPUT

echo "::endgroup::"
