nodeName = manager.envVars['NodeToUpdate']
labelName = manager.envVars['LabelName']
set = manager.envVars['DesiredState']

for (node in jenkins.model.Jenkins.instance.nodes) {
    if (node.getNodeName().equals(nodeName)) {
        manager.listener.logger.println("Found node to update: " + nodeName)
        oldLabelString = node.getLabelString()
        if (set.equals('true')) {
            if (!oldLabelString.contains(labelName)) {
                manager.listener.logger.println("Adding label '" + labelName     + "' from node " + nodeName);
                newLabelString = oldLabelString + " " + labelName
                node.setLabelString(newLabelString)
                node.save()
            } else {
                manager.listener.logger.println("Label '" + labelName + "' already exists on node " + nodeName)
            }
        }
        else {
            if (oldLabelString.contains(labelName)) {
                manager.listener.logger.println("Removing label '" + labelName + "' from node " + nodeName)
                newLabelString = oldLabelString.replaceAll(labelName, "")
                node.setLabelString(newLabelString)
                node.save()
            } else {
                manager.listener.logger.println("Label '" + labelName + "' doesn't exist on node " + nodeName)
            }
        }
    }
}
