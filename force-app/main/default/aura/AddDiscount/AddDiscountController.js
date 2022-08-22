({
	loadInfo : function(component, event, helper)
    {        
		helper.loadInfo(component, helper);
        helper.loadOptions(component, helper);
	},
    
    reload : function(component, event, helper)
    {        
		helper.loadInfo(component, helper);
        component.set("v.discountMessage", null);
	},
    
    applyDiscount : function(component, event, helper)
    {      
        helper.applyDiscount(component, helper);
    },
    
    close : function(component, event, helper)
    {
        $A.get("e.force:closeQuickAction").fire();
    }

})