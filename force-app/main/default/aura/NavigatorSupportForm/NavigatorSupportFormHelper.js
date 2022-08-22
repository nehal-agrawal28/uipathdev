({
    //MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    
    doInit : function (component, event) {
        
        let self = this; 
        
        let countryValuesPromise = this.getCountryPickListValues (component, event);
        let PriorityValuesPromise = this.getPriorityPickListValues (component, event);
        let RelatedValuesPromise = this.getWhatFeatureIsThisRelatedToPickListValues (component, event);
        let EnvironmentValuesPromise = this.getEnvironmentPickListValues (component, event);
        let NumRobValuesPromise = this.getNumRobPickListValues (component, event);
        let StudioPickValuesPromise = this.getStudioPickListValues (component, event);
        let OrchestratorValuesPromise = this.getOrchestratorPickListValues (component, event);
        let countryCodePromise = this.getCountryCodePickListValues (component, event);
        let blackListDomainsPromis  = this.getBlackListDomains (component, event);
        let TimeZoneListPromis  = this.getTimeZoneList (component, event);
        let IssueTypePromis =this.getIssueTypePickListValues (component, event);
        
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
                      IssueTypePromis
                     ]).then ( 
            $A.getCallback (function (results) {
                component.set("v.showLoadingSpinner", false);
                if (results && results !== null && results !== undefined) {
                    component.set ('v.countryList', results[0]);
                    component.set ('v.priorityList', results[1]);
                    var withoutPortal = [];
                    for(var i = 0;i<results[7].length;i++){
                        console.log('asdf'+results[7][i].label);
                        if ( results[7][i].label != 'Upload/Download issues' &&
                            results[7][i].label != 'Company Profile Request' &&
                           results[7][i].label != 'Component publishing queries')
                        withoutPortal.push(results[7][i]);
                        /*if(results[7][i].label == 'Connect Enterprise'){
                            results[7][i].isSelected = true;
                            withoutPortal.push(results[7][i]);
                            
                        }*/
                            
                    }
                    component.set ('v.relatedList', withoutPortal);
                    component.set ('v.environmentList', results[3]);
                    component.set ('v.numRobList', results[4]);
                    component.set ('v.studioList', results[5]);
                    component.set ('v.orchestratorList', results[6]);
                    component.set ('v.dependentMap', results[2]);
                    component.set ('v.blackListDomains', results[8]);
                    component.set ('v.TimeZoneList', results[9]);
                    component.set ('v.IssueTypeList', results[10]);
                    
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
        
        component.set ('v.legacyFormUrl', window.location.origin + '/' + $A.get("$Label.c.UI_Path_Legacy_Case_Page_Name"));
    },
    handleCheck :function (component) {
        debugger;
        let isCapta = component.get ('v.isCapta');
        let isSiteValidated = true;
        let IsAckSelected = component.get ('v.IsAckSelected');
        let myButton = component.find ('myButton');
        console.log('mytton',myButton);
        console.log('isCapta',isCapta);
        console.log('isSiteValidated',isCapta);
        console.log('IsAckSelected',isCapta);
        if (isCapta && IsAckSelected && isSiteValidated) {
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
        
        console.log('frameSrc:' , frameSrc);
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
        let caseSiteUrl = component.find ('caseSiteUrl').get ('v.value').trim ();
        if (!caseSiteUrl || caseSiteUrl === undefined || caseSiteUrl === null) {
            component.find ('caseSiteUrl').setCustomValidity("Please fill License Code.");
            component.find ('caseSiteUrl').reportValidity ();
            return false;
        }else {
            component.find ('caseSiteUrl').setCustomValidity("");
            component.find ('caseSiteUrl').reportValidity ();
        }
        /*let relatedName = component.find ('relatedName').get ('v.value').trim ();
        if (!relatedName || relatedName === undefined || relatedName === null) {
            component.find ('relatedName').set('v.validity','{valid:false, badInput :true}');
            component.find ('relatedName').showHelpMessageIfInvalid();
            component.find ('relatedName').focus ();
            return false;
        }*/
        let priority = component.find ('priority').get ('v.value').trim ();
        if (!priority || priority === undefined || priority === null) {
            component.find ('priority').set('v.validity','{valid:false, badInput :true}');
            component.find ('priority').showHelpMessageIfInvalid();
            component.find ('priority').focus ();
            return false;
        }
        
        /*let NumRobryListName = component.find ('NumRobryListName').get ('v.value').trim ();
        if (!NumRobryListName || NumRobryListName === undefined || NumRobryListName === null) {
            component.find ('NumRobryListName').set('v.validity','{valid:false, badInput :true}');
            component.find ('NumRobryListName').showHelpMessageIfInvalid();
            component.find ('NumRobryListName').focus ();
            return false;
        }*/
        
        /*let studioListName = component.find ('studioListName').get ('v.value').trim ();
        if (!studioListName || studioListName === undefined || studioListName === null) {
            component.find ('studioListName').set('v.validity','{valid:false, badInput :true}');
            component.find ('studioListName').showHelpMessageIfInvalid();
            component.find ('studioListName').focus ();
            return false;
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
    checkValidSiteURL : function (component, event) {
        let caseSiteUrl = component.find ('caseSiteUrl').get ('v.value');
        if (!caseSiteUrl || caseSiteUrl === undefined || caseSiteUrl === null) {
            component.find ('caseSiteUrl').setCustomValidity("Please fill Site URL.");
            component.find ('caseSiteUrl').reportValidity ();
            return false;
        }else {
            component.find ('caseSiteUrl').setCustomValidity("");
            component.find ('caseSiteUrl').reportValidity ();
            component.set ('v.isInValidSiteURL', true);
            component.set("v.showLoadingSpinner", true);
            this.validateSiteURL (component, caseSiteUrl).then (
                $A.getCallback (function (result) {
                    component.set("v.showLoadingSpinner", false);
                    let resMap = result;
                    console.log(resMap)
                    if (result &&  result !== undefined && result !== null && resMap.validated) {
                        component.set('v.rpaEmailId', resMap.email);
                        component.set ('v.isSiteValidated', true);
                        component.find('caseSiteUrl').set('v.disabled', true);
                        
                    } else {
                        component.set ('v.isSiteValidated', false);
                        component.find ('caseSiteUrl').setCustomValidity($A.get("$Label.c.Error_In_Site_URL"));
                        component.find ('caseSiteUrl').reportValidity ();
                    }
                }),
                $A.getCallback (function (error) {
                    component.set ('v.isSiteValidated', false);
                    component.set("v.showLoadingSpinner", false);
                    self.createModal (component, false, "Error", $A.get("$Label.c.Error_In_Site_URL"));
                })
            );
        }
    },
    validateSiteURL : function (component, siteURL) {
        let self = this;
        let params = {
            'validateSiteURL' : siteURL
        };
        return new Promise ($A.getCallback(function (resolve, reject) {
            
            let action = component.get ('c.cloudRPAAccount');
            action.setParams (params);
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === 'SUCCESS') {
                    console.log('checkRes ',response.getReturnValue());
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
        debugger;
        console.log('0');
        if (this.validateForm (component)) {
            console.log('1');
            let caseObj = {'Status' : 'New', 
                           'Origin' : 'Web',
                           'SuppliedName' : component.find ('caseContactName').get ('v.value'),
                           'SuppliedEmail' : component.find ('caseContactEmail').get ('v.value'),
                           //'End_Customer_s_Name__c' : (component.find ('caseEndCustomerName').get ('v.value')).trim (),
                           'SuppliedPhone' :  component.get ('v.selectedCountryCode') + component.find ('casePhone').get ('v.value'),
                           'Subject': component.find ('caseSubject').get ('v.value'),
                           'Description' : component.find ('caseDescription').get ('v.value'),
                           'Error_Message__c' : component.find ('caseErrMsg').get ('v.value'),
                           //'Device_Id__c' : component.find ('caseDevice').get ('v.value'),
                           //'License_Code__c' : (component.find ('caseLicence').get ('v.value')).trim (),
                           'Country__c' : component.get ('v.selectedCountry'),
                           'Time_Zone__c' : component.get ('v.selectedTimeZone'),
                           //'Issue_type_1__c':component.get('v.selectedIssueType'),
                           //'What_feature_is_this_related_to__c' : component.get ('v.selectedRelated'), 
                           'Priority' :component.get ('v.selectedPriority'), 
                           //'Environment_Of_Issue__c' : component.get ('v.selectedEnvironment'), 
                           'No_Of_Robots_Impacted_By_Issue__c' : component.get ('v.selectedNumRob'), 
                           'Studio_Version__c' : component.get ('v.selectedStudio'), 
                           // 'Orchestrator_Version__c' : component.get ('v.selectedOrches'), 
                           'RecordTypeId':$A.get("$Label.c.WebtoCaseRecordTypeId"),
                           //'Case_Source_Link__c' : window.location.href,
                           'Site_URL__c' : component.find('caseSiteUrl').get('v.value'),
                           'Case_Web_Form_Region__c': 'Connect Enterprise',
                           //'SuppliedEmail': component.get('v.rpaEmailId'),
                           //'SuppliedName' :'Bharadwaj',
                           'Webform_Acknowledgement__c': component.find('caseAcknowledge').get('v.checked')
                          };
            console.log('3');
            
            debugger;
            let params = {'caseString' : JSON.stringify (caseObj)};
            console.log('casecheck ',JSON.stringify(params));
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
    
    getWhatFeatureIsThisRelatedToPickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
          //  let action = component.get ('c.getWhatFeatureIsThisRelatedToPickListValues');
            let action = component.get ('c.getGenericObjectfieldValues');
            action.setParams ({
                'objAPIName' : 'Case',
                'fieldName' : 'What_feature_is_this_related_to__c',
                'recordTypeDevName' : 'Incident'
                
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
    getIssueTypePickListValues : function (component, event) {
        let self = this;
        return new Promise ($A.getCallback(function (resolve, reject) {
            let action = component.get ('c.getIssueTypePickListValues');
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