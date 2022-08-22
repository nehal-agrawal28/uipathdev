({
    populateOpportunityProducts : function(component) {
        // Get a list of Opportunities that belong to the same account
        var action = component.get("c.getProductsForOpportunity");
        
        action.setParams({
            oppId: component.get("v.recordId")
        });
       
		action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                
                component.set("v.oppLineItems", returnValue);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // TODO: Better error handling
                        
                        // Clear the list of Opportunities to ensure nothing bad is displayed
                        component.set("v.oppLineItems", null);
                    }
                } 
                else {
                    // TODO: Better error handling

                    // Clear the list of Opportunities to ensure nothing bad is displayed
                    component.set("v.oppLineItems", null);
                }
            }
        });

        $A.enqueueAction(action);
    }
})