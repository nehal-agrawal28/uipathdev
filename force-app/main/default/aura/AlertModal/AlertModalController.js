({
    
   
   doInit: function(component, event, helper) {
      
   },
   hide : function (component, event, helper) {
      component.set("v.isOpen", false);
   },
   show : function (component, event, helper) {
      component.set("v.isOpen", true);
   },
 
   closeModel: function(component, event, helper) {
       var cmpEvent = component.getEvent("alertEvent");
       let isSuccess =  component.get  ('v.isSuccess');
       if (isSuccess) {
       		cmpEvent.fire();    
       }
       component.set("v.isOpen", false);
   },
})