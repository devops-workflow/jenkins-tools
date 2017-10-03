
# TODO: validate that 1 of these succeeded, else fail - Not under Jenkins

if [ -d "${JENKINS_HOME}" ]; then
  # or [ "${NODE_NAME}" = "master" ]
  # Jenkins master
  NODE_HOME=${JENKINS_HOME}
else
  # Jenkins build slave
  NODE_HOME=${WORKSPACE%%/workspace*}
fi
