#!/usr/bin/python

# Author: Steven Nemetz

import boto3
import getopt
import sys

def usage():
    print '%s <options>\n' % (sys.argv[0])
    print '-a --action      Instance action: start, status, stop'
    print '-h --help        This page'
    print '-i --instance    List of instance names to apply action to'
    sys.exit(1)

def getArgs(argv):
    try:
        opts, args = getopt.getopt(argv, "a:hi:", ["action=", "help", "instances="] )
    except getopt.GetoptError:
        usage()
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
        elif opt in ("-a", "--action"):
            action = arg
        elif opt in ("-i", "--instances"):
            instances = arg
    if not action in ['start', 'stop']:
        print "ERROR: 'action' must be 'start' or 'stop'"
        usage()
    # TODO: validate instances
    return action, instances

action, instances = getArgs(sys.argv[1:])
instanceNames = instances.split(',')
print "Requested '%s' on: " % action, instanceNames

ec2 = boto3.resource('ec2')

# Get instances
print "Instances:"
instances = ec2.instances.filter(
    Filters=[{'Name': 'tag:Name', 'Values': instanceNames}])

# Perform action if not already in that state
for instance in instances:
    print("Current state: ", instance.id, instance.instance_type, instance.tags[0]["Value"], instance.state["Name"])
    if action == 'start':
        if instance.state["Name"] == 'stopped':
            ec2.instances.filter(InstanceIds=[instance.id]).start()
    elif action == 'stop':
        if instance.state["Name"] == 'running':
            ec2.instances.filter(InstanceIds=[instance.id]).stop()
    elif action != 'status':
        print "ERROR: unknown action: %s" % action
        sys.exit(1)
    instance.reload()
    print('After requested '%s': ' % action, instance.id, instance.tags[0]["Value"], instance.state["Name"])
