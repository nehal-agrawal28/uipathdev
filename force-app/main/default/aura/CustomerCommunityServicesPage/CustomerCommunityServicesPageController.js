({
	doInit : function(component, event, helper) {
        helper.findAccountType (component);   
        helper.tryUpdateTheNumbers (component);
	},
   /* createInfraTask : function (component, event, helper) {
       	helper.createTask (component, 'infra');
    },
    createOptimizationTask : function (component, event, helper) {
        helper.createTask (component, 'optimization')
    },*/
    createContactSupportTask : function (component, event, helper) {
        helper.createTask (component, 'contactTechnicalAdvisor');
    },
    createPS_Case:function(component,event,helper)
    {
        helper.createCase(component,'contactTechnicalAdvisor');
    },
    callBackOnSuccess: function(component, event, helper)
    {
      //  window.location.reload(true);
         var sobjectId = component.get("v.CaseId");
    console.log(sobjectId);
    if (sobjectId.indexOf("500") >-1) { //Note 500 is prefix for Case Record
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/case/'+sobjectId,
            "isredirect" :false
        });
        urlEvent.fire();
    }
    }
})