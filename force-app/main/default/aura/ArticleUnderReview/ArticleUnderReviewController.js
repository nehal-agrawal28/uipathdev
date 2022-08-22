({
    doInit : function(component, event, helper) {
        let changeType = event.getParams().changeType;
        if (changeType === "ERROR") { 
            alert(component.get("v.recordLoadError"));
        }
        else if (changeType === "LOADED") { 
            helper.onInit(component, event);
        }
            else if (changeType === "REMOVED") { 
                
            }
                else if (changeType === "CHANGED") {  
                    component.find("recordLoader").reloadRecord(true);
                    
                }                                                   
    },
    startTechnicalReview : function(component, event, helper){
        event.getSource().set("v.disabled",true);
        let userId = component.get("v.wrapper").userId;
        let knowledgeObj = {};
        knowledgeObj.Id = component.get("v.recordId");
        knowledgeObj.Technical_Reviewer__c = userId;
        knowledgeObj.ValidationStatus = "Under Technical Review";
        //component.set("v.targetRecord.Technical_Reviewer__c",userId);
        //component.set("v.targetRecord.ValidationStatus","Under Technical Review");
        //obj.ValidationStatus = "Under Technical Review";
        //component.set("v.targetRecord",obj);
        helper.saveRecord(component, event, knowledgeObj);
        
    },
    startQualityReview : function(component, event, helper){
        event.getSource().set("v.disabled",true);
        let userId = component.get("v.wrapper").userId;
        let knowledgeObj = {};
        knowledgeObj.Id = component.get("v.recordId");
        knowledgeObj.Quality_Reviewer__c = userId;
        knowledgeObj.ValidationStatus = "Under Quality Review";
        //component.set("v.targetRecord.Quality_Reviewer__c",userId);
        //component.set("v.targetRecord.ValidationStatus","Under Quality Review");
        helper.saveRecord(component, event,knowledgeObj);
    },
    handleSubmit : function(component, event, helper){
        component.set("v.showSpinner",true);
        component.find("knowledgeForm").submit();
    },
    handleSuccess : function(component, event, helper){
        component.set("v.isRecordChanged",false);
        component.set("v.showSpinner",false);
        let toast = $A.get("e.force:showToast");
        toast.setParams({
            type : "success",
            message : "Knowledge Article was saved successfully."
        });
        toast.fire();
        //component.set("v.hideTechnicalDetails",true);
    },
    handleError : function(component, event, helper){
        component.set("v.showSpinner",false);
    },
    publishArticle : function(component, event, helper){
        let action = component.get("c.publishKnowledgeArticle");
        action.setParams({
            recordId : component.get("v.recordId"),
            articleId : component.get("v.knowledgeRecord.KnowledgeArticleId")
        });
        action.setCallback(this, function(response){
            let toastMessage = $A.get("e.force:showToast");
            if(response.getState()==="SUCCESS"){
                if(response.getReturnValue()){
                    toastMessage.setParams({
                        type: "success",
                        message: "Article Published Successfully!"
                    });
                    toastMessage.fire();
                    $A.get("e.force:refreshView").fire();
                }else{
                    toastMessage.setParams({
                        type: "error",
                        message: "System encountered an error. Please contact your System Administrator."
                    });
                    toastMessage.fire();
                }
            }else{
                toastMessage.setParams({
                    type: "error",
                    message: "System encountered an error. Please contact your System Administrator."
                });
                toastMessage.fire();
            }
            
        });
        $A.enqueueAction(action);
    },
    createAQIRecord : function(component, event, helper){
        var createRecordEvent = $A.get("e.force:createRecord");
    	createRecordEvent.setParams({
        	"entityApiName": "Article_Quality_Index__c",
            "defaultFieldValues": {
        		'Knowledge__c' : component.get("v.recordId"),
        		'Evaluated_Engineer__c' : component.get("v.knowledgeRecord.CreatedById")
    		}
    	});
    createRecordEvent.fire();
    },
    handleRecordChanged : function(component, event, helper){
        component.set("v.isRecordChanged",true);
    }
})