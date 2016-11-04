#!/bin/bash
#
# Transform whale-linter output in single line output for Jenkins Warning plugin
#
input=$1
while read -r line || [[ -n "$line" ]]; do
  # Skip lines
  if [[ ! $(echo $line | grep ':' | wc -l) -gt 0 ]]; then
    continue
  fi
  # Remove all color codes first, will simplfy the rest of the regex matching
  # Mac
  #line=$(echo $line | sed -E 's/.\[[0-9]+m//g')
  # Linux
  line=$(echo $line | sed -r 's/.\[[0-9]+m//g')
  # Check for priority change and get
  if [[ $(echo $line | grep -E 'CRITICAL\s*:' | wc -l) -gt 0 ]]; then
    priority='CRITICAL'
    continue
  elif [[ $(echo "$line" | grep -E 'WARNING\s*:' | wc -l) -gt 0 ]]; then
    priority='WARNING'
    continue
  elif [[ $(echo "$line" | grep -E 'ENHANCEMENT\s*:' | wc -l) -gt 0 ]]; then
    priority='ENHANCEMENT'
    continue
  fi
  # Parse message lines
  #   21: [93mBadPractice : [0mThere is two consecutive 'RUN'. Consider chaining them with '\' and '&&'
  lineNumber=${line%%:*}
  lineNumber=$(echo $lineNumber | sed 's/^\s+//')
  if [ -z "$lineNumber" ]; then
    continue
  fi
  # if lineNumber is NOT a number, it is the category instead
  if [[ $lineNumber =~ ^[0-9]+$ ]]; then
    category=${line#*:}
    category=${category%%:*}
  else
    category=$lineNumber
    lineNumber=0
  fi
  msg=${line##*:}
  # Trim leading and trailing white space
  category=$(echo $category | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')
  msg=$(echo $msg | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')
  echo "${priority};${lineNumber};${category};${msg}"
done < "$input"
