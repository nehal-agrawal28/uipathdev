({
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
        let productRecordPromise = this.getproductRecordTypes (component, event);
        let blackListDomainsPromise = this.getBlackListDomains (component, event);


        //component.set("v.showLoadingSpinner", true);
        Promise.all ([countryValuesPromise, 
                      PriorityValuesPromise, 
                      RelatedValuesPromise, 
                      EnvironmentValuesPromise, 
                      NumRobValuesPromise,
                      StudioPickValuesPromise,
                      OrchestratorValuesPromise,
                      countryCodePromise,
                      productRecordPromise,
                      blackListDomainsPromise
                     ]).then ( 
            $A.getCallback (function (results) {
                component.set("v.showLoadingSpinner", false);
                if (results && results !== null && results !== undefined) {
                    component.set ('v.countryList', results[0]);
                    component.set ('v.priorityList', results[1]);
                    component.set ('v.relatedList', results[2]);
                    component.set ('v.environmentList', results[3]);
                    component.set ('v.numRobList', results[4]);
                    component.set ('v.studioList', results[5]);
                    component.set ('v.orchestratorList', results[6]);
                    component.set ('v.dependentMap', results[7]);
                    component.set ('v.productRecordTypes', results[8]);
                    component.set ('v.blackListDomains', results[9]);

                    self.updateOnInit (component, event);
                    console.log(JSON.stringify(component.get ('v.relatedList')));
                }       
            }), 
            $A.getCallback(function(error) {
                component.set("v.showLoadingSpinner", false);
                console.log ('Error :' + error);
            })
        );
        this.setUpIframe (component, event);
        window.addEventListener("message", function(event) {
            console.log(event.data);
            if (event.origin !== window.location.origin ) {
                // Not the expected origin: Reject the message!
                return;
            } 
            if (event.data==="Unlock") {
                component.set ('v.isCapta', true);
                component.set('v.capFrameHeight','100');               
                self.handleCheck(component);
            }
            
        }, false);   
    },
    handleCheck :function (component) {
        let isCapta = component.get ('v.isCapta');
        let IsAckSelected = component.get ('v.IsAckSelected');
        let isBtnDisabled = component.get('v.isBtnDisabled');
        let myButton = component.find ('myButton');
        if (isCapta && IsAckSelected && !isBtnDisabled) {
            myButton.set('v.disabled', false);
        } else {
            myButton.set('v.disabled', true);
        } 

    },
    setUpIframe : function (component, event) {
        component.set('v.lcHost', window.location.hostname);
        let path = window.location.pathname[window.location.pathname.length - 1] === '/' ? window.location.pathname : window.location.pathname + '/';
        let frameSrc = path + "UploadFilePage?"  + '&lcHost=' + component.get ('v.lcHost'); //id=+ component.get ('v.parentId')
        let captaSrc = window.location.pathname + "reCaptchaPage"; 
        component.set('v.frameSrc', frameSrc);
        component.set('v.captaSrc', captaSrc);
        let self = this;
        window.addEventListener("message", function(event) {

            if(event.data.state == 'LOADED'){
                component.set('v.vfHost', event.data.vfHost);
            }

            if(event.data.state == 'ONFILEOVERSIZE'){
                debugger;
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
    validateEmail : function (email) {
       var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(email).toLowerCase());
    },
    updateOnInit : function (component, event) {
        var depMap = component.get("v.dependentMap");
        
        var listOfkeys = []; 
        var ControllerField = [];
        for (var singlekey in depMap) {
            listOfkeys.push(singlekey);
        }
        //set the controller field value for lightning:select
        if (listOfkeys != undefined && listOfkeys.length > 0) {
            ControllerField.push('--- None ---');
            
                for (var i = 0; i < listOfkeys.length; i++) {
                    let val = {};
                    val.value = listOfkeys[i];
                    val.isSelected =  (val.value === 'Japan') ? true : false;
                    ControllerField.push (val);
                }  
            component.set("v.country", ControllerField);
            component.set("v.isDependentDisabled" , false); 
        }
        
        
        component.set ('v.selectedCountry', 'Japan');
        
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
        
        window.setTimeout(
            $A.getCallback( function() {
                component.find ('countryPickList').set ('v.value', 'Japan');
            })
        );
    },
    onControllerFieldChange: function(component, event, helper) {
		var controllerValueKey = event.getSource().get("v.value"); 
        var dependentFieldMap = component.get("v.dependentMap");
        
        if (controllerValueKey && controllerValueKey != '--- None ---') {
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
    validateEmail : function (email) {
       var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(email).toLowerCase());
    },
    validateForm : function (component) {
        component.set ('v.errorMessage', $A.get ('$Label.c.Mandatory_error_msg'));
        let lastName = component.find ('caseContactLastName').get ('v.value').trim ();
        if (!lastName || lastName === undefined || lastName === null) {
            component.find ('caseContactLastName').setCustomValidity($A.get('$Label.c.J_Input_Name_Error'));
            component.find ('caseContactLastName').reportValidity ();
            return false;
        }else {
            component.find ('caseContactLastName').setCustomValidity("");
            component.find ('caseContactLastName').reportValidity ();
        }
        
        let firstName = component.find ('caseContactFirstName').get ('v.value').trim ();
        if (!firstName || firstName === undefined || firstName === null) {
            component.find ('caseContactFirstName').setCustomValidity($A.get('$Label.c.J_Input_Name_Error'));
            component.find ('caseContactFirstName').reportValidity ();
            return false;
        }else {
            component.find ('caseContactFirstName').setCustomValidity("");
            component.find ('caseContactFirstName').reportValidity ();
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
            component.find ('caseContactEmail').setCustomValidity($A.get('$Label.c.J_InvalidEmail'));
            component.find ('caseContactEmail').reportValidity ();
            return false;
        } 

        let caseRequestersCompanyName = component.find ('caseRequestersCompanyName').get ('v.value').trim ();
        if (!caseRequestersCompanyName || caseRequestersCompanyName === undefined || caseRequestersCompanyName === null) {
            component.find ('caseRequestersCompanyName').setCustomValidity($A.get('$Label.c.J_RequestersCompanyNameError'));
            component.find ('caseRequestersCompanyName').reportValidity ();
            return false;
        }else {
            component.find ('caseRequestersCompanyName').setCustomValidity("");
            component.find ('caseRequestersCompanyName').reportValidity ();
        }

        let caseSubject = component.find ('caseSubject').get ('v.value').trim ();
        if (!caseSubject || caseSubject === undefined || caseSubject === null) {
            component.find ('caseSubject').setCustomValidity($A.get('$Label.c.J_SubjectError'));
            component.find ('caseSubject').reportValidity ();
            return false;
        }else {
            component.find ('caseSubject').setCustomValidity("");
            component.find ('caseSubject').reportValidity ();
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
        let licensecode = component.find('caseLicence').get('v.value').trim();
        console.log(licensecode);
        if(relatedName!='Academy' && licensecode=='')
        {
          //J_LicenseCodeError  
          component.find ('caseLicence').setCustomValidity($A.get('$Label.c.J_LicenseCodeError'));
          component.find ('caseLicence').reportValidity ();
           // component.find('caseLicence').focus();
          return false;
        }
        else
        {
           component.find ('caseLicence').setCustomValidity("");
            component.find ('caseLicence').reportValidity ();
        }
		let caseDescription = component.find ('caseDescription').get ('v.value');
        if (caseDescription) {
            caseDescription = caseDescription.trim ();
        }
        if (!caseDescription || caseDescription === undefined || caseDescription === null) {
            component.find ('caseDescription').set('v.validity','{valid:false, badInput :true}');
            component.find ('caseDescription').showHelpMessageIfInvalid();
            component.find ('caseDescription').focus ();
            return false;
        }else {
            component.find ('caseDescription').setCustomValidity("");
            component.find ('caseDescription').reportValidity ();
        }
        return true;

    },
    validateBlackListDomains : function (component) {
        let blackListDomains  = component.get ('v.blackListDomains');
        let email = component.find ('caseContactEmail').get ('v.value');

        let selectedProductComponent = component.find ('relatedName').get ('v.value');
        
        if (blackListDomains && blackListDomains.length > 0 && email && (selectedProductComponent === undefined || selectedProductComponent.toLowerCase () !== 'Academy'.toLocaleLowerCase ()) ) {
            let domainName = email.substring(email.indexOf ('@') + 1, email.lastIndexOf('.') );
            for (let index = 0; index < blackListDomains.length; index++) {
                if (domainName && domainName.toLowerCase () === (blackListDomains[index].MasterLabel.toLowerCase ())) {
                    component.set ('v.errorMessage', $A.get ('$Label.c.Official_Error_Msg'));
                    //component.find ('caseContactEmail').focus();
                    return false;
                }
            }
        }
        return true;
    },
    handleSubmitClick: function(component, event) {
        let self = this;

        if (this.validateForm (component) && this.validateBlackListDomains (component)) {
        	let caseObj = {'Status' : 'New', 
                       'Origin' : 'Web',
                       'Case_Web_Form_Region__c' : 'Japan',
                       'SuppliedName' : component.find ('caseContactFirstName').get ('v.value') + ' ' + component.find ('caseContactLastName').get ('v.value') ,
                       'SuppliedEmail' : component.find ('caseContactEmail').get ('v.value'),
                       'End_Customer_s_Name__c' :component.find ('caseEndCustomerName').get ('v.value'),
                       'Requester_s_Company_Name__c' :component.find ('caseRequestersCompanyName').get ('v.value'),
                       'SuppliedPhone' :  component.get ('v.selectedCountryCode') + component.find ('casePhone').get ('v.value'),
                       'Subject': component.find ('caseSubject').get ('v.value'),
                       'Description' : component.find ('caseDescription').get ('v.value'),
                       'Steps_To_Reproduce_The_Issue__c' : component.find ('Steps_To_Reproduce_The_Issue__c').get ('v.value'),
                       'Expected_Result__c' : component.find ('Expected_Result__c').get ('v.value'),
                       'Actual_Result__c' : component.find ('Actual_Result__c').get ('v.value'),
                       'Frequency__c' : component.find ('Frequency__c').get ('v.value'),
                       'Workaround__c' : component.find ('Workaround__c').get ('v.value'),
                       'What_You_Want_Us_To_Do__c' : component.find ('What_You_Want_Us_To_Do__c').get ('v.value'),
                       'Error_Message__c' : component.find ('caseErrMsg').get ('v.value'),
                       'License_Code__c' : component.find ('caseLicence').get ('v.value'),
                       'Country__c' : component.get ('v.selectedCountry'),
                       'Related_To__c' : component.get ('v.selectedRelated'), 
                       'Environment_Of_Issue__c' : component.get ('v.selectedEnvironment'), 
                       'No_Of_Robots_Impacted_By_Issue__c' : component.get ('v.selectedNumRob'), 
                       'Studio_Version__c' : component.get ('v.selectedStudio'), 
                       'Orchestrator_Version__c' : component.get ('v.selectedOrches'), 
                       'RecordTypeId':$A.get("$Label.c.JapanCaseRecordTypeId"),
                       'Webform_Acknowledgement__c':component.find('caseAcknowledge').get ('v.checked')
                   };

            let priority = component.get ('v.selectedPriority');
            if (priority && priority !== undefined && priority !== null && priority !== '') {
                caseObj.Priority = priority;
            }
            if (caseObj && caseObj.Related_To__c && caseObj.Related_To__c !== undefined && caseObj.Related_To__c !== null) {
                let productRecordTypes = component.get ('v.productRecordTypes');
                productRecordTypes.forEach (function (record) {
                    if (record.MasterLabel === caseObj.Related_To__c) {
                        caseObj.RecordTypeId = record.RecordTypeId__c;
                        return;
                    } 
                });
            }
            
            let params = {'caseString' : JSON.stringify (caseObj)};
            component.find ('customNotification').hide ();
            component.set("v.showLoadingSpinner", true);


            this.createCase (component, params).then (
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
                        self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), $A.get("$Label.c.Error_Case_Creation_Msg"));
                    }
                }),
                $A.getCallback (function (error) {
                    component.set("v.showLoadingSpinner", false);
                    self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), $A.get("$Label.c.Error_Case_Creation_Msg"));
                })
            );          
        } else {
            var scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            //window.scrollTo(scrollOptions);
            self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), component.get ('v.errorMessage'));
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
    
    getproductRecordTypes : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.getproductRecordTypes');
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
                'recordTypeId' : $A.get("$Label.c.JapanCaseRecordTypeId")
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
            
          	let action = component.get ('c.saveCase');
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
        this.createModal (component, true, $A.get("$Label.c.J_Success_Title"), $A.get("$Label.c.Case_Success_Message"));
        component.getEvent("caseCreated").fire();
    },
    createModal : function (component, isSuccess, title, description) {
        let self = this;
        if (isSuccess) {
            component.set ('v.isBtnDisabled', isSuccess);
            self.handleCheck(component);
        }
        component.set ('v.modalTitle', title);
        component.set ('v.isSuccess', isSuccess);
        component.set ('v.errorMessage', description);
        component.find ('customNotification').show ();
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
})