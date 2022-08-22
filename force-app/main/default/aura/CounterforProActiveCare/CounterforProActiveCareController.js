({
    doInit : function(component, event, helper) {
        let action = component.get ('c.getAccountInfo');
        action.setCallback (this, function (response)
                            {
                                let state = response.getState ();
                                if (state === 'SUCCESS') 
                                {
                                    let result = response.getReturnValue ();
                                    var user = JSON.parse(result).result;
                                    if (user && user !== undefined 
                                        && user !== null && user.AccountId 
                                        && user.AccountId !== undefined && user.AccountId !== null ) 
                                    {
                                        if (user.Account.Max_of_Services_Quarter__c  !== undefined && user.Account.Max_of_Services_Quarter__c!== null) 
                                        {
                                            component.set("v.availableRequests",user.Account.Max_of_Services_Quarter__c);
                                        }
                                        if (user.Account.requests_this_quarter__c  !== undefined && user.Account.requests_this_quarter__c!== null) 
                                        {
                                            component.set("v.thisMonthRequests",user.Account.requests_this_quarter__c);
                                        }
                                    }                                    
                                }
                                else if (state === 'INCOMPLETE'){
                                    console.log ('Exception in reteiving Data :' )
                                } 
                                    else if (state === 'ERROR'){
                                    console.log ('Exception in reteiving Data :' + response.getError ());
                                }
                                
                            });
        $A.enqueueAction (action);

    }
})