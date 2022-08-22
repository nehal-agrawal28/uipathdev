({
    doInit:function(cmp,event,helper){
        cmp.set("v.showSpinner",true);
        var action=cmp.get("c.expertRequest");
        
        action.setParams({"RecordId": cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                var parentcasStatus = response.getReturnValue().parentCaseStatus; //Added by Maanas 12/6/2019 to prevent ER creation on closed cases.
                if(parentcasStatus == 'Closed'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "Cannot create Expert Request Case when Parent Case status is closed.",
                        "type": "error"
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire()             
                }else{
                    var caseObj = cmp.get('v.erCaseRec');
                    caseObj = response.getReturnValue().associatedCases[0];
                    caseObj.ParentId = cmp.get('v.recordId');
                    caseObj.Status = 'New';
                    delete caseObj['Id'];
                    cmp.set('v.erCaseRec',caseObj);
                    cmp.set("v.erCaseRec.RecordTypeId",response.getReturnValue().expertReqRecTypeId);
                    console.log('caseObj'+JSON.stringify(caseObj));
                    var ownerid = response.getReturnValue().QueID;
                    cmp.set("v.ownerId",ownerid);
                    cmp.set('v.saved', true);       
                }
                cmp.set("v.showSpinner",false);
            }
            else if(state === 'ERROR'){
                
                
            }
        })
        $A.enqueueAction(action); 
    },
    
    handleLoad: function(cmp, event, helper) {
        cmp.set('v.showSpinner', false);
    },
    
    handleError: function(cmp, event, helper) {
        // errors are handled by lightning:inputField and lightning:messages
        // so this just hides the spinner
        cmp.set('v.showSpinner', false);
    },
    
    handleSuccess: function(cmp, event, helper) {
        $A.get("e.force:refreshView").fire();
        
        cmp.set('v.showSpinner', false);
        cmp.set('v.saved', false);
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The case has been created.",
            "type": "success"
        });
        toastEvent.fire();
        
        var navService = cmp.find("navService");
        var params = event.getParams();
        console.log('params',params.response.id);
        
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": params.response.id,
            "slideDevName": "related"
        });
        navEvt.fire();
    },
    
    
    handleClick: function(cmp, event, helper ){
        
        cmp.set('v.saved', true);
        
    },
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.saved", false);
    },
    
    handleSubmit: function(cmp,event,helper){
        cmp.set('v.showSpinner', true);
        event.preventDefault();
        var fields = event.getParam("fields");
        fields["OwnerId"] = cmp.get("v.ownerId");
        fields["RecordTypeId"] = cmp.get("v.erCaseRec.RecordTypeId");
        console.log(JSON.stringify(fields));
        cmp.find("form").submit(fields);
    },
    
    /*Added by Maanas: Using apex to create case instead of and commenting above LDS code as Owner assignment cannot be done via LDS*/
    createCase: function(cmp,event,helper){ 
        debugger;
        cmp.set("v.showSpinner",true);
        cmp.set('v.disableSave',true);
        //cmp.set("v.erCaseRec.RecordTypeId",'01236000001QF1D');
        var caseRec = cmp.get('v.erCaseRec');
        console.log(JSON.stringify(caseRec));
        var action=cmp.get("c.createERCase");
        
        action.setParams({"caseObj": caseRec});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                var recId  =response.getReturnValue();
                cmp.set('v.showSpinner', false);
                cmp.set('v.saved', false);
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The case has been created.",
                    "type": "success"
                });
                toastEvent.fire();
                
                var navService = cmp.find("navService");
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recId,
                    "slideDevName": "related"
                });
                navEvt.fire();   
            }
            else if(state === 'ERROR'){
                var errors = response.getError();
                if (errors) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": errors[0].message,
                        "type": "error"
                    });
                    toastEvent.fire();
                }     
            }
        });
        $A.enqueueAction(action); 
    }
    
})