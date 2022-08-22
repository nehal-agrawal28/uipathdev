({
    doInit : function(component, event, helper) {
        window.addEventListener("message", $A.getCallback(function(event) {
            if(event.data==="surveySubmitted"){
                helper.fetchAllDetails(component, event);
                component.set("v.currentCaseIndex",null);
            }
        }), false);
        document.title = 'UiPath Technical Support';
        component.set("v.articleColumns",[
            {label: 'Title', fieldName: 'Title', type: 'text',wrapText : true, initialWidth: 300},
            {label: 'Product Component', fieldName: 'Product_Component__c', type: 'text'},
            {label: 'Sub Component', fieldName: 'Sub_Component__c', type: 'text'},
            {   
                type:  'button',
                typeAttributes: {label: 'View', name: 'View Details', title: 'View Details', value: 'View Details', variant: 'brand'}
            }
        ]);
        component.set("v.articleSearchResultColumns",[
            {label: 'Title', fieldName: 'Title', type: 'text',wrapText : true},
            {label: 'Product Component', fieldName: 'Product_Component__c', type: 'text'},
            {label: 'Sub Component', fieldName: 'Sub_Component__c', type: 'text'},
            {label: 'Studio Version', fieldName: 'Studio_Version__c', type: 'text'},
            {label: 'Orchestrator Version', fieldName: 'Orchestrator_Version__c', type: 'text'},
            {   
                type:  'button',
                typeAttributes: {label: 'View', name: 'View Details', title: 'View Details', value: 'View Details', variant: 'brand'}
            }
            
        ]);
        component.set("v.caseSearchResultColumns",[
            {label: 'Case Number', fieldName: 'CaseNumber', type: 'text'},
            {label: 'Product Component', fieldName: 'Related_To__c', type: 'text'},
            {label: 'Subject', fieldName: 'Subject', type: 'text', wrapText:true},
            {label: 'Studio Version', fieldName: 'Studio_Version__c', type: 'text'},
            {label: 'Orchestrator Version', fieldName: 'Orchestrator_Version__c', type: 'text'},
            {   
                type:  'button',
                typeAttributes: {label: 'View', name: 'View Details', title: 'View Details', value: 'View Details', variant: 'brand'}
            }
        ]);
        let surveyPendingStart = new Date();
        surveyPendingStart.setDate(surveyPendingStart.getDate()-parseInt($A.get("$Label.c.CaseViewSurveyPendingTimeFrame")));
        component.set("v.surveyPendingStart",surveyPendingStart);
        let action = component.get("c.getContactDetails");
            action.setParams({
                "email" : component.get('v.caseEmail')
            });
            action.setCallback(this,function(response){
                if(response && response.getState()==="SUCCESS"){
                    component.set("v.contactObj",response.getReturnValue());
                    component.set("v.showLoginFlow",false);
                    helper.fetchAllDetails (component, event);
                } 
            });
            $A.enqueueAction(action);
    },
    /*validateEmailAndCaseNumber : function (component, event, helper) {
        let email = component.get ('v.caseEmail');
        helper.resetVal (component, ['v.errorMessage'], null);
        if (!email || email === undefined || email === '') {
            component.find ('caseEmail').setCustomValidity($A.get('$Label.c.Empty_Case_Email'));
            component.find ('caseEmail').reportValidity ();
            return;
        }else if(email==$A.get('$Label.c.UiPathSupportEmail')){
            component.find ('caseEmail').setCustomValidity('Access Restricted');
            component.find ('caseEmail').reportValidity ();
            return;
        }else {
            component.find ('caseEmail').setCustomValidity('');
            component.find ('caseEmail').reportValidity ();
        }
        if (helper.validateEmail (email)) {
            component.find ('caseEmail').setCustomValidity('');
            component.find ('caseEmail').reportValidity ();
        } else {
            component.find ('caseEmail').setCustomValidity($A.get('$Label.c.Empty_Case_Email'));
            component.find ('caseEmail').reportValidity ();
            return;
        }
        helper.validateEmailAndCaseNumber (component, event, email);
    },*/
    closeModel : function (component, event, helper) {
        //helper.toggleOTPModal (component, false);
    },
    /*validateOTP : function (component, event, helper) {
        let userOTP = component.get ('v.userEnteredOTP');
        //let sysOTP 	= component.get ('v.systemGeneratedOTP');
        
        if (!userOTP) {
            component.find ('otpInput').setCustomValidity($A.get('$Label.c.Empty_OTP'));
            component.find ('otpInput').reportValidity ();
        } else {
            component.find ('otpInput').setCustomValidity('');
            component.find ('otpInput').reportValidity ();
        }
        component.set("v.showLoadingSpinner",true);
        let action = component.get("c.checkOTPValidity");
        action.setParams({
            "otp" : userOTP,
            "email" : component.get ('v.caseEmail')
        });
        action.setCallback(this, function(response){
            if(response.getState()==="SUCCESS"){
                let returnValue = JSON.parse(response.getReturnValue());
                if(returnValue && returnValue.valid){
                    if(window.sessionStorage){
                        sessionStorage.setItem("CaseViewSession",component.get ('v.caseEmail'));
                    }
                    helper.fetchAllDetails (component, event);
                    helper.toggleOTPModal (component, false);
                }
                else{
                    component.find ('otpInput').setCustomValidity($A.get('$Label.c.Invalid_OTP'));
                    component.find ('otpInput').reportValidity ();
                }
            }else{
                component.find ('otpInput').setCustomValidity($A.get('$Label.c.Invalid_OTP'));
                component.find ('otpInput').reportValidity (); 
            }
            component.set("v.showLoadingSpinner",false);
        });
        $A.enqueueAction(action);
        if  (userOTP && sysOTP && Number (userOTP) === Number (sysOTP)) {
            
            if(window.sessionStorage){
                sessionStorage.setItem("CaseViewSession",component.get ('v.caseEmail'));
            }
            helper.fetchAllDetails (component, event);
            helper.toggleOTPModal (component, false);
        }  else {
            component.find ('otpInput').setCustomValidity($A.get('$Label.c.Invalid_OTP'));
            component.find ('otpInput').reportValidity ();
        }
    },*/
    checkIsNumber : function (component, event, helper) {
        let val = event.getSource().get ('v.value');
        if (val && val !== undefined && isNaN(val)) {
            val = val.substring (0, (val.length-1));
            event.getSource().set ('v.value', val);
        }
    },
    closeEmailModel : function (component, event, helper) {
        helper.toggleEmailModal (component, false);
    },
    openEmailPopup : function (component, event, helper) {
        let index = event.target.getAttribute ('data-index');
        if (index !== undefined) {
            helper.openEmailPopup (component, index);
        }
    },
    reset : function (component, event, helper) {
        
        /*if(window.sessionStorage && sessionStorage.getItem("CaseViewSession")){
            sessionStorage.removeItem("CaseViewSession");
        }*/
        window.location.reload();
        
    },
    getCaseDetails : function (component, event, helper) {
        let index = event.target.getAttribute ('data-index');
        if (index !== undefined) {
            helper.getCaseDetails (component, index);
        }
    },
    openKnowledgeArticle : function(component, event, helper){
        let urlName = event.getSource().get("v.name");
        let articles = component.get("v.knowledgeArticles");
        let knowledgeObj = articles.find(function(obj){
            return obj.UrlName === urlName;
        });
        if(knowledgeObj){
            component.set("v.articleObj",knowledgeObj);
            component.set("v.showKnowledgeArticle",true);
        }
    },
    hideKnowledgeArticle : function(component, event, helper){
        component.set("v.showKnowledgeArticle",false);
        component.set("v.articleObj",null);
    },
    handleTabChange : function(component, event, helper){
        let selectedTabId = component.get("v.selectedTabId");
        if(selectedTabId == "KnowledgeArticles"){
            component.set("v.currentTabString","Search Results");
        }else if(selectedTabId == "AllCaseDetails"){
            component.set("v.currentTabString","All Cases");
        }else if(selectedTabId == "CreateNewCase"){
            component.set("v.currentTabString","New Technical Case");
        }
        
    },
    handleHeaderTabClick : function(component, event, helper){
        component.set("v.selectedTabId",event.currentTarget.getAttribute("id"));
        if(component.get("v.selectedTabId") == "KnowledgeArticles"){
            component.set("v.showLoadingSpinner",true);
            let action = component.get("c.getAllArticles");
            action.setCallback(this, function(response){
                if(response.getState()==="SUCCESS"){
                    component.set("v.allKnowledgeArticles",response.getReturnValue());
                }
                component.set("v.showLoadingSpinner",false);
            });
            $A.enqueueAction(action);
        }
    },
    handleCreateCaseClick : function(component, event, helper){
        component.set("v.selectedTabId","CreateNewCase");
    },
    handleAllCasesClick : function(component, event, helper){
        component.set("v.selectedTabId","AllCaseDetails");
        helper.fetchAllDetails(component,event);
    },
    handleSearch : function(component, event, helper){
        if(component.get("v.searchText")){
            if (event.keyCode === 13) {
                component.set("v.selectedTabId","KnowledgeArticles");
            }
        }
        
    },
    handleRecordSelected : function(component, event, helper){
        component.set("v.selectedTabId","AllCaseDetails");
        let selectedRecord = component.get("v.selectedLookUpRecord");
        if(selectedRecord.Id && selectedRecord.Id.startsWith('ka0')){
            component.set("v.articleObj",selectedRecord);
            component.set("v.showKnowledgeArticle",true);
        }else if(selectedRecord.Id && selectedRecord.Id.startsWith('500')){
            let caseList = component.get("v.caseList");
            let index = caseList.findIndex(function(obj){
                return (obj.Id === selectedRecord.Id);
            });
            if(index > -1){
                helper.getCaseDetails(component, index);
            }
            
        }
    },
    handleRowAction : function(component, event, helper){
        component.set("v.articleObj",event.getParam("row"));
        component.set("v.showKnowledgeArticle",true);
    },
    handleEnterPressed : function(component, event, helper){
        component.set("v.selectedTabId","KnowledgeArticles");
    },
    handleSearchResultsChange : function(component, event, helper){
        let searchResults = component.get("v.searchResults");
        if(searchResults){
            let knowledgeResults = searchResults.filter(function(obj){
                return obj.Id.startsWith('ka0');
            });
            let caseResults = searchResults.filter(function(obj){
                return obj.Id.startsWith('500');
            });
            component.set("v.articleSearchResults",knowledgeResults);
            component.set("v.caseSearchResults",caseResults);
        }
        
    },
    handleArticleSearchRowAction : function(component, event, helper){
        component.set("v.articleObj",event.getParam("row"));
        component.set("v.showKnowledgeArticle",true);
    },
    handleCaseSearchRowAction : function(component, event, helper){
        let selectedRecord = event.getParam('row');
        let caseList = component.get("v.caseList");
        let index = caseList.findIndex(function(obj){
            return (obj.Id === selectedRecord.Id);
        });
        if(index > -1){
            helper.getCaseDetails(component, index);
            component.set("v.searchText","");
            component.set("v.selectedTabId","AllCaseDetails");
        }
    },
    handleCaseCreated : function(component, event, helper){
        component.set("v.selectedTabId","AllCaseDetails");
        helper.fetchAllDetails(component,event);
    },
    /*handleStatusChange : function(component, event, helper){
        if (event.getParam('status') === "FINISHED") {
            let outputVariables = event.getParam('outputVariables');
            for(let i=0;i<outputVariables.length;i++){
                if(outputVariables[i].name=="ContactEmail"){
                    component.set ('v.caseEmail',outputVariables[i].value);
                }
            }
            let action = component.get("c.getContactDetails");
            action.setParams({
                "email" : component.get('v.caseEmail')
            });
            action.setCallback(this,function(response){
                if(response && response.getState()==="SUCCESS"){
                    component.set("v.contactObj",response.getReturnValue());
                    component.set("v.showLoginFlow",false);
                    helper.fetchAllDetails (component, event);
                    helper.toggleOTPModal (component, false);
                } 
            });
            $A.enqueueAction(action);
            
        }
    }*/
})