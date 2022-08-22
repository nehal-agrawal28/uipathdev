({
    checkValidLicenseCode : function (component, event, helper) {
        helper.checkValidLicenseCode (component, event, helper);
    },
    closeModal : function(component, event, helper){
        window.location.reload(true);
    },
    validateInput : function(component, event, helper){
        let caseLicence = component.find ('caseLicence').get ('v.value');
        if (!caseLicence || caseLicence === undefined || caseLicence === null) {
            component.find ('caseLicence').setCustomValidity("Please fill License Code.");
            component.find ('caseLicence').reportValidity ();
            return false;
        }else {
            component.find ('caseLicence').setCustomValidity("");
            component.find ('caseLicence').reportValidity ();
        }
        
        if(component.get("v.SubscriptionCode") != "TRIAL"){
            let caseEndCustomerName = component.find ('caseEndCustomerName').get ('v.value');
            if (!caseEndCustomerName || caseEndCustomerName === undefined || caseEndCustomerName === null) {
                component.find ('caseEndCustomerName').setCustomValidity($A.get('$Label.c.J_Organization_Error'));
                component.find ('caseEndCustomerName').reportValidity ();
                return false;
            }else {
                component.find ('caseEndCustomerName').setCustomValidity("");
                component.find ('caseEndCustomerName').reportValidity ();
            }
        }
        
        return true;
    },
    checkLicenseCodeUpdated : function (component, event, helper) {
        //let val = component.find ('caseLicence').get ('v.value');
        //let isInValidLicenseCode = component.get ('v.isInValidLicenseCode');
        component.set('v.showEndCustomerName',true);
        component.set ('v.isInValidLicenseCode', true);
        component.find ('caseEndCustomerName').set ('v.value', '');
       /* if (isInValidLicenseCode === false) {
            component.set ('v.isInValidLicenseCode', true);
            component.find ('caseEndCustomerName').set ('v.value', '');
            component.set('v.showEndCustomerName',true);
        }*/
        
    }
})