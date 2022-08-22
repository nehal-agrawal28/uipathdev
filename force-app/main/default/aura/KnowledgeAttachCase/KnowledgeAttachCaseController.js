({
	attachCase : function(component, event, helper) {
        if(!component.get("v.selectedRecord")){
            helper.showToast("error","Please select a case to attach.");
            return;
        }
        component.set("v.disabled",true);
        let action = component.get("c.attachCaseToArticle");
        action.setParams({
            "kavId" : component.get("v.recordId"),
            "caseId" : component.get("v.selectedRecord").Id
        });
        action.setCallback(this, function(response){
            component.set("v.disabled",false);
            if(response.getState()==="SUCCESS"){
                $A.get("e.force:refreshView").fire();
                helper.showToast("success","Case attached successfully.");
                $A.get("e.force:closeQuickAction").fire();
            }else{
                helper.showToast("error","Unable to attach case to the article.");
            }
        });
        $A.enqueueAction(action);
	},
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
	}
})