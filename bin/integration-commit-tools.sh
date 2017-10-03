set +x
#
# Commit tool changes to git
#

# parse project name from job name
#   Strip folder: ${JOBNAME##*/}
project=$(echo ${JOB_NAME} | cut -d+ -f2)

echo "== Moving tools =="
# -u causing issue. Look into later
cp -avf tmp/bin .
chmod +x bin/*.sh
echo "== Moving configuration files =="
cp -avf tmp/etc .

git add bin/*
git add etc/*
git commit -m "Integrating tools from ${project}" || true

# Error and build fail if they are different
#	email (include diff list) and jira ticket
# Get git-changelog to work and sent changelog
