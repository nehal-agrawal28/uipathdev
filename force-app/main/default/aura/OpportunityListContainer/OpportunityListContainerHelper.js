({
    mergeOpportunities : function(component) {
        var action = component.get("c.mergeOpportunities");
        
        action.setParams({ 
            destinationOpp: component.get("v.recordId"),
            oppsToMergeFrom: component.get("v.oppsToMergeFrom")
        });
       
		action.setCallback(this, function(response) {
            var state = response.getState();

            var toastEvent = $A.get("e.force:showToast");
            
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();

                // Clear checkboxes
                component.set("v.oppsToMergeFrom", []);

                // Fire the event
                component.find("oppList").reInit();

                if (returnValue == "Success") {
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success",
                        "message": "The record has been updated successfully. You may need to refresh the page."
                    });
                }
                else {
                    toastEvent.setParams({
                        "type": "warning",
                        "title": "Error",
                        "message": "Please try again, or alternatively let your Salesforce Administratpr see the following error message:\n\n" + returnValue
                    });
                }                
                
                toastEvent.fire();
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
        
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error",
                            "message": "Please try again, or alternatively let your Salesforce Administratpr see the following error message:\n\n" + errors[0].message
                        });
                    }
                }
                else {
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error",
                        "message": "Could not update the Opportunities. Please refresh the page and try again."
                    });
                }

                toastEvent.fire();
            }
        });

        $A.enqueueAction(action);
    },

    handleOppUpdated : function(component, event) {
        var eventParams = event.getParams();
        
        if(eventParams.changeType === "LOADED") {
            // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");

            component.set("v.IsClosed", component.get("v.opp.StageName") === "Dropped");
        } 
        else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } 
        else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } 
        else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    }
})