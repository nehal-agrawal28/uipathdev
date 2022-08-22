({
    doInit : function (component, event, helper) {

    },
   	hide : function (component, event, helper) {
        component.set ('v.theme', 'slds-theme_error');
        component.set ('v.icon', 'utility:error');
        component.set ('v.showModal', false);
   	},
   	show : function (component, event, helper) {
        let isSuccess = component.get  ('v.isSuccess');
        if (isSuccess) {
       		component.set ('v.theme', 'slds-theme_success');
            component.set ('v.icon', 'utility:success');
       	}
        component.set ('v.showModal', true);
   	},
   	onScriptLoaded : function (component, event, helper) {
        
   	},
   	closeModel: function(component, event, helper) {
       var cmpEvent = component.getEvent("alertEvent");
       let isSuccess =  component.get  ('v.isSuccess');
       if (isSuccess) {
       		cmpEvent.fire();    
       }
       component.set ('v.showModal',false);        
   },
})