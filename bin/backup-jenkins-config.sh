#!/bin/bash
#
# Backup all the Jenkins configuration - ONLY config
#
# TODO: auto figure out path ${JENKINS_HOME}
# Add hostname in backup file name

dirJenkins='/var/lib/jenkins'
dirJenkins='/data/Projects/software/Jenkins-Home'

backupList='backup.files'
dateStamp=$(date '+%Y-%m-%d-%H.%M.%S')

pushd ${dirJenkins}
echo "DEBUG: Creating backup file list..."
cp /dev/null ${backupList}
for D in email-templates labels rules scriptler; do
  if [ -d ${D} ]; then
    echo "${D}" >> ${backupList}
  fi
done
ls -1 *.xml >> ${backupList}
find . \( -name config-history -o -name workspace \) -prune -o -name 'config.xml' -type f | grep \.xml >> ${backupList}
echo "DEBUG: Archiving..."
tar -czf backup.${dateStamp}.tgz -T ${backupList}


