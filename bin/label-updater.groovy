nodeName = NodeToUpdate
labelName = LabelName
set = DesiredState
listener.logger.println("Running label updater")
listener.logger.println("Node: " + nodeName + " Label: " + labelName + " Set: " + set)

for (node in jenkins.model.Jenkins.instance.nodes) {
    if (node.getNodeName().equals(nodeName)) {
        listener.logger.println("Found node to update: " + nodeName)
        oldLabelString = node.getLabelString()
        if (set.equals('true')) {
            if (!oldLabelString.contains(labelName)) {
                listener.logger.println("Adding label '" + labelName     + "' from node " + nodeName);
                newLabelString = oldLabelString + " " + labelName
                node.setLabelString(newLabelString)
                node.save()
            } else {
                listener.logger.println("Label '" + labelName + "' already exists on node " + nodeName)
            }
        }
        else {
            if (oldLabelString.contains(labelName)) {
                listener.logger.println("Removing label '" + labelName + "' from node " + nodeName)
                newLabelString = oldLabelString.replaceAll(labelName, "")
                node.setLabelString(newLabelString)
                node.save()
            } else {
                listener.logger.println("Label '" + labelName + "' doesn't exist on node " + nodeName)
            }
        }
    }
}
