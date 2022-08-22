({
    doInit : function(component, event, helper) {
        
        let Serviceobjlist={};
        helper.findAccountType(component); 
        helper.getRecordType(component);
        try{
            helper.setUpIframe(component,event);
            
            component.set('v.showSpinner', false);    
            component.set('v.disabled',false);
        }
        catch(err){
            alert(err);
        }
    },
    showDescription : function(component,event,helper){
        helper.showAssociatedDescription(component,event);
    },
    
    changeDatecheck : function(cmp,event,helper){
        var value = cmp.get('v.startDate');
        if(value != null){
            var selectedDate = new Date(value);
            var today = new Date();
            today = new Date(today.getFullYear(),today.getMonth(),today.getDate());
            console.log('selectedDate',selectedDate);
            console.log('today',today);
            var check = (selectedDate.getTime()-today.getTime())/(1000 * 3600 * 24);
            var minimumDate = today.setDate(today.getDate() + 15); //number  of days to add, e.x. 15 days
            console.log('Check',check);
            if(check <= 0){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'Please do not select a date in the past',
                    duration:' 1000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                cmp.set("v.disabled",true);
                toastEvent.fire();
            }
            else{
                cmp.set("v.disabled",false);
            }
        }
        
    },
    
    handleClick: function(cmp, event, helper) {
        window.location.reload();
    },
    
    handleSubmitClick :function(cmp, event, helper) {
        
        if(!cmp.get('v.description')){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message:'Description is mandatory',
                duration:' 1000',
                key: 'info_alt',
                type: 'error',
                mode: 'pester'
            });
            toastEvent.fire();
            return;
        }
        
        if(!cmp.get('v.startDate')){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message:'Start Date is mandatory',
                duration:' 1000',
                key: 'info_alt',
                type: 'error',
                mode: 'pester'
            });
            toastEvent.fire();
            return;
        }
        cmp.set('v.disabled', true);
        cmp.set('v.showSpinner', true);
        let action = cmp.get("c.createPremiumServiceCase");
        action.setParams(
            {"stDate": cmp.get('v.startDate') ,
             "descr": cmp.get('v.description'),
             "subject" : cmp.get('v.selectedRequestType')
            }
        );
        action.setCallback(this, function(response) {
            let state = response.getState();
            if(state === 'SUCCESS'){
                cmp.set('v.showSpinner', false);
                cmp.set('v.saved', false);
                let local = response.getReturnValue();
                if (local.Id && local.Id != null) {
                    if (cmp.get ('v.isFileSelected') && cmp.get ('v.isFileSelected') === true) {
                        var message = {
                            "uploadFile" : true,
                            "parentId" : local.Id
                        };
                        helper.sendMessage(cmp, message);
                    }          
                }
                var successmsg= "Case is successfully created with Number #"+ local.CaseNumber +". You can also view your case in Proactive care Cases List View";
                helper.createModal (cmp,true,"Success",successmsg); 
                $A.get('e.force:refreshView').fire(); 
                cmp.set('v.startDate', '');
                cmp.set('v.description', '');
                cmp.set('v.disabled', false);
            }
            else if(state === 'ERROR'){
                cmp.set('v.showSpinner', false);
                cmp.set('v.disabled', false);
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errors[0].message);
                        helper.createModal (component, false, "Error", $A.get("$Label.c.Error_Case_Creation_Msg"));
                    }
                }
            }
        })
        $A.enqueueAction(action);
    }
})