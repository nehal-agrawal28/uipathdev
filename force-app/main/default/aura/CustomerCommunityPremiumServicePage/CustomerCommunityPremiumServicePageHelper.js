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
	}
})