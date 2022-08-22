({

    cancelDialog: function(component, event, helper) {
        var oli = JSON.stringify(component.get("v.oliRecord"));
        var recId = component.get("v.oliRecord.OpportunityId");
        recId
        if (!recId) {
            var homeEvt = $A.get("e.force:navigateToObjectHome");
            homeEvt.setParams({
                "scope": "Opportunity"
            });
            homeEvt.fire();
        } else {
            helper.navigateTo(component, recId);
        }
    }
});