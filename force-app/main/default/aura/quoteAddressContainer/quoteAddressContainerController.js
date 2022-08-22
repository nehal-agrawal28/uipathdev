({
	doInit : function(component, event, helper) {        
        helper.getCurrentQuote(component, event);
    },

    handleSelectBillToClick : function(component, event, helper) {
        component.set("v.modalHeader","Select Bill To Address");
        component.set("v.selectorMode","BillTo");
        helper.getAddressOptionList(component, event);  
    },
    
    handleSelectShipToClick : function(component, event, helper) {
        component.set("v.modalHeader","Select Ship To Address");
        component.set("v.selectorMode","ShipTo");
        helper.getAddressOptionList(component, event);  
    },
    
    onCheckboxChange : function(component, event, helper) {
        var itemId = event.getSource().get("v.name");
        component.set("v.selectedAddress",itemId);
        
        //Gets the checkbox group based on the checkbox id
		var availableCheckboxes = component.find('rowSelectionCheckboxId');
        var resetCheckboxValue  = false;
        if (Array.isArray(availableCheckboxes)) {
            //If more than one checkbox available then individually resets each checkbox
            availableCheckboxes.forEach(function(checkbox) {
                checkbox.set('v.value', resetCheckboxValue);
            }); 
        } else {
            //if only one checkbox available then it will be unchecked
            availableCheckboxes.set('v.value', resetCheckboxValue);
        }
        //mark the current checkbox selection as checked
        event.getSource().set("v.value",true);
	},
    
    closeModal : function(component, event, helper) {
        component.set("v.isOpen",false); 
    },
    
    selectAndCloseModal : function(component, event, helper) {
        helper.setAddress(component, event);         
    }
})