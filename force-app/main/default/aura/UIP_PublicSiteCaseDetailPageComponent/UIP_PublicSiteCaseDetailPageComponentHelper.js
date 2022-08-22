({
    validateEmailAndCaseNumber  : function (component, event, email) {
		let params  = {
			'email' : email
		};
		let self = this;
		component.set("v.showLoadingSpinner", true);

		this.validate (component, params).then (
			$A.getCallback (function (result) {
				let resMap = JSON.parse(result);
				component.set("v.showLoadingSpinner", false);
				if (result &&  result !== undefined && result !== null && resMap.status && resMap.status === 'SUCCESS') {
					//component.set ('v.caseObj', resMap.result);
					component.set ('v.contactObj', resMap.result);
					self.toggleOTPModal (component, true);
					component.set ('v.systemGeneratedOTP', resMap.OTP);
                    self.setTimeOutToReload (component);
				} else {
                    component.set ('v.contactObj', null);
					//component.set ('v.caseObj', null);
					//console.log ('Alert :', resMap.message);
                    self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), resMap.message);
                    self.resetVal (component, ['v.errorMessage'], resMap.message);
				}
			}),
			$A.getCallback (function (error) {
				component.set("v.showLoadingSpinner", false);
				component.set ('v.caseObj', null);
                console.log ()
				self.createModal (component, false, $A.get("$Label.c.J_Error_Title"), $A.get("$Label.c.Case_Email_Service_not_Found") );
			})
		);
	},
	validate : function (component, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
          	let action = component.get ('c.validateContactEmail');  //validateCaseNumberAndEmail
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
    fetchAllDetails : function (component, event) {
        let self = this;
        component.set("v.showLoadingSpinner", true);
        
        let contactObj =  component.get ('v.contactObj');
		this.toggleOTPModal (component, false);
        debugger;
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
                    });
                    component.set ('v.caseList', resMap.result);

                    self.toggleInputs (component, ['v.showCaseDetails'], true);
                    self.toggleInputs (component, ['v.isEmailDisabled', 'v.isCaseNumberDisabled'], true);
                    self.toggleInputs (component, ['v.isFindBtnEnabled'], false);
                    self.clearTimeOutToReload (component);
                    self.setTimeOutToReload (component);
                    
                    debugger;
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
			this.fetchCaseDetails (component, caseList[index]);
        }
    },
    fetchCaseDetails : function (component, caseObj) {
		component.set("v.showLoadingSpinner", true);
		//let caseObj =  component.get ('v.caseObj');
		this.toggleOTPModal (component, false);

        let caseDataPromise = this.fetchCaseData (component, caseObj.CaseNumber, caseObj.RecordType.Name);
        let caseExtraDetailsPromise = this.getEmailAndAttachmentByCaseId (component, caseObj.Id);

        //let attachmentPromise = this.getAttachmentByCaseId (component, caseObj.Id);
        //let emailPromise = this.getEmailsByCaseId (component, caseObj.Id);

        let self = this;
        Promise.all ([caseDataPromise, caseExtraDetailsPromise]).then ( //attachmentPromise, emailPromise]).then (
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

                    let caseExtraRes = JSON.parse(results[1]);


                    //component.set ('v.attachmentList', caseExtraRes.attachments);
                    caseExtraRes.emailMessages.forEach (function (eachMessage) {
                        eachMessage.MessageDate = new Date (eachMessage.MessageDate);
                    });
                    component.set ('v.emailList', caseExtraRes.emailMessages);

                    self.toggleInputs (component, ['v.isEmailDisabled', 'v.isCaseNumberDisabled'], true);
                    self.toggleInputs (component, ['v.isFindBtnEnabled'], false);
                    self.clearTimeOutToReload (component);
                    self.setTimeOutToReload (component);
                    
                }

            }),
            $A.getCallback (function (error) {
                component.set("v.showLoadingSpinner", false);
                console.log (error);
            })
        );
    },
    toggleOTPModal : function (component, shouldShow) {
        component.set ('v.userEnteredOTP', null);
        if (!shouldShow) {
            this.clearTimeOutToReload (component);
        }
    	component.set ('v.showOTPModal', shouldShow);
    },
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
                    reject(response.getError());
                }
            });
            $A.enqueueAction(action);
        }));
    }, 
    /*getAttachmentByCaseId : function (component, caseId) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get ('c.getAttachmentByCaseId');
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
    getEmailsByCaseId : function (component, caseId) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get ('c.getEmailsByCaseId');
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
    },*/
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
    validateEmail : function (email) {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(email).toLowerCase());
    }, 
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