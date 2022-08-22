({
    checkValidLicenseCode : function (component, event) {
        let self = this;
        let caseLicence = component.find ('caseLicence').get ('v.value');
        if (!caseLicence || caseLicence === undefined || caseLicence === null) {
            component.find ('caseLicence').setCustomValidity("Please fill License Code.");
            component.find ('caseLicence').reportValidity ();
            return false;
        }else {
            component.find ('caseLicence').setCustomValidity("");
            component.find ('caseLicence').reportValidity ();
            component.set ('v.isInValidLicenseCode', true);
            component.set("v.showLoadingSpinner", true);
            this.validateLicenseCode (component, caseLicence).then (
                $A.getCallback (function (result) {
                    component.set("v.showLoadingSpinner", false);
                    let resMap = JSON.parse(result);
                    if (result &&  result !== undefined && result !== null && resMap.status && resMap.status === 'SUCCESS') {
                        if(resMap.subscriptionCode && $A.get("$Label.c.Restricted_License_Subscription_Codes").includes(resMap.subscriptionCode)){
                            component.set("v.restrictedSubCode",true);
                        }else{
                            component.set ('v.isInValidLicenseCode', false);
                            component.find ('caseEndCustomerName').set ('v.value', resMap.name);
                            component.set('v.resMapAccountId',resMap.accountId);//Maanas
                            component.set('v.SubscriptionType',resMap.caseType);
                            component.set('v.SubscriptionCode',resMap.subscriptionCode);
                            component.set('v.endDate',resMap.endDate);
                            component.set('v.duration',resMap.duration);
                            component.set('v.createdDateTime',resMap.createdDateTime);
                            component.set('v.bundleName',resMap.bundleName ? resMap.bundleName : '');
                            if(resMap.subscriptionCode==="TRIAL" && !resMap.name){
                                component.set('v.showEndCustomerName',false);
                            }
                        }
                    } else {
                        component.set ('v.isInValidLicenseCode', true);
                        component.find ('caseLicence').setCustomValidity(( (resMap.message && resMap.message !== undefined && resMap.message !== null ) 
                                                                          ? resMap.message 
                                                                          : $A.get("$Label.c.Error_Validating_LicenseCode")));
                        component.find ('caseLicence').reportValidity ();
                    }
                }),
                $A.getCallback (function (error) {
                    component.set ('v.isInValidLicenseCode', true);
                    component.set("v.showLoadingSpinner", false);
                    console.log (error);
                    component.find ('caseLicence').setCustomValidity(( (resMap.message && resMap.message !== undefined && resMap.message !== null ) 
                                                                      ? resMap.message 
                                                                      : $A.get("$Label.c.Error_Validating_LicenseCode")));
                    component.find ('caseLicence').reportValidity ();
                })
            );
        }
    },
    validateLicenseCode : function (component, licenseCode) {
        
        let self = this;
        let params = {
            'licenseCode' : licenseCode
        };
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.validateLicenseCode');
            action.setParams (params);
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (state === "INCOMPLETE") {
                    //todo
                    reject('Incomplete');
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    }
})