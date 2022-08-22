({
	findAccountType : function(component) {
		let action = component.get ('c.getAccountInfo');
        action.setCallback (this, function (response) {
           	let state = response.getState ();
            if (state === 'SUCCESS') {
                let result = response.getReturnValue ();
                if (result && JSON.parse(result).status && JSON.parse(result).status === true) {
                    let user = JSON.parse(result).result;
                    if (user && user !== undefined 
                        && user !== null && user.AccountId 
                        && user.AccountId !== undefined && user.AccountId !== null ) {
                  		if (user.Account.Maintenance_Flag__c  
                            && user.Account.Maintenance_Flag__c  !== undefined
                            && user.Account.Maintenance_Flag__c  !== null
                            && user.Account.Maintenance_Flag__c .toLowerCase() === 'premium') {
							component.set ('v.isPremiumAccount', true);                            
                        }
                    }
                } else {
                    
                }
            } else if (state === 'INCOMPLETE'){
                console.log ('Exception in reteiving Data :' )
            } else if (state === 'ERROR'){
                console.log ('Exception in reteiving Data :' + response.getError ());
            }
            
        });
        $A.enqueueAction (action);
	},
    createTask : function (component, taskType) {
        let isResponseCame = component.get ('v.isResponseCame');
        let self = this;
        if (isResponseCame && isResponseCame === true) {
            let action = component.get ('c.createTask');
            action.setParams ({'taskType': taskType});
            component.set ('v.isResponseCame', false);            
            action.setCallback (this, function (response) {
                component.set ('v.isResponseCame', true);
                let state = response.getState ();
                if (state === 'SUCCESS') {
                    let result = response.getReturnValue ();
                    if (result && JSON.parse(result).status && JSON.parse(result).status === true) {
                        self.createModal (component, true, "Success", $A.get ("$Label.c.Customer_community_task_created"));
                        window.setTimeout(
                            $A.getCallback(function() {
                                component.find ('customNotification').hide ();
                                self.tryUpdateTheNumbers (component)
                            }), Number ($A.get ("$Label.c.Customer_Community_callback_task_timeout_milliseconds"))
                        );
                    } else {
                        
                    }
                } else if (state === 'INCOMPLETE'){
                    console.log ('Exception in reteiving Data :' )
                } else if (state === 'ERROR'){
                    console.log ('Exception in reteiving Data :' + response.getError ());
                }
            })
            $A.enqueueAction (action);    
        }
    },
    tryUpdateTheNumbers : function (component) {
        let action = component.get ('c.getLatestTaskCount');
        action.setCallback (this, function (response) {
           	let state = response.getState ();
            if (state === 'SUCCESS') {
                let result = response.getReturnValue ();
                if (result) {
					let res = JSON.parse(result);
                    if (res["Infrastructure Services"]) {
                       component.set ('v.infraCount', Number (res["Infrastructure Services"])); 
                    }
                    if (res["Optimization Services"]) {
                       component.set ('v.optiCount', Number (res["Optimization Services"]));                        
                    }
                    if (res["Contact Technical Support"]) {
                       component.set ('v.techCount', Number (res["Contact Technical Support"]));                        
                    }
                } else {
                    console.log ('Error');
                }
            } else if (state === 'INCOMPLETE'){
                console.log ('Exception in reteiving Data :' )
            } else if (state === 'ERROR'){
                console.log ('Exception in reteiving Data :' + response.getError ());
            }
            
        });
        $A.enqueueAction (action);
        
    },
    createModal : function (component, isSuccess, title, description) {
        component.set ('v.modalTitle', title);
        component.set ('v.isSuccess', isSuccess);
        component.set ('v.errorMessage', description);
        component.find ('alertModal').show ();
    },
    createCase: function(component,CaseType)
    {
        component.set("v.showLoadingSpinner", true); 
        let action = component.get ('c.createCaseForTechnicalAdvisor');
        action.setParams({'ServiceType':CaseType});
        action.setCallback (this, function (response) {
           	let state = response.getState ();
            if (state === 'SUCCESS') {
                let result = response.getReturnValue ();
                if (result !=null)
                {
                    component.set("v.CaseId",response.getReturnValue ().Id);
                    var successmsg= "Case is created with the Number #"+  response.getReturnValue ().CaseNumber + '.' ;
                    component.set("v.showLoadingSpinner", false);  
                    this.createModal (component, true, "Success", successmsg);
                }
                else
                {
                    component.set("v.showLoadingSpinner", false);
                  this.createModal (component, false,"Error", $A.get("$Label.c.Error_Case_Creation_Msg"));
                  
                }
            }
            
            });
         $A.enqueueAction (action);
    }
})