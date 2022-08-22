({
	saveRecord1 : function(component, event) {
		component.find("recordLoader").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Save completed successfully.");
                 //$A.get('e.force:refreshView').fire();
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' +
                           JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
	},
    saveRecord : function(component, event, knowledgeObj) {
		let action = component.get("c.updateKnowledgeArticle");
        action.setParams({
            "knowledgeObj" : knowledgeObj
        });
        action.setCallback(this, function(response){
            if(response.getState()==="SUCCESS"){
                $A.get("e.force:refreshView").fire();
            }else{
                console.log("error"+response.getError());
                let toast = $A.get("e.force:showToast");
                toast.setParams({
                    type : "error",
                    message : "System encountered an error."
                });
                toast.fire();
                event.getSource().set("v.disabled",false);
            }
        });
        $A.enqueueAction(action);
	},
    onInit : function(component, event){
        let knowledgeRecord = component.get("v.knowledgeRecord");
        if(knowledgeRecord && knowledgeRecord.ValidationStatus != "Not Validated"
           && knowledgeRecord.ValidationStatus != "Rejected By Technical Reviewer"
           && knowledgeRecord.ValidationStatus != "Rejected By Quality Reviewer"
           && knowledgeRecord.PublishStatus =='Draft'
          ){
            
            let action = component.get("c.getReviewerData");
            action.setParams({
                "recordId" : component.get("v.recordId")
            });
            action.setCallback(this, function(response){
                if(response.getState()==="SUCCESS"){
                	let wrapper = response.getReturnValue();
                    component.set("v.wrapper",wrapper);  
                    let currentUserId = wrapper.userId;
                    let isTechnicalApprover = wrapper.technicalReviewers.some(function(obj){return obj.Id == currentUserId});
                    let isQualityApprover = wrapper.qualityReviewers.some(function(obj){return obj.Id == currentUserId});
                    component.set("v.isTechnicalApprover",isTechnicalApprover);
                    component.set("v.isQualityApprover",isQualityApprover);
                    if(knowledgeRecord.ValidationStatus == "Under Technical Review"){
                        let isCurrentReviewer = currentUserId == knowledgeRecord.Technical_Reviewer__c;
                        component.set("v.isCurrentReviewer",isCurrentReviewer);
                        let currentReviewer = wrapper.technicalReviewers.find(function(obj){
                            return obj.Id == knowledgeRecord.Technical_Reviewer__c;
                        });
                        component.set("v.currentReviewerName",currentReviewer ? currentReviewer.Name : "");
                    }else if(knowledgeRecord.ValidationStatus == "Under Quality Review"){
                        let isCurrentReviewer = currentUserId == knowledgeRecord.Quality_Reviewer__c;
                        component.set("v.isCurrentReviewer",isCurrentReviewer);
                        let currentReviewer = wrapper.qualityReviewers.find(function(obj){
                            return obj.Id == knowledgeRecord.Quality_Reviewer__c;
                        });
                        component.set("v.currentReviewerName",currentReviewer ? currentReviewer.Name : "");
                    }
                    component.set("v.isVisible",true);
                    // $A.get('e.force:refreshView').fire();
                }
                
            });
            $A.enqueueAction(action);
        }
        else{
            component.set("v.isVisible",false);
        }
    }
})