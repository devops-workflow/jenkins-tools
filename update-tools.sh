#!/bin/bash
#
# Update Tools in Jenkins from Git repo
#
# Copy
#   $WORKSPACE/bin/* $home/bin
#   $WORKSPACE/etc/* $home/etc

if [ -d "${JENKINS_HOME}" ]; then
  # or [ "${NODE_NAME}" = "master" ]
  # Jenkins master
  home=${JENKINS_HOME}
else
  # Jenkins build slave
  home=${WORKSPACE%%/workspace*}
fi

echo "INFO: Destination HOME: ${home}"
echo "INFO: Copying bin..."
cp -afu ${WORKSPACE}/bin ${home}
echo "INFO: Copying etc..."
cp -afu ${WORKSPACE}/etc ${home}
