({
    /*validateEmailAndCaseNumber  : function (component, event, email) {
        let skipOTP = false;
        if(window.sessionStorage && sessionStorage.getItem("CaseViewSession")){
            if(sessionStorage.getItem("CaseViewSession") === component.get('v.caseEmail')){
                skipOTP = true;
            }
        }
        
        let params  = {
            'email' : email,
            'skipOTP' : skipOTP
        };
        let self = this;
        component.set("v.showLoadingSpinner", true);
        
        this.validate (component, params).then (
            $A.getCallback (function (result) {
                let resMap = JSON.parse(result);
                component.set("v.showLoadingSpinner", false);
                if (result &&  result !== undefined && result !== null && resMap.status && resMap.status === 'SUCCESS') {
                    component.set ('v.contactObj', resMap.result);
                    if(skipOTP){
                        self.fetchAllDetails (component, event);
                        self.toggleOTPModal (component, false);
                    }else{
                        self.toggleOTPModal (component, true);
                        //component.set ('v.systemGeneratedOTP', resMap.OTP);
                    }
                } else {
                    component.set ('v.contactObj', null);
                    self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), resMap.message);
                    self.resetVal (component, ['v.errorMessage'], resMap.message);
                }
            }),
            $A.getCallback (function (error) {
                component.set("v.showLoadingSpinner", false);
                component.set ('v.caseObj', null);
                self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), $A.get("$Label.c.Case_Email_Service_not_Found") );
            })
        );
    },*/
    /*validate : function (component, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get ('c.validateContactEmail'); 
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
    },*/
    fetchAllDetails : function (component, event) {
        let self = this;
        component.set("v.showLoadingSpinner", true);
        
        let contactObj =  component.get ('v.contactObj');
        //this.toggleOTPModal (component, false);
        let params  = {
            'contactId' : contactObj.Id
        };
        this.getAllCasesByContactId (component, params).then (
            $A.getCallback (function (result) {
                let resMap = JSON.parse(result);
                component.set("v.showLoadingSpinner", false);
                if (result &&  result !== undefined && result !== null && resMap.status && resMap.status === 'SUCCESS') {
                    resMap.result.forEach (function (eachCase) {
                        eachCase.CreatedDate = new Date (eachCase.CreatedDate);
                        if(eachCase.ClosedDate)
                            eachCase.ClosedDate = new Date (eachCase.ClosedDate);
                    });
                    component.set ('v.caseList', resMap.result);
                    
                    self.toggleInputs (component, ['v.showCaseDetails'], true);
                    self.toggleInputs (component, ['v.isEmailDisabled', 'v.isCaseNumberDisabled'], true);
                    self.toggleInputs (component, ['v.isFindBtnEnabled'], false);
                } else {
                    self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), resMap.message);
                    self.resetVal (component, ['v.errorMessage'], resMap.message);
                }
            }),
            $A.getCallback (function (error) {
                component.set("v.showLoadingSpinner", false);
                self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), error);
            })
        );
        
    },
    getAllCasesByContactId : function (component, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get ('c.getAllCasesByContactId');  
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
    getCaseDetails : function (component, index) {
        let caseList = component.get ('v.caseList');
        if (caseList[index]) {
            component.set("v.currentCaseIndex",Number(index));
            let caseObj = caseList[index];
            if(caseObj.Status == 'Closed' && !caseObj.SurveyTakers__r && caseObj.ClosedDate>=component.get('v.surveyPendingStart')){
                component.set("v.surveySrc",window.location.pathname + "takesurvey?id="+caseObj.Survey_Id__c+"&cId="+caseObj.ContactId+"&caId="+caseObj.Id+"&src=CaseView");
                component.set("v.selectedSubTabId","Survey");
            }else{
            	component.set("v.selectedSubTabId","CaseDetails");    
            }
            
            this.fetchCaseDetails (component, caseObj);
        }
    },
    fetchCaseDetails : function (component, caseObj) {
        component.set("v.showLoadingSpinner", true);
        component.set ('v.caseObj',caseObj);
        //this.toggleOTPModal (component, false);
        
        let caseDataPromise = this.fetchCaseData (component, caseObj.CaseNumber, caseObj.RecordType.Name);
        let caseExtraDetailsPromise = this.getEmailAndAttachmentByCaseId (component, caseObj.Id);
        let caseArticleDetailsPromise = this.getRelatedArticlesByCaseId(component, caseObj.Id);
        
        let self = this;
        Promise.all ([caseDataPromise, caseExtraDetailsPromise, caseArticleDetailsPromise]).then ( //attachmentPromise, emailPromise]).then (
            $A.getCallback (function (results) {
                component.set("v.showLoadingSpinner", false);
                if (results) {
                    let resMap = JSON.parse(results[0]);
                    
                    if (resMap &&  resMap !== undefined && resMap !== null && resMap.status && resMap.status === 'SUCCESS') {
                        self.toggleInputs (component, ['v.showCaseDetails'], true);
                        component.set ('v.caseResponse', resMap.result);
                    } else {
                        //console.log ('Alert :', resMap.message);
                    }
                    
                    let caseExtraRes = results[1];
                    
                    
                    
                    caseExtraRes.forEach (function (eachMessage) {
                        eachMessage.MessageDate = new Date (eachMessage.MessageDate);
                    });
                    component.set ('v.emailList', caseExtraRes);
                    
                    
                    component.set('v.knowledgeArticles',results[2]);
                    
                    
                    
                    self.toggleInputs (component, ['v.isEmailDisabled', 'v.isCaseNumberDisabled'], true);
                    self.toggleInputs (component, ['v.isFindBtnEnabled'], false);
                    
                    
                }
                
            }),
            $A.getCallback (function (error) {
                component.set("v.showLoadingSpinner", false);
                console.log (error);
            })
        );
    },
    /*toggleOTPModal : function (component, shouldShow) {
        component.set ('v.userEnteredOTP', null);
        if (!shouldShow) {
            this.clearTimeOutToReload (component);
        }
        component.set ('v.showOTPModal', shouldShow);
    },*/
    toggleEmailModal : function (component, shouldShow) {
        if (!shouldShow) {
            component.set ('v.emailMessage', null);
        }
        component.set ('v.showEmailBody', shouldShow);
    },
    fetchCaseData : function (component, caseNumber, recordTypeName) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get ('c.getCase');
            action.setParams ({
                'caseNumber' : caseNumber,
                'recordTypeName': recordTypeName
            });
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
    
    getEmailAndAttachmentByCaseId : function (component, caseId) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get ('c.getEmailAndAttachmentByCaseId');
            action.setParams ({
                'caseId' : caseId
            });
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
                    resolve([]);
                    //reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    }, 
    
    getRelatedArticlesByCaseId : function (component, caseId) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get ('c.getArticlesByCaseId');
            action.setParams ({
                'caseId' : caseId
            });
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
    openEmailPopup : function (component, index) {
        let emailList = component.get ('v.emailList');
        if (emailList[index]) {
            component.set ('v.emailMessage', emailList [index]);
            component.set ('v.showEmailBody', true);
        }
    },
    toggleInputs : function (component, items, isDisabled) {
        items.forEach (function (eachItem) {
            component.set (eachItem, isDisabled);
        })
    },
    resetVal : function (component, items, val) {
        items.forEach (function (eachItem) {
            component.set (eachItem, val);
        })
    },
    createModal : function (component, isSuccess, title, description) {
        component.set ('v.modalTitle', title);
        component.set ('v.isSuccess', isSuccess);
        component.set ('v.errorMessage', description);
        component.find ('alertModal').show ();
    },
    /*validateEmail : function (email) {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(email).toLowerCase());
    }, */
    setTimeOutToReload : function (component) {
        let myTimeOut = component.get ('v.myTimeOut');
        myTimeOut = setTimeout (function () {
            window.location.reload(true);
        }, Number ($A.get('$Label.c.RefreshTimeOutVal')));
        component.set ('v.myTimeOut', myTimeOut);
    },
    clearTimeOutToReload : function (component) {
        let myTimeOut = component.get ('v.myTimeOut');
        clearTimeout (myTimeOut);
        
    }
})