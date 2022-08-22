({
    onInit : function( component, event, helper ) {    
        
        var action = component.get('c.updateTheBillingEvent'); 
        action.setParams({
            "recordId":component.get('v.recordId')
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                helper.showSuccess(component, event);
            } else {
                helper.showError(component, event);
                console.log('response: '+JSON.stringify(a));
            }
            $A.get("e.force:refreshView").fire();
            $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
    }
})