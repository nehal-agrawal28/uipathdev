({
    handleSubmitClick : function(component, event, helper) {
        helper.handleSubmitClick(component, event);
    },
    doInit : function (component, event, helper) {
        let acknowledgement = $A.get("$Label.c.Webform_Acknowledgement");
        console.log('acknowledgement',acknowledgement);
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
                       'Subscription_ID__c' : '',
                       'Webform_Acknowledgement__c':false
                      };
        component.set ('v.caseObj', caseObj);
        
        helper.doInit (component, event);
    },

    onScriptLoaded : function (component, event, helper) {
        console.log ('Scripts loaded');
    },
	
    callBackOnSuccess : function (component, event, helper) {
        window.location.reload(true);
    },
    handleCheck: function(component, event, helper){ 
    helper.handleCheck (component);       
    },
    onControllerFieldChange: function(component, event, helper) {     
    	helper.onControllerFieldChange (component, event, helper);
    },
    checkIsNumber : function (component, event, helper) {

        let val = component.find ('casePhone').get ('v.value');
        if (val && val !== undefined && isNaN(val)) {
            val = val.substring (0, (val.length-1));
            console.log (component.find ('casePhone').set ('v.value', val));
        }
    }
})