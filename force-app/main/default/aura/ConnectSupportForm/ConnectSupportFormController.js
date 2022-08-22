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
    
})