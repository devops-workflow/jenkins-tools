#!/bin/bash
#
# Select number of git log entries and output in JSON
#

# Other options:
#   https://github.com/dreamyguy/gitlogg
#   https://github.com/tarmstrong/git2json
#   https://github.com/paulrademacher/gitjson
#   https://gist.github.com/textarcana/1306223

commit_count=$1

git log -n ${commit_count} --pretty=format:'{%n  "commit": "%H",%n  "abbreviated_commit": "%h",%n  "refs": "%D",%n  "author": "%aN",%n  "date": "%aD",%n  "subject": "%s",%n  "body": "%b"%n},' \
perl -pe 'BEGIN{print "["}; END{print "]\n"}' | \
perl -pe 's/},]/}]/'

# Can put as second line to accept all arguments
# $@ | \

exit

# More complete field reference
git log -n ${commit_count} --pretty=format:'{%n  "commit": "%H",%n  "abbreviated_commit": "%h",%n  "tree": "%T",%n  "abbreviated_tree": "%t",%n  "parent": "%P",%n  "abbreviated_parent": "%p",%n  "refs": "%D",%n  "encoding": "%e",%n  "subject": "%s",%n  "sanitized_subject_line": "%f",%n  "body": "%b",%n  "commit_notes": "%N",%n  "verification_flag": "%G?",%n  "signer": "%GS",%n  "signer_key": "%GK",%n  "author": {%n    "name": "%aN",%n    "email": "%aE",%n    "date": "%aD"%n  },%n  "commiter": {%n    "name": "%cN",%n    "email": "%cE",%n    "date": "%cD"%n  }%n},'

git log -n ${commit_count} --pretty=format:'{%n
"commit": "%H",%n
"abbreviated_commit": "%h",%n
"tree": "%T",%n
"abbreviated_tree": "%t",%n
"parent": "%P",%n
"abbreviated_parent": "%p",%n
"refs": "%D",%n
"encoding": "%e",%n
"subject": "%s",%n
"sanitized_subject_line": "%f",%n
"body": "%b",%n
"raw body": "%B",%n
"commit_notes": "%N",%n
"verification_flag": "%G?",%n
"signer": "%GS",%n
"signer_key": "%GK",%n
"author": {%n    "name": "%aN",%n    "email": "%aE",%n    "date": "%aD"%n  },%n
"commiter": {%n    "name": "%cN",%n    "email": "%cE",%n    "date": "%cD"%n  }%n},'
