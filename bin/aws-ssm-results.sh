#!/bin/bash
#
# Get SSM command results
#
#  ssmId=$(echo "${{ssmResults}}" | jq -r .Command.CommandId)

ssmId=$1
status='Pending'
while [ "${status}" = "Pending" -o "${status}" = "InProgress" -o "${status}" = "Delayed" ]; do
  ssmResult=$(aws ssm list-commands --command-id ${ssmId})
  status=$(echo "${ssmResult}" | jq .Command.Status)
done
case status in
  Canceled)
    echo "ERROR: SSM Aborted"
    ;;
  Failed|Undeliverable|Terminated)
    echo "ERROR: SSM Failed"
    ;;
  *)
    echo "SSM completed with status: ${status}"
    ;;
esac
