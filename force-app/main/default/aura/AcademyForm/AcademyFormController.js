({
    handleSubmitClick : function(component, event, helper) {
        helper.handleSubmitClick(component, event);
    },
    doInit : function (component, event, helper) {
        let caseObj = {'Status' : 'New', 
                       'Origin' : 'Web',
                       'SuppliedName' : '',
                       'End_Customer_s_Name__c' : '',
                       'ContactEmail' : '',
                       'Subject': '',
                       'Description' : '',
                       'Error_Message__c' : '',
                       'Device_Id__c' : '',
                       'License_Code__c' : '',
                       'Webform_Acknowledgement__c':false,
                       'Country__c' : ''
                      };
        component.set ('v.caseObj', caseObj);
        
        helper.doInit (component, event);
    },
    onControllerFieldChange: function(component, event, helper) {     
        helper.onControllerFieldChange (component, event);
    },
    onScriptLoaded : function (component, event, helper) {
        console.log ('Scripts loaded');
    },
    checkIsNumber : function (component, event, helper) {
        
        let val = component.find ('casePhone').get ('v.value');
        if (val && val !== undefined && isNaN(val)) {
            val = val.substring (0, (val.length-1));
            console.log (component.find ('casePhone').set ('v.value', val));    
        }
    },
    callBackOnSuccess : function (component, event, helper) {
        window.location.reload(true);
    },
    handleCheck: function(component, event, helper){ 
    helper.handleCheck (component);       
    },
    
    showMessage: function (component, event, helper)
   {
       var currentvalue = component.find("Job_Level__c").get("v.value");
       if(currentvalue == "Customer" || currentvalue == "Partner")
           component.set("v.showEmailMessage",true);
       else
           component.set("v.showEmailMessage",false);
   }
})