({
    doInit : function(component, event, helper) {

        var action = component.get('c.upvoteDownVoteIdeas'); 
        // method name i.e. getEntity should be same as defined in apex class
        // params name i.e. entityType should be same as defined in getEntity method
        action.setParams({
            "actionType" : component.get('v.actionType'),
            "recordId":component.get('v.recordId')
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                helper.showSuccess(component, event);
            } else {
                helper.showError(component, event);
            }
            $A.get("e.force:refreshView").fire();
            $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
       
        
    }
})