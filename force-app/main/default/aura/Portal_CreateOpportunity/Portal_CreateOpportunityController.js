({
	doInit : function(component, event, helper) {
		helper.LoadOpportunity(component, event, helper);
	},
    saveOpp : function(component, event, helper) {
        component.set("v.errorMessage", "");
        var errors = helper.CheckFields(component, event, helper);
        if (errors == "") {
			helper.SaveOpp(component, event, helper);
        } else {
            component.set("v.errorMessage", errors);
        }
	}
})