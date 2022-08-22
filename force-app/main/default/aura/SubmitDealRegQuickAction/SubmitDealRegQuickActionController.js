({
    onclickNo : function(component, event, helper)
    {
        $A.get("e.force:closeQuickAction").fire();
    },

    onclickYes : function(component, event, helper)
    {
        $A.util.removeClass(component.find("spinnerId"), "slds-hide");
        
        const action = component.get("c.createOpportunityWithProducts");
        action.setParams({
            dealRegId: component.get("v.recordId")
        });
        action.setCallback(this, function(response)
        {
            if (response.getState() === "SUCCESS")
            {
                $A.get("e.force:closeQuickAction").fire();
                helper.showToast($A.get("$Label.c.Deal_Registration_Success_Message"), "Success!", "success");
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                const errors = response.getError();  
                $A.get("e.force:closeQuickAction").fire();
                if(errors[0] && errors[0].message && errors[0].message.toString().includes("deal type is not allowed")){//BPO or Resale deal type is not allowed because your Account does not have this agreement'
                    helper.showToast("This deal type is not allowed for your Account", "Error!", "error");
                }else{
                    helper.showToast("Something went wrong, please contact the System Admin", "Error!", "error");
                }
            }
        });

        $A.enqueueAction(action);
    }
})