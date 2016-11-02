#!/bin/bash
#
# Update Tools in Jenkins from Git repo
#
# Copy
#   $WORKSPACE/bin/* $home/bin
#   $WORKSPACE/etc/* $home/etc

if [ -d "${JENKINS_HOME}" ]; then
  # or [ "${NODE_NAME}" = "master" ]
  home=${JENKINS_HOME}
else
  # FIX: need slave's jenkins home dir NOT user home
  #home=${HOME}
  home=${WORKSPACE%%/workspace*}
fi

echo "HOME: ${home}"
