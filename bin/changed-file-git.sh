#!/bin/bash
#
# Check if a file changed
# Used for a conditional build step
#

if [ $(git log ${GIT_PREVIOUS_COMMIT}.. $1 | wc -l) -eq 0 ]; then
  # File not changed since last commit
  exit 1
else
  # File changed
  exit 0
fi
