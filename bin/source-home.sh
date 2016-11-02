
# TODO: validate that 1 of these succeeded, else fail - Not under Jenkins

if [ -d "${JENKINS_HOME}" ]; then
  # or [ "${NODE_NAME}" = "master" ]
  # Jenkins master
  home=${JENKINS_HOME}
else
  # Jenkins build slave
  home=${WORKSPACE%%/workspace*}
fi
