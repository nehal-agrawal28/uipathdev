({
    doInit : function(component, event, helper) {
        let action = component.get("c.getEscalationTaskWrapper");
        action.setParams({
            "caseId":component.get("v.pageReference").state.c__caseid
        });
        action.setCallback(this,function(response){
            if(response.getState()==="SUCCESS"){
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    component.set("v.tabId",focusedTabId);
                })
                .catch(function(error) {
                    console.log(error);
                });
                let wrapper = response.getReturnValue();
                let recordTypeId = wrapper.EscalationRecordType;
                var createTaskEvent = $A.get("e.force:createRecord");
                createTaskEvent.setParams({
                    "entityApiName": "Task",
                    "recordTypeId" : recordTypeId,
                    "defaultFieldValues": {
                        "Subject" : "Escalation for Case "+wrapper.caseObj.CaseNumber,
                        "WhatId" : wrapper.caseObj.Id,
                        "OwnerId" : wrapper.queueId,
                        "Initiator__c" : wrapper.userId
                    }
                });
                createTaskEvent.fire();
                window.setTimeout(function(){
                    var workspaceAPI = component.find("workspace");
                    workspaceAPI.closeTab({tabId: component.get("v.tabId")});
                },2000);
            }
        });
        $A.enqueueAction(action);
        
    }
})