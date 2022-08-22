({
	loadInfo : function(component, helper) 
    {
        component.set("v.loading", "true");
		var action = component.get("c.getInfo");
        action.setParams({ oppId : component.get("v.recordId")});
       
		action.setCallback(this, function(response) 
        {
            component.set("v.loading", "false");
            var state = response.getState();
            
            if (state === "SUCCESS") 
            {
                var returnValue = response.getReturnValue();
                component.set("v.opportunityProductList", returnValue);
            }
            else if (state === "ERROR")
            {
                var errors = response.getError();
                if (errors) 
                {
                    if (errors[0] && errors[0].message) 
                    {
                        component.set("v.errorFound",'true');
                        component.set("v.errorMessage",errors[0].message);
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } 
                else 
                {
                    component.set("v.errorFound",'true');
                    component.set("v.errorMessage",errors[0].message);
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    
    loadOptions : function(component, helper) 
    {
        component.set("v.loading", "true");
		var action = component.get("c.getOptions");        
       
		action.setCallback(this, function(response) 
        {
            component.set("v.loading", "false");
            var state = response.getState();
            
            if (state === "SUCCESS") 
            {
                var returnValue = response.getReturnValue();
                component.set("v.choiceList", returnValue);
            }
            else if (state === "ERROR")
            {
                var errors = response.getError();
                if (errors) 
                {
                    if (errors[0] && errors[0].message) 
                    {
                        component.set("v.errorFound",'true');
                        component.set("v.errorMessage",errors[0].message);
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } 
                else 
                {
                    component.set("v.errorFound",'true');
                    component.set("v.errorMessage",errors[0].message);
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    applyDiscount : function(component, helper) 
    {
        component.set("v.loading", "true");
		var action = component.get("c.calculateDiscount");              
        
        action.setParams
        ({ 	apply: component.get("v.apply"),          	
          	oppProd : JSON.stringify(component.get("v.opportunityProductList")), 
          	oppId : component.get("v.recordId"),
          	disc : component.get("v.discount")
         });
       	
		action.setCallback(this, function(response) 
        {
            component.set("v.loading", "false");
            var state = response.getState();
            
            if (state === "SUCCESS") 
            {
                var returnValue = response.getReturnValue();
                component.set("v.discountMessage", returnValue);               
            }
            else if (state === "ERROR")
            {                
                var errors = response.getError();
                if (errors) 
                {
                    if (errors[0] && errors[0].message) 
                    {     
                        component.set("v.errorFound",'true');
                        component.set("v.errorMessage",errors[0].message);
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } 
                else 
                {
                    component.set("v.errorFound",'true');
                    component.set("v.errorMessage",errors[0].message);
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	}
})