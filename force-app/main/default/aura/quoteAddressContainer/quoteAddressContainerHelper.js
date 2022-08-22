({
	getCurrentQuote : function(component, event) {
        var self = this;
    	var action = component.get("c.retrieveQuote");
console.log("getCurrentQuote");         
        action.setParams({ 
            quoteId: component.get("v.recordId")        
        });
       
		action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var quote = response.getReturnValue();
                component.set("v.quote", quote);
                component.set("v.billToAddressId", quote.Bill_To_Address__c);
                component.set("v.shipToAddressId", quote.Ship_To_Address__c);
                self.getCurrentAddresses(component, event);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
            }
        });

        $A.enqueueAction(action);
    },

    
    getCurrentAddresses : function(component, event) {
    	var action = component.get("c.retrieveCurrentAddresses");
       
        var billToAddressId = component.get("v.quote.Bill_To_Address__c");
        var shipToAddressId = component.get("v.quote.Ship_To_Address__c");
        
        action.setParams({ 
            billToAddressId: billToAddressId,
            shipToAddressId: shipToAddressId
        });
       
		action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var addressList = response.getReturnValue();
                var billToFound = false;
				var shipToFound = false;                
                
                for(var i = 0; i < addressList.length; i++){
                    if(addressList[i].Id === billToAddressId){
                        billToFound = true;
                        component.set("v.billToAddress",addressList[i]);
                    }
                    if(addressList[i].Id === shipToAddressId){
                        shipToFound = true;
                        component.set("v.shipToAddress",addressList[i]);
                    }
                }
                if(!billToFound){
                    component.set("v.billToAddress",null);
                    component.set("v.billToAddressPresent",false);
                }
                if(!shipToFound){
                    component.set("v.shipToAddress",null);
                    component.set("v.shipToAddressPresent",false);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
            }
        });

        $A.enqueueAction(action);
    },
    
    getAddressOptionList : function(component, event) {
               
    	var action = component.get("c.retrieveAddressOptionList");
        var selectorMode = component.get("v.selectorMode");
        var billToAddressId = component.get("v.quote.Bill_To_Address__c");
        var shipToAddressId = component.get("v.quote.Ship_To_Address__c");

        action.setParams({ 
            quoteId: component.get("v.recordId"),
            selectorMode: selectorMode
        });
       
		action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                component.set("v.addressOptionsList", response.getReturnValue());
                
                //mark the right radio button
                var availableCheckboxes = component.find('rowSelectionCheckboxId');
                if (Array.isArray(availableCheckboxes)) {
                    availableCheckboxes.forEach(function(checkbox) {
                        var addressId = checkbox.get("v.name");
                        console.log("addressId " + addressId);
                        if(selectorMode == "BillTo"){
                            if(billToAddressId == addressId){
                                checkbox.set("v.value",true);
                            }
                        }
                        if(selectorMode == "ShipTo"){
                            if(shipToAddressId == addressId){
                                checkbox.set("v.value",true);
                            }
                        }
                    }); 
                }
                else{
                    console.log("no checkboxes found");
                }
                component.set("v.isOpen",true);     
            }
            else if (state === "ERROR") {
                var errors = response.getError();
            }
        });

        $A.enqueueAction(action);
    },
    
    setAddress : function(component, event) {
//What if no address was selected?
		var self = this;
        
    	var action = component.get("c.setQuoteAddress");

        action.setParams({ 
            quoteId: component.get("v.recordId"),
            addressId: component.get("v.selectedAddress"),
            selectorMode: component.get("v.selectorMode")            
        });
       
		action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                //force refresh of component
                self.getCurrentQuote(component, event);
                component.set("v.isOpen",false);
console.log("before refresh");    
                $A.get('e.force:refreshView').fire();
            }
            else if (state === "ERROR") {
console.log("error");                  
                var errors = response.getError();
            }
        });

        $A.enqueueAction(action);
    }
})