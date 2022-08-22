({
    createArticle : function(component, event) {
        let action = component.get("c.createKnowledgeArticle");
        let knowledgeObj = component.get("v.knowledgeObj");
        knowledgeObj.Is_Valid__c = true;
        knowledgeObj.Product_Component__c = knowledgeObj.Product_Component__c == 'Insights' ? 'UiPath Insights' : knowledgeObj.Product_Component__c == 'Marketplace' ? 'UiPath Connect' : knowledgeObj.Product_Component__c == 'AI Center' ? 'AI Fabric' : component.get("v.productComponent");
        knowledgeObj.Sub_Component__c = knowledgeObj.Sub_Component__c == 'UIAutomation Classic' ? 'UiAutomation' : knowledgeObj.Sub_Component__c;
        action.setParams({
            "knowledgeObj" : knowledgeObj
        });
        action.setCallback(this, function(response){
            if(response.getState()==="SUCCESS"){
                let toastEvt = $A.get("e.force:showToast");
                toastEvt.setParams({
                    "type" : "success",
                    "message" : "Article was created successfully!"
                });
                toastEvt.fire();
                
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(resp) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                    
                    setTimeout(function(){
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": response.getReturnValue()
                        });
                        navEvt.fire();
                    },2000);
                    
                    
                })
                .catch(function(error) {
                    console.log(error);
                });
            }else if(response.getState()==="ERROR"){
                component.set("v.showSpinner",false);
                let errors = response.getError();
                let message = '';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    if(errors[0].message){
                        message += errors[0].message+'\n';
                    }
                    if(errors[0].fieldErrors){
                        for(let field in errors[0].fieldErrors){
                            message += errors[0].fieldErrors[field][0].message+'\n';
                        }
                    }
                    if(errors[0].pageErrors && errors[0].pageErrors.length>0){
                        message += errors[0].pageErrors[0].message+'\n';
                    }
                    
                }
                let toastEvt = $A.get("e.force:showToast");
                toastEvt.setParams({
                    "type" : "error",
                    "message" : message
                });
                toastEvt.fire();
                event.getSource().set("v.disabled",false);
            }
        });
        $A.enqueueAction(action);
    },
    setKnowledgeObject : function(component, event, caseObj){
        let kaObj = component.get("v.knowledgeObj");
        if(!kaObj){
            kaObj = {};
        }
        if(caseObj){
            kaObj.Case_Id__c = caseObj.Id; 
         	kaObj.Product_Component__c = kaObj.Product_Component__c ? kaObj.Product_Component__c : component.get("v.productComponent");
        	kaObj.Sub_Component__c = kaObj.Sub_Component__c ? kaObj.Sub_Component__c : component.get("v.subComponent");
            kaObj.Product_Component_Version__c = kaObj.Product_Component_Version__c ? kaObj.Product_Component_Version__c : component.get("v.productComponentVersion");
            let question = kaObj.Question_Problem__c ? kaObj.Question_Problem__c : caseObj.Problem__c;
            kaObj.Question_Problem__c = question ? question.replace(/<\/?[^>]+(>|$)/g, "") : '';
            kaObj.Resolution__c = kaObj.Resolution__c ? kaObj.Resolution__c : caseObj.Solution__c;
        	kaObj.Root_Cause__c = kaObj.Root_Cause__c ? kaObj.Root_Cause__c : caseObj.Cause__c;
        }else{
         	kaObj.Product_Component__c = kaObj.Product_Component__c ? kaObj.Product_Component__c : '';
        	kaObj.Sub_Component__c = kaObj.Sub_Component__c ? kaObj.Sub_Component__c : '';
            kaObj.Product_Component_Version__c = kaObj.Product_Component_Version__c ? kaObj.Product_Component_Version__c : '';
            let question = kaObj.Question_Problem__c ? kaObj.Question_Problem__c : '';
            kaObj.Question_Problem__c = question ? question.replace(/<\/?[^>]+(>|$)/g, "") : '';
            kaObj.Resolution__c = kaObj.Resolution__c ? kaObj.Resolution__c : '';
        	kaObj.Root_Cause__c = kaObj.Root_Cause__c ? kaObj.Root_Cause__c : '';
        }
        
        kaObj.Title = kaObj.Title ? kaObj.Title : '';
        kaObj.UrlName = kaObj.UrlName ? kaObj.UrlName : '';
        kaObj.Studio_Version__c = kaObj.Studio_Version__c ? kaObj.Studio_Version__c : component.get("v.studioVersionValues");
        kaObj.Orchestrator_Version__c = kaObj.Orchestrator_Version__c ? kaObj.Orchestrator_Version__c : component.get("v.orchestratorVersionValues");
        kaObj.Error__c = kaObj.Error__c ? kaObj.Error__c : '';
        kaObj.Related_Links__c = kaObj.Related_Links__c ? kaObj.Related_Links__c : '';
        kaObj.Internal_Notes__c = kaObj.Internal_Notes__c ? kaObj.Internal_Notes__c : '';
        kaObj.Review_Date1__c = kaObj.Review_Date1__c ? kaObj.Review_Date1__c : null;
        kaObj.Technical_content__c = true;
        kaObj.Is_confidential__c = kaObj.Is_confidential__c ? kaObj.Is_confidential__c :false;
        kaObj.Reason_for_Confidential__c = kaObj.Reason_for_Confidential__c ? kaObj.Reason_for_Confidential__c : '';
        kaObj.Is_confidential__c = kaObj.Is_Not_External__c ? kaObj.Is_Not_External__c :false;
        kaObj.Reason_for_Not_External__c = kaObj.Reason_for_Not_External__c ? kaObj.Reason_for_Not_External__c : '';
        kaObj.Reason_for_Removal__c = kaObj.Reason_for_Removal__c ? kaObj.Reason_for_Removal__c : '';
        component.set("v.knowledgeObj",kaObj);
    }
})