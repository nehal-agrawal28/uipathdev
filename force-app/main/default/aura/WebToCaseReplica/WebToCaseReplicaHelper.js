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
        
        //component.set("v.showLoadingSpinner", true);
        
        Promise.all ([countryValuesPromise, 
                      PriorityValuesPromise, 
                      countryCodePromise,                      
                      EnvironmentValuesPromise, 
                      NumRobValuesPromise,
                      StudioPickValuesPromise,
                      OrchestratorValuesPromise,
                      RelatedValuesPromise,
                      blackListDomainsPromis 
                     ]).then ( 
            $A.getCallback (function (results) {
                component.set("v.showLoadingSpinner", false);
                if (results && results !== null && results !== undefined) {
                    component.set ('v.countryList', results[0]);
                    component.set ('v.priorityList', results[1]);
                    component.set ('v.relatedList', results[7]);
                    component.set ('v.environmentList', results[3]);
                    component.set ('v.numRobList', results[4]);
                    component.set ('v.studioList', results[5]);
                    component.set ('v.orchestratorList', results[6]);
                    component.set ('v.dependentMap', results[2]);
                    component.set ('v.blackListDomains', results[8]);
                    
                    self.updateOnInit (component, event);
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
                self.handleCheck (component);
            }
            
        }, false);   
    },
    handleCheck :function (component) {
        let isCapta = component.get ('v.isCapta');
        let IsAckSelected = component.get ('v.IsAckSelected');
        let myButton = component.find ('myButton');
        console.log('mytton',myButton);
        console.log('v.capFrameHeight',component.get('v.capFrameHeight'));
        if (isCapta && IsAckSelected) {
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

        let casePhone = component.find ('casePhone').get ('v.value').trim ();
        if (!casePhone || casePhone === undefined || casePhone === null) {
            component.find ('casePhone').setCustomValidity($A.get('$Label.c.J_Phone_Error'));
            component.find ('casePhone').reportValidity ();
            return false;
        }else {
			component.find ('casePhone').setCustomValidity("");
            component.find ('casePhone').reportValidity ();
        }

        let caseEndCustomerName = component.find ('caseEndCustomerName').get ('v.value').trim ();
        if (!caseEndCustomerName || caseEndCustomerName === undefined || caseEndCustomerName === null) {
            component.find ('caseEndCustomerName').setCustomValidity($A.get('$Label.c.J_Organization_Error'));
            component.find ('caseEndCustomerName').reportValidity ();
            return false;
        }else {
			component.find ('caseEndCustomerName').setCustomValidity("");
            component.find ('caseEndCustomerName').reportValidity ();
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
        
        let NumRobryListName = component.find ('NumRobryListName').get ('v.value').trim ();
        if (!NumRobryListName || NumRobryListName === undefined || NumRobryListName === null) {
            component.find ('NumRobryListName').set('v.validity','{valid:false, badInput :true}');
            component.find ('NumRobryListName').showHelpMessageIfInvalid();
            component.find ('NumRobryListName').focus ();
            return false;
        }
        
        let studioListName = component.find ('studioListName').get ('v.value').trim ();
        if (!studioListName || studioListName === undefined || studioListName === null) {
            component.find ('studioListName').set('v.validity','{valid:false, badInput :true}');
            component.find ('studioListName').showHelpMessageIfInvalid();
            component.find ('studioListName').focus ();
            return false;
        }
        
        let orchestratorListId = component.find ('orchestratorListId').get ('v.value').trim ();
        if (!orchestratorListId || orchestratorListId === undefined || orchestratorListId === null) {
            component.find ('orchestratorListId').set('v.validity','{valid:false, badInput :true}');
            component.find ('orchestratorListId').showHelpMessageIfInvalid();
            component.find ('orchestratorListId').focus ();
            return false;
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
        
        let caseDevice = component.find ('caseDevice').get ('v.value').trim ();
        if (!caseDevice || caseDevice === undefined || caseDevice === null) {
            component.find ('caseDevice').setCustomValidity("Please fill Device Id.");
            component.find ('caseDevice').reportValidity ();
            return false;
        }else {
            component.find ('caseDevice').setCustomValidity("");
            component.find ('caseDevice').reportValidity ();
        }
        
        let caseLicence = component.find ('caseLicence').get ('v.value').trim ();
        if (!caseLicence || caseLicence === undefined || caseLicence === null) {
            component.find ('caseLicence').setCustomValidity("Please fill License Code.");
            component.find ('caseLicence').reportValidity ();
            return false;
        }else {
            component.find ('caseLicence').setCustomValidity("");
            component.find ('caseLicence').reportValidity ();
        }
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
    handleSubmitClick: function(component, event) {
       
        let self = this;
        
    	if (this.validateForm (component) && this.validateBlackListDomains (component)) {
        	let caseObj = {'Status' : 'New', 
                'Origin' : 'Web',
                'SuppliedName' : component.find ('caseContactName').get ('v.value'),
                'SuppliedEmail' : component.find ('caseContactEmail').get ('v.value'),
                'End_Customer_s_Name__c' :component.find ('caseEndCustomerName').get ('v.value'),
                'SuppliedPhone' :  component.get ('v.selectedCountryCode') + component.find ('casePhone').get ('v.value'),
                'Subject': component.find ('caseSubject').get ('v.value'),
                'Description' : component.find ('caseDescription').get ('v.value'),
                'Error_Message__c' : component.find ('caseErrMsg').get ('v.value'),
                'Device_Id__c' : component.find ('caseDevice').get ('v.value'),
                'License_Code__c' : component.find ('caseLicence').get ('v.value'),
                'Country__c' : component.get ('v.selectedCountry'),
                'Related_To__c' : component.get ('v.selectedRelated'), 
                'Priority' :component.get ('v.selectedPriority'), 
                'Environment_Of_Issue__c' : component.get ('v.selectedEnvironment'), 
                'No_Of_Robots_Impacted_By_Issue__c' : component.get ('v.selectedNumRob'), 
                'Studio_Version__c' : component.get ('v.selectedStudio'), 
                'Orchestrator_Version__c' : component.get ('v.selectedOrches'), 
                'RecordTypeId':$A.get("$Label.c.WebtoCaseRecordTypeId"),
                'Webform_Acknowledgement__c':component.find('caseAcknowledge').get ('v.checked')
            };
             console.log('caseObj'+ caseObj);
            let params = {'caseString' : JSON.stringify (caseObj)};
            component.set("v.showLoadingSpinner", true);
            this.createCase (component, params).then (
                $A.getCallback (function (result) {
                    console.log('SAvidd',result);
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
                    console.log('inside success',response.getReturnValue());
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
                console.log('state'+ state);
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
    }
})