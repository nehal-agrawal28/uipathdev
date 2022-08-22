({
    handleMergeCandidatesUpdate : function(component, event) {
        // Depending on the type of operation (add/remove), either add or remove the opp id accordingly 
        var oppId = event.getParam("oppId");
        var includeInMerge = !!event.getParam("includeInMerge");

        // If operation was to add, only add the Id if it doesn't already exist
        var oppIdList = component.get("v.oppsToMergeFrom");

        // Determine the operation
        if (includeInMerge) {
            // If the Id isn't found, add it
            if (oppIdList.indexOf(oppId) === -1) {
                oppIdList.push(oppId);
            }
        }
        else {
            // If the Id was found already, remove it
            if (oppIdList.indexOf(oppId) > -1) {
                oppIdList.splice(oppIdList.indexOf(oppId), 1);
            }
        }

        // Update the list of merge candidates
        component.set("v.oppsToMergeFrom", oppIdList);
    },

    handleMergeOppsButtonClick : function(component, event, helper) {
        helper.mergeOpportunities(component, event);
    },

    handleOppUpdated : function(component, event, helper) {
        helper.handleOppUpdated(component, event);
    }
})