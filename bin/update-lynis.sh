#!/bin/bash
#
# Ensure the current version of Lynis is installed
#
if [ $(lynis update info | grep Status | grep Outdated | wc -l) -gt 0 ]; then
  yum -y install lynis
fi
