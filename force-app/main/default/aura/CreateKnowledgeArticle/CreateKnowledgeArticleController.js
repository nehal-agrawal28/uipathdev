({
    doInit : function(component, event, helper) {
        //const urlparams = new URLSearchParams(window.location.search)        
        if(window.location.href.includes('c__CreateKnowledgeArticle')){
            component.set("v.showSpinner",true);
            if(window.location.href.includes('c__caseid')){
                let caseId = window.location.search.split("c__caseid=")[1];
                if(caseId && caseId.includes("&")){
                    caseId = caseId.split("&")[0];
                }
                component.set("v.caseId",caseId);
            }
            
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({"tabId" : focusedTabId , "label" : "New Article"});
                workspaceAPI.setTabIcon({"tabId" : focusedTabId , "icon" : "standard:knowledge","iconAlt":"Knowledge"});
            })
            .catch(function(error) {
                console.log(error);
            });
            let metadataServerCall = component.get("c.getFieldMetadata");
            metadataServerCall.setParams({
                "caseId" : component.get("v.caseId")
            });
            metadataServerCall.setCallback(this, function(response){
                if(response.getState()==="SUCCESS"){
                    let wrapper = response.getReturnValue();
                    if(wrapper.isCreateable){
                        let studioVersions = [];
                        for(let key in wrapper.studioVersions){
                            let obj = {};
                            obj.label = wrapper.studioVersions[key];
                            obj.value = key;
                            studioVersions.push(obj);
                        }
                        let orchestratorVersions = [];
                        for(let key in wrapper.orchestratorVersions){
                            let obj = {};
                            obj.label = wrapper.orchestratorVersions[key];
                            obj.value = key;
                            orchestratorVersions.push(obj);
                        }
                        let prodCompMapping = [];
                        for(let key in wrapper.productComponentPicklistMappings){
                            if(key!='Attended browser embedding SDK' && key!='IT Automation'){
                                let obj = {};
                                obj.label = wrapper.productComponentPicklistMappings[key];
                                obj.value = key;
                                /* if(key=="AI Fabric"){
                            obj.label = "AI Center";
                            obj.value = "AI Fabric";
                        }*/
                                prodCompMapping.push(obj);
                            }
                        }
                        let productCompValues = Object.keys(wrapper.prodCompAndSubCompValues);
                        let indexAttendedBrow = productCompValues.indexOf('Attended browser embedding SDK');
                        if(indexAttendedBrow>-1)
                        	productCompValues.splice(indexAttendedBrow,1);
                        let indexITAuto = productCompValues.indexOf('IT Automation');
                        if(indexITAuto>-1)
                        	productCompValues.splice(indexITAuto,1);
                        component.set("v.prodCompAndSubCompValues",wrapper.prodCompAndSubCompValues);
                        component.set("v.productComponentValues",productCompValues);
                        component.set("v.prodCompAndVersionValues",wrapper.prodCompAndVersionValues);
                        component.set("v.studioVersionOptions",studioVersions);
                        component.set("v.orchestratorVersionOptions",orchestratorVersions);
                        component.set("v.productComponentMappings",prodCompMapping);
                        if(wrapper.caseObj){
                            let productCompArr = Array.from(component.get("v.productComponentValues"));                          
                            let selectProdComp = prodCompMapping.find(obj=>obj.value==wrapper.caseObj.Related_To__c);
                            if(productCompArr && selectProdComp && productCompArr.includes(selectProdComp.label)){
                                component.set("v.productComponent",selectProdComp.label);
                                component.set("v.subComponent",wrapper.caseObj.Sub_Component__c == 'UiAutomation' ? 'UIAutomation Classic' : wrapper.caseObj.Sub_Component__c );
                                component.set("v.productComponentVersion",wrapper.caseObj.Product_Component_Version__c);
                                component.set("v.subComponentValues",wrapper.prodCompAndSubCompValues[selectProdComp.label]);
                                component.set("v.productComponentVersionValues",wrapper.prodCompAndVersionValues[selectProdComp.label]);
                            }
                            else{
                                component.set("v.productComponent",productCompArr[0]);
                                component.set("v.subComponentValues",wrapper.prodCompAndSubCompValues[productCompArr[0]]);
                                component.set("v.productComponentVersionValues",wrapper.prodCompAndVersionValues[productCompArr[0]]);
                                component.set("v.productComponentVersion","");
                            }
                            let studioValues = [];
                            studioValues.push(wrapper.caseObj.Studio_Version__c);
                            component.set("v.studioVersionValues",studioValues);
                            let orcValues = [];
                            orcValues.push(wrapper.caseObj.Orchestrator_Version__c);
                            component.set("v.orchestratorVersionValues",orcValues);
                        }else{
                            let prodCompArr = Array.from(component.get("v.productComponentValues"));
                            component.set("v.productComponent",prodCompArr[0]);
                            component.set("v.subComponentValues",wrapper.prodCompAndSubCompValues[prodCompArr[0]]);
                            component.set("v.productComponentVersionValues",wrapper.prodCompAndVersionValues[prodCompArr[0]]);
                            component.set("v.productComponentVersion","");
                        }
                        
                        
                        helper.setKnowledgeObject(component, event, wrapper.caseObj);
                    }
                    else{
                        var workspaceAPI = component.find("workspace");
                        workspaceAPI.getFocusedTabInfo().then(function(response) {
                            let toastEvt = $A.get("e.force:showToast");
                            toastEvt.setParams({
                                "type" : "error",
                                "message" : "You do not have access to create articles."
                            });
                            toastEvt.fire();
                            var focusedTabId = response.tabId;
                            workspaceAPI.closeTab({tabId: focusedTabId});
                        })
                        .catch(function(error) {
                            console.log(error);
                        });
                    }
                    component.set("v.showSpinner",false);
                }else if(response.getState()==="ERROR"){
                    component.set("v.hasAccess",false);
                    component.set("v.showSpinner",false);
                    let toastEvt = $A.get("e.force:showToast");
                    toastEvt.setParams({
                        "type" : "error",
                        "message" : JSON.stringify(response.getError())
                    });
                    toastEvt.fire();
                }
            });
            $A.enqueueAction(metadataServerCall);
        }
    },
    closeFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
        
    },
    handleProductComponentChange : function(component, event, helper) {
        let kaObj = component.get("v.knowledgeObj");
        let selectedValue = kaObj.Product_Component__c;
        let valueMap = component.get("v.prodCompAndSubCompValues");
        let versionValueMap = component.get("v.prodCompAndVersionValues");
        component.set("v.productComponent",selectedValue);
        component.set("v.subComponentValues",valueMap[selectedValue]);
        component.set("v.productComponentVersionValues",versionValueMap[selectedValue]);
        kaObj.Sub_Component__c = valueMap[selectedValue][0];
        kaObj.Product_Component_Version__c = versionValueMap[selectedValue][0];
        component.set("v.knowledgeObj",kaObj);
        
    },
    
    clickCreate : function(component, event, helper) {
        event.getSource().set("v.disabled",true);
        let validArticleFields = component.find('articleForm').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        
        /*var validArticleRichTextFields = component.find('richText').reduce(function (validSoFar, inputCmp) {
            inputCmp.set("v.valid",inputCmp.get('v.value') ? true : false);
            return validSoFar && inputCmp.get('v.value');
        }, true);*/
        let inputCmp = component.find('richText');
        inputCmp.set("v.valid",inputCmp.get('v.value') ? true : false);
        let  validArticleRichTextFields = inputCmp.get('v.value') ? true : false;
        
        if(validArticleFields && validArticleRichTextFields){
            component.set("v.showSpinner",true);
            helper.createArticle(component, event);
        }else{
            let toastEvt = $A.get("e.force:showToast");
            toastEvt.setParams({
                "type" : "error",
                "message" : "Please review below errors"
            });
            toastEvt.fire();
            event.getSource().set("v.disabled",false);
        }
    },
    
    setUrlName : function(component, event, helper){
        let kaObj = component.get("v.knowledgeObj");
        let str = kaObj.Title;
        str = str.replace(/\s+/g, '-');
        kaObj.UrlName = str;
        component.set("v.knowledgeObj",kaObj);
    }
})