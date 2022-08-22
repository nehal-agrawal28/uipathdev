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
                       'Requester_s_Company_Name__c' : '',
                       'ContactEmail' : '',
                       'Subject': '',
                       'Description' : '',
                       'Steps_To_Reproduce_The_Issue__c' : '',
                       'Expected_Result__c' : '',
                       'Actual_Result__c' : '',
                       'Frequency__c' : '',
                       'Workaround__c' : '',
                       'What_You_Want_Us_To_Do__c' : '',
                       'Error_Message__c' : '',
                       'License_Code__c' : '',
                       'Webform_Acknowledgement__c':false
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
      helper.handleCheck(component);
    },
    onblurEvent:function(component,event,helper)
    {
         var value = component.find("caseLicence").get("v.value");
        if((component.find ('relatedName').get("v.value")!='Academy' && value!="")|| (component.find ('relatedName').get("v.value")=='Academy' && value==""))
        {
          component.find ('caseLicence').setCustomValidity("");   
        }
        
         component.find ('caseLicence').reportValidity ();
    /*console.log(validity.valid); //returns true
        //var value=component.get("v.value");
       //component.find ('caseLicence').checkValidity();
        if(validity.valid == true)
        {
            component.find ('caseLicence').setCustomValidity(""); 
        }*/
    }
})