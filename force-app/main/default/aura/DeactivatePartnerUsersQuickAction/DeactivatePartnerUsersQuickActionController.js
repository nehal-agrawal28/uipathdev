({
    onclickNo : function(component, event, helper)
    {
        $A.get("e.force:closeQuickAction").fire();
    },

    onclickYes : function(component, event, helper)
    {
        $A.util.removeClass(component.find("spinnerId"), "slds-hide");
        
        const action = component.get("c.deactivatePartnerUsers");
        action.setParams({
            accountId: component.get("v.recordId")
        });
        action.setCallback(this, function(response)
        {
            if (response.getState() === "SUCCESS")
            {
                console.log('Return Value', response.getReturnValue());

                $A.get("e.force:closeQuickAction").fire();
                helper.showToast($A.get("$Label.c.Partner_User_Deactivation_Success_Message"), "Success!", "success");
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                console.log('Not Successful!');
                console.log('Errors', response.getError());
                $A.get("e.force:closeQuickAction").fire();
                helper.showToast($A.get("$Label.c.Partner_User_Deactivation_Error_Message"), "Error!", "error");
            }
        });

        $A.enqueueAction(action);
    }
})