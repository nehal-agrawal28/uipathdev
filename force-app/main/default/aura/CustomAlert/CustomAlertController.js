({
   hide : function (component, event, helper) {
		let modal = component.find ('myModal');
       	$A.util.addClass(modal, 'slds-hide');
   },
   show : function (component, event, helper) {
		let modal = component.find ('myModal');
       	$A.util.removeClass(modal, 'slds-hide');
   },
   onScriptLoaded : function (component, event, helper) {
        
   },
   closeModel: function(component, event, helper) {
       var cmpEvent = component.getEvent("alertEvent");
       let isSuccess =  component.get  ('v.isSuccess');
       if (isSuccess) {
       		cmpEvent.fire();    
       }
	   let modal = component.find ('myModal');
       $A.util.addClass(modal, 'slds-hide');
   },
})