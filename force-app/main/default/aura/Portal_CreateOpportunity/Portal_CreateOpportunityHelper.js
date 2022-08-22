({
	LoadOpportunity : function(component, event, helper) {
		
        var action = component.get("c.InitOpportunity");

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.opportunity", response.getReturnValue());
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    CheckFields : function(component, event, helper) {
        var opp = component.get("v.opportunity");
        if (opp.Name == null || opp.Name == "") {
            return "All fields are mandatory";
        }
        if (opp.Client__c == null || opp.Client__c == "") {
            return "All fields are mandatory";
        }
        if (opp.Opportunity_Vertical__c == null || opp.Opportunity_Vertical__c == "") {
            return "All fields are mandatory";
        }
        if (opp.Client_s_Billing_Country__c == null || opp.Client_s_Billing_Country__c == "") {
            return "All fields are mandatory";
        }
        if (opp.Client_Project_Name__c == null || opp.Client_Project_Name__c == "") {
            return "All fields are mandatory";
        }
        if (opp.Client_Contact_Email__c == null || opp.Client_Contact_Email__c == "") {
            return "All fields are mandatory";
        }
        if (opp.Contract_Duration__c == null || opp.Contract_Duration__c == "") {
            return "All fields are mandatory";
        }
        if (isNaN(opp.Contract_Duration__c)) {
            return "Contract Duration needs to be a valid number";
        }
        if (opp.Potential_Opportunity_Value__c == null || opp.Potential_Opportunity_Value__c == "") {
            return "All fields are mandatory";
        }
        if (isNaN(opp.Potential_Opportunity_Value__c)) {
            return "Potential Opportunity Value needs to be a valid number";
        }
        if (opp.Description == null || opp.Description == "") {
            return "All fields are mandatory";
        }
        if (opp.Products_offered__c == null || opp.Products_offered__c == "") {
            return "All fields are mandatory";
        }
        if (opp.Working_with_other_partners_on_this_opp__c == null || opp.Working_with_other_partners_on_this_opp__c == "") {
            return "All fields are mandatory";
        }
        if (opp.Working_with_other_partners_on_this_opp__c == 'Yes') {
            if (opp.Other_Partners_Involved__c == null || opp.Other_Partners_Involved__c == "") {
                return "All fields are mandatory";
            }
        }
        return "";
    },
    SaveOpp : function(component, event, helper) {
		component.set("v.loading", "true");
                      
        var action = component.get("c.SaveOpportunity");
        
        action.setParams({ opp : component.get("v.opportunity") });

        action.setCallback(this, function(response) {
            component.set("v.loading", "false");
            var state = response.getState();
            if (state === "SUCCESS") {
                var saveResult = response.getReturnValue();
                if (saveResult.success) {
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                      "recordId": saveResult.id,
                      "slideDevName": "detail"
                    });
                    navEvt.fire();
                } else {
                    component.set("v.errorMessage", saveResult.errorMessage);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	}
})