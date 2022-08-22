({
    //MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    
    doInit : function (component, event) {
        
        let self = this;
        let countryValuesPromise = this.getCountryPickListValues (component, event);
        let PriorityValuesPromise = this.getPriorityPickListValues (component, event);
        let RelatedValuesPromise = this.getRelatedPickListValues (component, event);
        let EnvironmentValuesPromise = this.getEnvironmentPickListValues (component, event);
        let NumRobValuesPromise = this.getNumRobPickListValues (component, event);
        let StudioPickValuesPromise = this.getStudioPickListValues (component, event);
        let OrchestratorValuesPromise = this.getOrchestratorPickListValues (component, event);
        let countryCodePromise = this.getCountryCodePickListValues (component, event);
        let blackListDomainsPromis  = this.getBlackListDomains (component, event);
        let TimeZoneListPromis  = this.getTimeZoneList (component, event);
        let prodctcmpVersionPromise = this.getProductComponentVersionPickListValues (component, event); //SLTECH-6705
        //component.set("v.showLoadingSpinner", true);
        
        Promise.all ([countryValuesPromise, 
                      PriorityValuesPromise, 
                      countryCodePromise,                      
                      EnvironmentValuesPromise, 
                      NumRobValuesPromise,
                      StudioPickValuesPromise,
                      OrchestratorValuesPromise,
                      RelatedValuesPromise,
                      blackListDomainsPromis,
                      TimeZoneListPromis,
                      prodctcmpVersionPromise
                     ]).then ( 
            $A.getCallback (function (results) {
                component.set("v.showLoadingSpinner", false);
                if (results && results !== null && results !== undefined) {
                    component.set ('v.countryList', results[0]);
                    var priorityArray = [];
                    var priority = results[1];
                    for(var i = 0;i<results[1].length;i++){
                        if(results[1][i].value == "Medium"){
                            results[1][i].isSelected = true;
                        }
                        priorityArray.push(results[1][i]);
                    }
                    component.set ('v.priorityList', priorityArray);
                    var withoutPortal = [];
                    console.log('Sorted',results[6].sort());
                    for(var i = 0;i<results[7].length;i++){
                        if(results[7][i].value != 'Portal' && results[7][i].value != 'Cloud Platform' && results[7][i].value != 'Connect Enterprise' &&
                           results[7][i].value != 'UiPath Go'){
                            if(results[7][i].value.includes('&amp;')){
                                results[7][i].value = results[7][i].value.replace('&amp;','&');
                                results[7][i].label = results[7][i].label.replace('&amp;','&');
                            }
                            withoutPortal.push(results[7][i]);
                        }
                    }
                    withoutPortal.sort((a, b) => {
  						if (a.label < b.label) return -1
  						return a.label > b.label ? 1 : 0
					})
                    component.set ('v.relatedList', withoutPortal);
                    component.set ('v.environmentList', results[3]);
                    component.set ('v.numRobList', results[4]);
                    component.set ('v.studioList', results[5]);
                    component.set ('v.orchestratorList', results[6].sort());
                    component.set ('v.dependentMap', results[2]);
                    component.set ('v.blackListDomains', results[8]);
                    component.set ('v.TimeZoneList', results[9]);
                    component.set('v.dependentversionMap', results[10])
                    self.updateOnInit (component, event);
                    self.updateOnInitVersion(component, event);
                }       
            }), 
            $A.getCallback(function(error) {
                component.set("v.showLoadingSpinner", false);
                console.log ('Error :' + error);
            })
        );
        
        
        component.set ('v.legacyFormUrl', window.location.origin + '/' + $A.get("$Label.c.UI_Path_Legacy_Case_Page_Name"));
        this.setUpIframe (component, event);
        window.addEventListener("message", function(event) {
            console.log(event.data);
            if (event.origin !== window.location.origin ) {
                // Not the expected origin: Reject the message!
                return;
            } 
            if (event.data==="Unlock") {
                component.set ('v.isCapta', true);
                self.handleCheck (component);
            }
            
        }, false);   
    },
    handleCheck :function (component) {
        let isCapta = component.get ('v.isCapta');
        let IsAckSelected = component.get ('v.IsAckSelected');
        var isInValidLicenseCode = component.get('v.isInValidLicenseCode');
        let myButton = component.find ('myButton');
        console.log('mytton',myButton);
        console.log('v.capFrameHeight',component.get('v.capFrameHeight'));
        if (isCapta && IsAckSelected && !isInValidLicenseCode) {
            myButton.set('v.disabled', false);
        } else {
            myButton.set('v.disabled', true);
        } 
        
    },
    setUpIframe : function (component, event) {
        component.set('v.lcHost', window.location.hostname);
        let frameSrc = window.location.pathname + "UploadFilePage?"  + '&lcHost=' + component.get ('v.lcHost'); //id=+ component.get ('v.parentId')
        let captaSrc = window.location.pathname + "reCaptchaPage"; 
        component.set('v.frameSrc', frameSrc);
        component.set('v.captaSrc', captaSrc);
        let self = this;
        window.addEventListener("message", function(event) {
            
            if(event.data.state == 'LOADED'){
                component.set('v.vfHost', event.data.vfHost);
            }
            
            if(event.data.state == 'ONFILEOVERSIZE'){
                component.set ('v.isFileSelected', false);
                self.createModal (component, false, 'Error', event.data.message);
            }
            if(event.data.state == 'ONFILESELECTED'){
                component.set ('v.isFileSelected', true);
            }
            if(event.data.state == 'ONFILEDESELECTED'){
                component.set ('v.isFileSelected', false);
            }
            
            if(event.data.state == 'fileUploadprocessed'){
                component.set("v.showLoadingSpinner", false);
                if (event.data.messageType && event.data.messageType === 'success') {
                    self.createModal (component, true, 'Success', $A.get("$Label.c.Case_Success_Message"));
                } else {
                    self.createModal (component, true, 'Success', $A.get("$Label.c.Case_Error_File_Upload") );
                }
            }
        }, false);
    },
    
    
    updateOnInitVersion : function (component, event) {
        var depMap = component.get("v.dependentversionMap");
        var listOfkeys = [];
        var ControllerField = [];
        for (var singlekey in depMap) {
            listOfkeys.push(singlekey);
        }
        
        let item=component.get ('v.selectedRelated');
        if (item && item !== '--- None ---' ) {
            var ListOfDependentFields = depMap[item];
            component.set ('v.selectedversion', '');
            if(ListOfDependentFields.length > 0){
                // component.set("v.isDependentDisabled" , false);
                this.fetchVersionValues(component, ListOfDependentFields);
            }else{
                //  component.set("v.isDependentDisabled" , true); 
                component.set("v.versionList", ['--- None ---']);
            }
        }
    },
    updateOnInit : function (component, event) {
        var depMap = component.get("v.dependentMap");
        
        var listOfkeys = []; 
        var ControllerField = [];
        for (var singlekey in depMap) {
            if(singlekey != 'Ireland {Republic}')
                listOfkeys.push(singlekey);
        }
        //set the controller field value for lightning:select
        if (listOfkeys != undefined && listOfkeys.length > 0) {
            ControllerField.push('--- None ---');
            
            for (var i = 0; i < listOfkeys.length; i++) {
                ControllerField.push(listOfkeys[i]);
                
            }  
            component.set("v.country", ControllerField);
            component.set("v.isDependentDisabled" , false); 
        }
        
        let item=component.get ('v.selectedCountry');
        if (item && item !== '--- None ---' ) {
            var ListOfDependentFields = depMap[item];
            
            component.set ('v.selectedCountryCode', '');
            if(ListOfDependentFields.length > 0){
                component.set("v.isDependentDisabled" , false);  
                this.fetchCountryValues(component, ListOfDependentFields);    
            }else{
                component.set("v.isDependentDisabled" , true); 
                component.set("v.countryCode", ['--- None ---']);
            } 
        }
    },
    onControllerFieldChange: function(component, event, helper) {
        var controllerValueKey = event.getSource().get("v.value"); 
        var dependentFieldMap = component.get("v.dependentMap");
        
        if (controllerValueKey != '--- None ---') {
            var ListOfDependentFields = dependentFieldMap[controllerValueKey];
            
            component.set ('v.selectedCountryCode', '');
            if(ListOfDependentFields.length > 0){
                component.set("v.isDependentDisabled" , false);  
                component.set ('v.selectedCountryCode',''); 
                this.fetchCountryValues(component, ListOfDependentFields);    
            }else{
                component.set("v.isDependentDisabled" , true); 
                component.set("v.countryCode", ['--- None ---']);
            }              
        } else {
            component.set("v.countryCode", ['--- None ---']);
            component.set("v.isDependentDisabled" , true);
        }
        //component.set ('v.selectedCountryCode', null);
    },
    fetchCountryValues: function(component, ListOfDependentFields) {
        var dependentFields = [];
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            //dependentFields.push(ListOfDependentFields[i]);
            component.set ('v.selectedCountryCode', ListOfDependentFields[i]);
            break;
        }
        //console.log ('Test : ' + component.get ('v.selectedCountryCode'));
        //component.set("v.countryCode", dependentFields);
    },
    getCountryCodePickListValues : function (component, event) {
        let self = this;
        let params = {
            'objDetail' : component.get ('v.objDetail'),
            'contrfieldApiName': component.get ('v.contrfieldApiName'),
            'depfieldApiName': component.get ('v.depfieldApiName') 
        };
        
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.getCountryCodePickListValues');
            action.setParams (params)
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
    },
    getProductComponentVersionPickListValues : function (component, event) {
        let self = this;
        let params = {
            'objDetail' : component.get ('v.objDetail'),
            'contrfieldApiName': 'Related_To__c',
            'depfieldApiName': 'Product_Component_Version__c' 
        };
        
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.getCountryCodePickListValues');
            action.setParams (params)
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
    },
    
    
    
    
    validateEmail : function (email) {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(email).toLowerCase());
    }, 
    validateForm : function (component) {
        component.set ('v.errorMessage', $A.get ('$Label.c.Mandatory_error_msg'));
        let name = component.find ('caseContactName').get ('v.value').trim ();
        if (!name || name === undefined || name === null) {
            component.find ('caseContactName').setCustomValidity($A.get('$Label.c.J_Input_Name_Error'));
            component.find ('caseContactName').reportValidity ();
            return false;
        }else {
            component.find ('caseContactName').setCustomValidity("");
            component.find ('caseContactName').reportValidity ();
        }
        
        let email = component.find ('caseContactEmail').get ('v.value').trim ();
        if (!email || email === undefined || email === null) {
            component.find ('caseContactEmail').setCustomValidity($A.get('$Label.c.J_EmailError'));
            component.find ('caseContactEmail').reportValidity ();
            return false;
        }else {
            component.find ('caseContactEmail').setCustomValidity("");
            component.find ('caseContactEmail').reportValidity ();
        }
        
        if (this.validateEmail (email)) {
            component.find ('caseContactEmail').setCustomValidity("");
            component.find ('caseContactEmail').reportValidity ();
        } else {
            component.set ('v.errorMessage', 'Please enter a valid email');
            component.find ('caseContactEmail').setCustomValidity('Please enter a valid email');
            component.find ('caseContactEmail').reportValidity ();
            return false;
        }
        
        let casePhone = component.find ('casePhone').get ('v.value').trim ();
        if (!casePhone || casePhone === undefined || casePhone === null) {
            component.find ('casePhone').setCustomValidity($A.get('$Label.c.J_Phone_Error'));
            component.find ('casePhone').reportValidity ();
            return false;
        }else {
            component.find ('casePhone').setCustomValidity("");
            component.find ('casePhone').reportValidity ();
        }
        
        /*let caseEndCustomerName = component.find ('caseEndCustomerName').get ('v.value').trim ();
        if (!caseEndCustomerName || caseEndCustomerName === undefined || caseEndCustomerName === null) {
            component.find ('caseEndCustomerName').setCustomValidity($A.get('$Label.c.J_Organization_Error'));
            component.find ('caseEndCustomerName').reportValidity ();
            return false;
        }else {
            component.find ('caseEndCustomerName').setCustomValidity("");
            component.find ('caseEndCustomerName').reportValidity ();
        }*/
        
        let caseSubject = component.find ('caseSubject').get ('v.value').trim ();
        if (!caseSubject || caseSubject === undefined || caseSubject === null) {
            component.find ('caseSubject').setCustomValidity($A.get('$Label.c.J_SubjectError'));
            component.find ('caseSubject').reportValidity ();
            return false;
        }else {
            component.find ('caseSubject').setCustomValidity("");
            component.find ('caseSubject').reportValidity ();
        }
        
        //SLTECH-9023
        if(component.get('v.selectedEnvironment') == 'Production' && component.get('v.selectedPriority') == 'Urgent'){
            let workaround = component.find ('wrklabel').get ('v.value').trim ();
            if (!workaround || workaround === undefined || workaround === null) {
                component.find ('wrklabel').set('v.validity','{valid:false, badInput :true}');
                component.find ('wrklabel').showHelpMessageIfInvalid();
                component.find ('wrklabel').focus ();
                return false;
            }
            
            let businessaffcted = component.find ('businessaffected').get ('v.value');
            if(businessaffcted) 
                businessaffcted= businessaffcted.trim ();
            
            if (!businessaffcted || businessaffcted === undefined || businessaffcted === null) {
                component.find ('businessaffected').set('v.validity','{valid:false, badInput :true}');
                component.find ('businessaffected').showHelpMessageIfInvalid();
                component.find ('businessaffected').focus ();
                return false;
            }
            
            let intermittentissue = component.find ('intermittentissues').get ('v.value');
            if(intermittentissue) 
                intermittentissue= intermittentissue.trim ();
            
            if (!intermittentissue || intermittentissue === undefined || intermittentissue === null) {
                component.find ('intermittentissues').set('v.validity','{valid:false, badInput :true}');
                component.find ('intermittentissues').showHelpMessageIfInvalid();
                component.find ('intermittentissues').focus ();
                return false;
            }
            
        }
        
        
        
        let selectedCountry = component.find ('countryPickList').get ('v.value').trim ();
        if ( (selectedCountry && selectedCountry === '--- None ---') || selectedCountry === undefined || selectedCountry === null ) {
            component.find ('countryPickList').set('v.validity','{valid:false, badInput :true}');
            component.find ('countryPickList').showHelpMessageIfInvalid();
            component.find ('countryPickList').focus ();
            return false;
        }
        
        let relatedName = component.find ('relatedName').get ('v.value').trim ();
        if (!relatedName || relatedName === undefined || relatedName === null) {
            component.find ('relatedName').set('v.validity','{valid:false, badInput :true}');
            component.find ('relatedName').showHelpMessageIfInvalid();
            component.find ('relatedName').focus ();
            return false;
        }
        let environmentName = component.find ('environmentName').get ('v.value').trim ();
        if (!environmentName || environmentName === undefined || environmentName === null) {
            component.find ('environmentName').set('v.validity','{valid:false, badInput :true}');
            component.find ('environmentName').showHelpMessageIfInvalid();
            component.find ('environmentName').focus ();
            return false;
        }
        
        let priority = component.find ('priority').get ('v.value').trim ();
        if (!priority || priority === undefined || priority === null) {
            component.find ('priority').set('v.validity','{valid:false, badInput :true}');
            component.find ('priority').showHelpMessageIfInvalid();
            component.find ('priority').focus ();
            return false;
        }
        
        //SLECH-7311
        if(component.get('v.showNoOfRobots')){
            let NumRobryListName = component.find ('NumRobryListName').get ('v.value').trim ();
            if (!NumRobryListName || NumRobryListName === undefined || NumRobryListName === null) {
                component.find ('NumRobryListName').set('v.validity','{valid:false, badInput :true}');
                component.find ('NumRobryListName').showHelpMessageIfInvalid();
                component.find ('NumRobryListName').focus ();
                return false;
            }
        }
        
        if(component.get('v.showStudioVersion')){
            let studioListName = component.find ('studioListName').get ('v.value').trim ();
            if (!studioListName || studioListName === undefined || studioListName === null) {
                component.find ('studioListName').set('v.validity','{valid:false, badInput :true}');
                component.find ('studioListName').showHelpMessageIfInvalid();
                component.find ('studioListName').focus ();
                return false;
            }
        }
        
        if(component.get('v.showOrchesVersion')){
            let orchestratorListId = component.find ('orchestratorListId').get ('v.value').trim ().trim ().trim ();
            if (!orchestratorListId || orchestratorListId === undefined || orchestratorListId === null) {
                component.find ('orchestratorListId').set('v.validity','{valid:false, badInput :true}');
                component.find ('orchestratorListId').showHelpMessageIfInvalid();
                component.find ('orchestratorListId').focus ();
                return false;
            }
        }
        
        if(component.get('v.showProductVersion')){
            let versionListName = component.find ('versionListId').get ('v.value').trim ();
            if ((!versionListName || versionListName === undefined || versionListName === null )) {
                component.find ('versionListId').set('v.validity','{valid:false, badInput :true}');
                component.find ('versionListId').showHelpMessageIfInvalid();
                component.find ('versionListId').focus ();
                return false;
            }
        }
        
        let caseDescription = component.find ('caseDescription').get ('v.value');
        if (caseDescription) {
            caseDescription = caseDescription.trim ();
        }
        if (!caseDescription || caseDescription === undefined || caseDescription === null) {
            component.find ('caseDescription').setCustomValidity("Please fill Description.");
            component.find ('caseDescription').reportValidity ();
            return false;
        }else {
            component.find ('caseDescription').setCustomValidity("");
            component.find ('caseDescription').reportValidity ();
        }
        
        /*   let caseDevice = component.find ('caseDevice').get ('v.value').trim ();
        if (!caseDevice || caseDevice === undefined || caseDevice === null) {
            component.find ('caseDevice').setCustomValidity("Please fill Device Id.");
            component.find ('caseDevice').reportValidity ();
            return false;
        }else {
            component.find ('caseDevice').setCustomValidity("");
            component.find ('caseDevice').reportValidity ();
        }*/
        
        let licenseValidity = component.find('licenceCodeCmp').validateInput();
        if(!licenseValidity){
            return false;
        }
        
        /* let caseLicence = component.find ('caseLicence').get ('v.value').trim ();
        if (!caseLicence || caseLicence === undefined || caseLicence === null) {
            component.find ('caseLicence').setCustomValidity("Please fill License Code.");
            component.find ('caseLicence').reportValidity ();
            return false;
        }else {
            component.find ('caseLicence').setCustomValidity("");
            component.find ('caseLicence').reportValidity ();
        }*/
        return true;
    },
    
    validateBlackListDomains : function (component) {
        let blackListDomains  = component.get ('v.blackListDomains');
        let email = component.find ('caseContactEmail').get ('v.value');
        if (blackListDomains && blackListDomains.length > 0 && email) {
            let domainName = email.substring(email.indexOf ('@') + 1, email.lastIndexOf('.') );
            for (let index = 0; index < blackListDomains.length; index++) {
                if (domainName && domainName.toLowerCase () === (blackListDomains[index].MasterLabel.toLowerCase ())) {
                    component.set ('v.errorMessage', $A.get ('$Label.c.Official_Error_Msg'));
                    component.find ('caseContactEmail').focus();
                    return false;
                }
            }
        }
        return true;
    },
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
                        }
                        
                        
                        
                        //alert(JSON.stringify(resMap));
                    } else {
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
                    self.createModal (component, false, "Error", $A.get("$Label.c.Error_Validating_LicenseCode"));
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
    },
    handleSubmitClick: function(component, event) {
        
        let self = this;
        
        if (this.validateForm (component) && this.validateBlackListDomains (component)) {
            
            let caseObj = {'Status' : 'New', 
                           'Origin' : 'Web',
                           'SuppliedName' : component.find ('caseContactName').get ('v.value'),
                           'SuppliedEmail' : component.find ('caseContactEmail').get ('v.value'),
                           'End_Customer_s_Name__c' : component.get("v.endCustomerName"),
                           'SuppliedPhone' :  component.get ('v.selectedCountryCode') + component.find ('casePhone').get ('v.value'),
                           'Subject': component.find ('caseSubject').get ('v.value'),
                           'Description' : component.find ('caseDescription').get ('v.value'),
                           'Error_Message__c' : component.find ('caseErrMsg').get ('v.value'),
                           /* 'Device_Id__c' : component.find ('caseDevice').get ('v.value'),*/
                           'License_Code__c' : component.get("v.licenseCode"),
                           'Country__c' : component.get ('v.selectedCountry'),
                           'Time_Zone__c' : component.get ('v.selectedTimeZone'),
                           'Related_To__c' : component.get ('v.selectedRelated'), 
                           'Priority' :component.get ('v.selectedPriority'), 
                           'Environment_Of_Issue__c' : component.get ('v.selectedEnvironment'), 
                           'No_Of_Robots_Impacted_By_Issue__c' : component.get ('v.selectedNumRob'), 
                           'Studio_Version__c' : component.get ('v.selectedStudio'), 
                           'Orchestrator_Version__c' : component.get ('v.selectedOrches'), 
                           'Webform_Acknowledgement__c': component.find('caseAcknowledge').get('v.checked'),
                           'Case_Source_Link__c' : window.location.href,
                           'AccountId' : component.get('v.resMapAccountId'), 
                           //'AccountId' : '0017j00000WC2RtAAL',
                           'Subscription_Type__c': component.get('v.SubscriptionType'),
                           'Subscription_Code__c': component.get('v.SubscriptionCode'),
                           'Bundle_Name__c': component.get('v.bundleName'),
                           'Product_Component_Version__c' : component.get('v.selectedversion'),
                           'Is_the_business_affected__c' : (component.get('v.selectedEnvironment') == 'Production' && component.get('v.selectedPriority') == 'Urgent') ? component.find ('businessaffected').get('v.value') : '',
                           'Workaround_in_place__c' : component.get('v.wrkVal'),
                           'Intermittent_issues__c' : (component.get('v.selectedEnvironment') == 'Production' && component.get('v.selectedPriority') == 'Urgent') ? component.find ('intermittentissues').get('v.value') : ''
                           
                          };
            if(component.get('v.endDate')){
                caseObj.License_End_Date__c = component.get('v.endDate');
            }
            else{
                let duration = component.get('v.duration');
                let startDate = new Date(component.get('v.createdDateTime'));
                let endDate = new Date();
                endDate.setDate(startDate.getDate() + parseInt(duration));
                let endDateFormatted = endDate.getFullYear()+'-'+(endDate.getMonth()+1)+'-'+endDate.getDate();
                if(endDate)
                    caseObj.License_End_Date__c = endDateFormatted;
            }
            if(component.get('v.SubscriptionCode')==='TRIAL'){
               // caseObj.AccountId = component.get('v.resMapAccountId') ? '0017j00000WC2RtAAL' : '';
                caseObj.AccountId = component.get('v.resMapAccountId') ? component.get('v.resMapAccountId') : '';
                caseObj.ContactId = '';
                caseObj.RecordTypeId = $A.get("$Label.c.ServiceRequestRecordTypeId");
                /*let duration = component.get('v.duration');
                let startDate = new Date(component.get('v.createdDateTime'));
                let endDate = new Date();
                endDate.setDate(startDate.getDate() + parseInt(duration));
                let endDateFormatted = endDate.getFullYear()+'-'+(endDate.getMonth()+1)+'-'+endDate.getDate();
                caseObj.License_End_Date__c = endDateFormatted;*/
                
            }else{
                caseObj.RecordTypeId = $A.get("$Label.c.WebtoCaseRecordTypeId");
                //caseObj.License_End_Date__c = component.get('v.endDate');
            }
            
            
            let params = {'caseString' : JSON.stringify (caseObj)};
            component.set("v.showLoadingSpinner", true);
            self.createCase (component, params).then (
                $A.getCallback (function (result) {
                    component.set("v.showLoadingSpinner", false);
                    if (result && result !== null && result !== undefined && result.Id && result.Id !== null && result.Id !== undefined) {
                        component.set ('v.parentId', result.Id);
                        if (component.get ('v.isFileSelected') 
                            && component.get ('v.isFileSelected') === true) {
                            var message = {
                                "uploadFile" : true,
                                "parentId" : result.Id
                            };
                            self.sendMessage(component, message);
                            component.set("v.showLoadingSpinner", true);
                        } else {
                            self.onCaseSuccess (component)    
                        }
                    } else {
                        self.createModal (component, false, "Error", $A.get("$Label.c.Error_Case_Creation_Msg"));
                    }
                }),
                $A.getCallback (function (error) {
                    component.set("v.showLoadingSpinner", false);
                    self.createModal (component, false, "Error", $A.get("$Label.c.Error_Case_Creation_Msg"));
                })
            );
            
            
            /*component.set("v.showLoadingSpinner", true);
            this.validateLicenseCode (component, caseObj.License_Code__c, caseObj.End_Customer_s_Name__c).then (
                $A.getCallback (function (result) {
                    component.set("v.showLoadingSpinner", false);
                    let resMap = JSON.parse(result);
                    if (result &&  result !== undefined && result !== null && resMap.status && resMap.status === 'SUCCESS') {

                    } else {
                        self.createModal (component, false, "Error", ( (resMap.message && resMap.message !== undefined && resMap.message !== null ) 
                                                                        ? resMap.message 
                                                                        : $A.get("$Label.c.Error_Validating_LicenseCode")) 
                                        );
                    }
                }),
                $A.getCallback (function (error) {
                    component.set("v.showLoadingSpinner", false);
                    console.log (error);
                    self.createModal (component, false, "Error", $A.get("$Label.c.Error_Validating_LicenseCode"));
                })
            );*/
        } else {
            var scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
            self.createModal (component, false, "Error", component.get ('v.errorMessage'));
        }     
    },
    
    getCountryPickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.getCountryPickListValues');
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
    },
    getPriorityPickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.getPriorityPickListValues');
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
    },
    
    getRelatedPickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            let action = component.get ('c.getRelatedPickListByRecordTypeId');
            action.setParams ({
                'recordTypeId' : $A.get("$Label.c.WebtoCaseRecordTypeId")
            });
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
    },
    
    getEnvironmentPickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.getEnvironmentPickListValues');
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
    },
    
    getNumRobPickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.getNumRobPickListValues');
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
    },
    
    
    getTimeZoneList : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            let action = component.get ('c.getTimeZoneList');
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
    },
    
    getStudioPickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            let action = component.get ('c.getStudioPickListValues');
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
    },
    getOrchestratorPickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            let action = component.get ('c.getOrchestratorPickListValues');
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
    },
    createCase : function (component, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get ('c.saveCaseCreateContact');
            if (params) {
                action.setParams (params);
            }  
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (state === "INCOMPLETE") {
                    //todo
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
    },
    onCaseSuccess : function (component) {
        component.set("v.showLoadingSpinner", false);
        this.createModal (component, true, "Success", $A.get("$Label.c.Case_Success_Message"));
    },
    createModal : function (component, isSuccess, title, description) {
        component.set ('v.modalTitle', title);
        component.set ('v.isSuccess', isSuccess);
        component.set ('v.errorMessage', description);
        component.find ('alertModal').show ();
    },
    getBlackListDomains : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.getBlackListDomains');
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else if (state === "INCOMPLETE") {
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
    },
    sendMessage: function(component, message){
        message.origin = window.location.hostname;
        var vfWindow = component.find("vfFrame").getElement().contentWindow;
        vfWindow.postMessage(message, component.get("v.vfHost"));
    },
    
    //SLTECH-6705
    handleProductChange : function(component, event){
        var controllerValueKey = event.getSource().get("v.value");
        if(controllerValueKey =='Process Gold')
            controllerValueKey = 'Process Mining';
        
        if(controllerValueKey =='Action Center')
            controllerValueKey = 'Apps';
        
        if(controllerValueKey =='UiPath Assistant')
            controllerValueKey = 'Agent Desktop';
        
        if ( controllerValueKey == 'AI Fabric' )
            controllerValueKey = 'AI Center';
        
        if ( controllerValueKey == 'UiPath Insights' )
            controllerValueKey = 'Insights';
        
        var showStudAndOrchArray =  $A.get("$Label.c.ProdCMPShowStudAndOrc").split(',');
        var showOrchArray = $A.get("$Label.c.ProdCMPShowOrch").split(',');
        var showProdCmpArray = $A.get("$Label.c.ProdCMPShowProdVersion").split(',');
        var showProdVerAndOrchArray = $A.get("$Label.c.ProdCMPShowPrdVerAndOrch").split(',');
        var showAllArray = $A.get("$Label.c.ProdCMPShowAll").split(',');
        var showProdCMPShowStudAndProVersion = $A.get("$Label.c.ProdCMPShowStudAndProVersion").split(',');
        var showProdCMPShowStudio = $A.get("$Label.c.ProdCMPShowStudio").split(',');
        var hideNoOfRobotsArray = $A.get("$Label.c.hideNoOfRobotsArray").split(',');
        
        
        var dependentFieldMap = component.get("v.dependentversionMap");
        
        if (controllerValueKey != '--- None ---') {
            
            var ListOfDependentFields = dependentFieldMap[controllerValueKey=='Apps' ? 'Action Center' : controllerValueKey == 'Agent Desktop' ? 'UiPath Assistant' : controllerValueKey];
            component.set ('v.selectedversion', '');
            if(ListOfDependentFields != undefined && ListOfDependentFields.length > 0 ){
                component.set ('v.selectedversion',''); 
                this.fetchVersionValues(component, ListOfDependentFields);    
            }else{
                var dependentFields = [];
                let obj = {};
                obj.label = '--None--';
                obj.value= '';
                dependentFields.push(obj);
                component.set("v.versionList", dependentFields);
            }
        } else {
            component.set("v.versionList", ['--- None ---']);
        }
        
        
        if(controllerValueKey ==''){
            component.set('v.showStudioVersion',false);
            component.set('v.showOrchesVersion',false);
            component.set('v.showProductVersion',false);
            component.set ('v.selectedversion','');
        }else if(showStudAndOrchArray.includes(controllerValueKey)){
            component.set('v.showStudioVersion',true);
            component.set('v.showOrchesVersion',true);
            component.set('v.showProductVersion',false);
            component.set ('v.selectedversion','');
            
        }else if(showOrchArray.includes(controllerValueKey)){
            component.set('v.showOrchesVersion',true);
            component.set('v.showStudioVersion',false);
            component.set('v.showProductVersion',false);
            component.set ('v.selectedversion','');
            component.set ('v.selectedStudio','');            
        }else if(showProdCmpArray.includes(controllerValueKey)){
            component.set('v.showOrchesVersion',false);
            component.set('v.showStudioVersion',false);
            component.set('v.showProductVersion',true);
            component.set ('v.selectedStudio',''); 
            component.set ('v.selectedOrches','');
            
        }else if(showProdVerAndOrchArray.includes(controllerValueKey)){
            component.set('v.showProductVersion',true);
            component.set('v.showOrchesVersion',true);
            component.set('v.showStudioVersion',false);
            component.set ('v.selectedStudio',''); 
        }else if(showAllArray.includes(controllerValueKey)){
            component.set('v.showOrchesVersion',true);
            component.set('v.showStudioVersion',true);
            component.set('v.showProductVersion',true);
        }else if(showProdCMPShowStudAndProVersion.includes(controllerValueKey)){
            component.set('v.showOrchesVersion',false);
            component.set('v.showStudioVersion',true);
            component.set('v.showProductVersion',true);
            component.set ('v.selectedOrches','');       
        }else if(showProdCMPShowStudio.includes(controllerValueKey)){
            component.set('v.showOrchesVersion',false);
            component.set('v.showStudioVersion',true);
            component.set('v.showProductVersion',false);
            component.set ('v.selectedversion','');
            component.set ('v.selectedOrches','');
            
        }
            else{
                component.set('v.showOrchesVersion',false);
                component.set('v.showStudioVersion',false);
                component.set('v.showProductVersion',false);
                component.set ('v.selectedStudio',''); 
                component.set ('v.selectedOrches','');
                component.set ('v.selectedversion','');
            }
        //SLTECH-7311
        if(hideNoOfRobotsArray.includes(controllerValueKey)){
            component.set('v.showNoOfRobots',false);
            component.set ('v.selectedNumRob','');
        }else{
            component.set('v.showNoOfRobots',true);
        }
        
    },
    
    fetchVersionValues :function (component, ListOfDependentFields) {
        var dependentFields = [];
        let obj = {};
        obj.label = '--None--';
        obj.value= '';
        dependentFields.push(obj);
        
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            let obj = {};
            obj.label = ListOfDependentFields[i];
            obj.value= ListOfDependentFields[i];
            dependentFields.push(obj);
            //dependentFields.push(ListOfDependentFields[i]);
        }
        
        
        
        if (dependentFields && dependentFields.length > 0) {
            component.set ('v.selectedversion', dependentFields [0].value);
        } else {
            component.set ('v.selectedversion', '');
        }
        component.set("v.versionList", dependentFields);
    },
    
    
    
    
    
    
    
    
    
})