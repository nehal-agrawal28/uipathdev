({
    doInit : function(component, event, helper) {
        helper.populateOpportunities(component);
    },

    handleOppSelectToMergeCheckbox : function(component, event, helper) {         
        helper.fireMergeCandidateCheckboxAction(component, event);
    }
})