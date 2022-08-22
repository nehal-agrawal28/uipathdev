({
	
        
    doInit: function( component, event, helper ) {
        
        var action = component.get("c.getPageLayoutFields");
        action.setParams({
            "recordTypeId" : component.get("v.recordTypeId")
        });
		action.setCallback(this, function(response) {
        	var state = response.getState();
			if (state === "SUCCESS") {
                component.set("v.layoutSections", response.getReturnValue() );
                console.log( response.getReturnValue() );
            }
            else if (state === "INCOMPLETE") {
            }
            else if (state === "ERROR") {
                var errors = response.getError();
				console.log( errors );
            }
        });
        
        $A.enqueueAction(action);
    },

	handleSuccess : function(component, event, helper) {
        
        component.set("v.saveMessage", true);
        component.set("v.disableButton", true);
        $A.get("e.force:closeQuickAction").fire();
    },
    
    handleLoad : function(component, event, helper) {
       
        var accId = component.get("v.simpleRecord.AccountId");
        var oppAccId = component.get("v.recordId");
        if (accId != null) {
            var ctrls = component.find("inputFld");
            if (ctrls != null) {
                for (var i = 0; i < ctrls.length; i++) {
                    if (ctrls[i].get("v.fieldName") == "Account__c") {
                       ctrls[i].set("v.value", accId);
                    }
                    if (ctrls[i].get("v.fieldName") == "Opportunity__c") {
                        ctrls[i].set("v.value", oppAccId);
                    }
                }
            }
        }
        
    	component.set("v.showSpinner", false);
    },
    
    handleSubmit : function(component, event, helper) {
       
    }
})