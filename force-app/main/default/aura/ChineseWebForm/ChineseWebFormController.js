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
                       'Webform_Acknowledgement__c':false
                   };
        console.log('Check'+component.get("v.IsAckSelected"));
        component.set ('v.caseObj', caseObj);
        console.log('Check2'+component.get("v.IsAckSelected"));
        helper.doInit (component, event);
         console.log('Check5'+component.get("v.IsAckSelected"));
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
    onEnvironmentChange : function (component, event, helper) {
        let val = event.getSource().get('v.value');
        let priorityList = component.get ('v.priorityList');
        if (val && val !== undefined && val !== null) {
            if (val === 'Production') {
                priorityList.forEach (function (val) {
                    if (val.value === 'Urgent') {
                        val.disabled = false;
                    }
                });
            } else {
                priorityList.forEach (function (val) {
                    if (val.value === 'Urgent') {
                        val.disabled = true;
                    } 
                }); 
                let selectedPriority  = component.get ('v.selectedPriority');
                if (selectedPriority && selectedPriority !== undefined && selectedPriority !== null && selectedPriority ==='Urgent') {
                	component.set ('v.selectedPriority', '');
                    component.find ('priority').focus ();
                }
            }
            component.set ('v.priorityList', priorityList);
        }        
    },
    callBackOnSuccess : function (component, event, helper) {
        window.location.reload(true);
    },
    checkValidLicenseCode : function (component, event, helper) {
        helper.checkValidLicenseCode (component, event, helper);
    },
    checkLicenseCodeUpdated : function (component, event, helper) {
        let val = component.find ('caseLicence').get ('v.value');
        let isInValidLicenseCode = component.get ('v.isInValidLicenseCode');
        if (isInValidLicenseCode === false) {
            component.set ('v.isInValidLicenseCode', true);
            component.find ('caseEndCustomerName').set ('v.value', '');
        }

    },
    openPopup : function (component, event, helper)  {
        helper.createModal (component, false, 'Note', $A.get ('$Label.c.License_Code_Help_text'));
    } ,
    handleCheck: function(component, event, helper){
        helper.handleCheck (component);       

    }
})