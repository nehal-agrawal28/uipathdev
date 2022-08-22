({
    fireMergeCandidateCheckboxAction : function(component, event) {
        var oppId = event.getSource().get("v.value");
        var checked = event.getParam("checked");

        // Fire the event
        var updateMergeCandidatesEvent = component.getEvent("updateMergeCandidates");

        updateMergeCandidatesEvent.setParams({
            "oppId" : oppId,
            "includeInMerge" : checked
        });

        updateMergeCandidatesEvent.fire();
    },

    populateOpportunities : function(component, event) {
        // Get a list of Opportunities that belong to the same account
        var action = component.get("c.getOpportunitiesForAccount");
        
        action.setParams({ 
            oppId: component.get("v.recordId")
        });
       
		action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                
                component.set("v.opportunities", returnValue);
            }
            else if (state === "ERROR") {
                var errors = response.getError();

                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // TODO: Better error handling
                        
                        // Clear the list of Opportunities to ensure nothing bad is displayed
                        component.set("v.opportunities", null);
                    }
                } 
                else {
                    // TODO: Better error handling

                    // Clear the list of Opportunities to ensure nothing bad is displayed
                    component.set("v.opportunities", null);
                }
            }
        });

        $A.enqueueAction(action);
    }
})