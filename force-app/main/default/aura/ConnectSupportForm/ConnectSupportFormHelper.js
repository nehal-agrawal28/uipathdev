({
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    
    doInit : function (component, event) {
        let self = this;
        let featurePicklist = this.getrelatedFeaturePickListValues (component, event);
        let recTypeId = this.getRectypeId (component, event);
        let countryValuesPromise = this.getCountryPickListValues (component, event);
        let blackListDomainsPromise  = this.getBlackListDomains (component, event);
        //component.set("v.showLoadingSpinner", true);
        Promise.all ([ 
            featurePicklist, 
            recTypeId,
            countryValuesPromise,
            blackListDomainsPromise
        ]).then (
            $A.getCallback (function (results) {
                component.set("v.showLoadingSpinner", false);
                if (results && results !== null && results !== undefined) {
                    
                    var countryArray =[];
                    var countryObj ={};
                    
                    countryObj.value = "";
                    countryObj.value = "--None--";
					results[2].push(countryObj);                    
                    component.set ('v.country', results[2]);
                    component.set ('v.blackListDomains', results[3]);
                    
                    var sobjArray =[];
                    var obj ={};
                    for(var count=0;count< results[0].length; count++){
                        if(results[0][count].value != 'Admin console' && results[0][count].value != 'Automations' && results[0][count].value != 'Components' && results[0][count].value != 'User profile'
                          && results[0][count].value != 'UiPath Supported Components'  && results[0][count].value != 'My Profile (Badges/Achievements)'  && results[0][count].value != 'Other' && results[0][count].value != 'Support on Demand'){
                            
                            sobjArray.push(results[0][count]);
                        }
                    }
                    component.set ('v.requestCategory', sobjArray);
                    component.set('v.recTypeId',results[1] );
                    
                     if($A.get("$Locale.language") == "ja"){
            			component.set('v.selectedCountry', "Japan");
        			}
                    
                }
            }),
            $A.getCallback(function(error) {
                component.set("v.showLoadingSpinner", false);
                console.log ('Error :' + error);
            })
        );
        this.setUpIframe (component, event);
        
        //let vfOrigin = "https://servcloud-uipath-survey.cs1.force.com";
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
    fetchCountryValues: function(component, ListOfDependentFields) {
        var dependentFields = [];
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            dependentFields.push(ListOfDependentFields[i]);
        }
        if (ListOfDependentFields && ListOfDependentFields.length > 0) {
            component.set ('v.selectedrequestSubCategory', ListOfDependentFields [0]);
        } else {
            component.set ('v.selectedrequestSubCategory', null);
        }
        component.set("v.requestSubCategory", dependentFields);
    },
    validateForm : function (component) {
        component.set ('v.errorMessage', $A.get ('$Label.c.Mandatory_error_msg'));
        
        if(component.get('v.showEmailMessage')){
            let name = component.find ('caseContactName').get ('v.value').trim ();
            if (!name || name === undefined || name === null) {
                component.find ('caseContactName').setCustomValidity($A.get('$Label.c.J_Input_Name_Error'));
                component.find ('caseContactName').reportValidity ();
                return false;
            }else {
                component.find ('caseContactName').setCustomValidity("");
                component.find ('caseContactName').reportValidity ();
            }
            let email = component.find ('caseContactEmail1').get ('v.value').trim ();
            if (!email || email === undefined || email === null) {
                component.find ('caseContactEmail1').setCustomValidity($A.get('$Label.c.J_EmailError'));
                component.find ('caseContactEmail1').reportValidity ();
                return false;
            }else {
                component.find ('caseContactEmail1').setCustomValidity("");
                component.find ('caseContactEmail1').reportValidity ();
            }
            
            
        }else{
            
            let name = component.find ('caseContactName').get ('v.value').trim ();
            if (!name || name === undefined || name === null) {
                component.find ('caseContactName').setCustomValidity($A.get('$Label.c.J_Input_Name_Error'));
                component.find ('caseContactName').reportValidity ();
                return false;
            }else {
                component.find ('caseContactName').setCustomValidity("");
                component.find ('caseContactName').reportValidity ();
            }
            let email = component.find ('caseContactEmail2').get ('v.value').trim ();
            if (!email || email === undefined || email === null) {
                component.find ('caseContactEmail2').setCustomValidity($A.get('$Label.c.J_EmailError'));
                component.find ('caseContactEmail2').reportValidity ();
                return false;
            }else {
                component.find ('caseContactEmail2').setCustomValidity("");
                component.find ('caseContactEmail2').reportValidity ();
            }                 
        }
        
        let selectedrequestCategory =  component.find ('What_is_your_request_related_to__c').get ('v.value').trim ();
        if ( !selectedrequestCategory || (selectedrequestCategory && selectedrequestCategory === '--- None ---') || selectedrequestCategory === undefined || selectedrequestCategory === null || selectedrequestCategory === '' ) {
            component.find ('What_is_your_request_related_to__c').set('v.validity','{valid:false, badInput :true}');
            component.find ('What_is_your_request_related_to__c').showHelpMessageIfInvalid();
            component.find ('What_is_your_request_related_to__c').focus ();
            return false;
        }
        
        let selectedCountry = component.find ('countryPickList').get ('v.value').trim ();
        if ( selectedCountry == "") {
            component.find ('countryPickList').set('v.validity','{valid:false, badInput :true}');
            component.find ('countryPickList').showHelpMessageIfInvalid();
            component.find ('countryPickList').focus ();
            return false;
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
        
        let caseDescription = component.find ('caseDescription').get ('v.value').trim ();
        if (caseDescription) {
            caseDescription = caseDescription.trim ();
        }
        
        if (!caseDescription || caseDescription === undefined || caseDescription === null) {
            component.find ('caseDescription').setCustomValidity($A.get('$Label.c.J_Description_Error'));
            component.find ('caseDescription').reportValidity ();
            return false;
        }else {
            component.find ('caseDescription').setCustomValidity("");
            component.find ('caseDescription').reportValidity ();
        }
        
        return true;
    },
    handleSubmitClick: function(component, event) {
        let self = this;
        if (this.validateForm (component)) {
            let caseObj = {'Status' : 'New',
                           'Origin' : 'Web',
                           'SuppliedName' : component.find ('caseContactName').get ('v.value'),
                           'SuppliedEmail' : component.get('v.showEmailMessage') ? component.find ('caseContactEmail1').get ('v.value') : component.find ('caseContactEmail2').get ('v.value') ,
                           'Subject': component.find ('caseSubject').get ('v.value'),
                           'Description' : component.find ('caseDescription').get ('v.value'),
                           'What_feature_is_this_related_to__c' :component.get ('v.selectedrequestCategory'),
                           'Webform_Acknowledgement__c': component.find('caseAcknowledge').get('v.checked'),
                           'RecordTypeId': this.validateBlackListDomains(component) ? component.get('v.recTypeId') : $A.get("$Label.c.ServiceRequestRecordTypeId"),
                           'Related_To__c':'UiPath Go',
                           'Is_Free_Mailer__c': !this.validateBlackListDomains(component)
                          };
            let params = {'caseString' : JSON.stringify (caseObj)};
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
    getrelatedFeaturePickListValues : function (component, event) {
        let self = this;
        
        return new Promise ($A.getCallback(function (resolve, reject) {
            let action = component.get ('c.getGenericPicklistValues');
            action.setParams ({
                'objName' : 'Case',
                'fieldName': 'What_feature_is_this_related_to__c'
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
    getRectypeId : function (component, event) {
        let self = this;
        
        return new Promise ($A.getCallback(function (resolve, reject) {
            let action = component.get ('c.getGenericRecordTyeId');
            let recTypeVal ='Incident';
            if($A.get("$Locale.language") == "ja")
                recTypeVal = 'Japan_Incident';
            
            action.setParams ({
                'objName' : 'Case',
                'devlperName': recTypeVal
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
    sendMessage: function(component, message){
        message.origin = window.location.hostname;
        var vfWindow = component.find("vfFrame").getElement().contentWindow;
        vfWindow.postMessage(message, component.get("v.vfHost"));
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
    validateBlackListDomains : function (component) {
        let blackListDomains  = component.get ('v.blackListDomains');
        let email = component.get('v.showEmailMessage') ? component.find ('caseContactEmail1').get ('v.value') : component.find ('caseContactEmail2').get ('v.value');
        if (blackListDomains && blackListDomains.length > 0 && email) {
            let domainName = email.substring(email.indexOf ('@') + 1, email.lastIndexOf('.') );
            for (let index = 0; index < blackListDomains.length; index++) {
                if (domainName && domainName.toLowerCase () === (blackListDomains[index].MasterLabel.toLowerCase ())) {
                    //component.set ('v.errorMessage', $A.get ('$Label.c.Official_Error_Msg'));
                    //component.find ('caseContactEmail').focus();
                    return false;
                }
            }
        }
        return true;
    },
})