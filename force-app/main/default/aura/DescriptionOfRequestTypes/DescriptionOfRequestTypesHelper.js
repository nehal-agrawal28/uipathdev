({
	findAccountType : function(component) {
        let action = component.get ('c.getAccountInfo');
        action.setCallback (this, function (response)
                            {
                                let state = response.getState ();
                                if (state === 'SUCCESS') 
                                {	
                                    
                                    let result = response.getReturnValue ();
                                    if (result && JSON.parse(result).status && JSON.parse(result).status === true) 
                                    {
                                        let user = JSON.parse(result).result;
                                        if (user && user !== undefined 
                                            && user !== null && user.AccountId 
                                            && user.AccountId !== undefined && user.AccountId !== null ) 
                                        {
                                            var accountId = user.AccountId;
                                            var contactId = user.ContactId;
                                            var technicalAdvisor = user.Account.Support_Technical_Advisor__c;
                                            component.set("v.accountName", user.Account.Name);
                                            component.set("v.contactName", user.Contact.Name);
                                            component.set("v.accId",accountId);
                                            component.set("v.contactId",contactId);
                                            component.set("v.TechSupportId",technicalAdvisor);
                                            if (true || user.Account.Maintenance_Flag__c  
                                                && user.Account.Maintenance_Flag__c  !== undefined
                                                && user.Account.Maintenance_Flag__c  !== null
                                                && user.Account.Maintenance_Flag__c .toLowerCase() === 'premium') 
                                            {
                                                var action = component.get("c.getQuestionsforDescription");
                                                action.setParams({"accountType":"Premium"});
                                                action.setCallback(this, function(response) {
                                                    var state = response.getState();
                                                    if(state === 'SUCCESS'){
                                                        var list = response.getReturnValue();
                                                        // component.set("v.questions", list);
                                                        console.log('list',list);
                                                        var newArray = new Object();
                                                        var PsJSON_List=[];
                                                        var rtypes = [];
                                                        component.set("v.Serviceobjlist",PsJSON_List);
                                                        console.log(PsJSON_List);
                                                        if(list!=null)
                                                        {
                                                            for(var key in list){
                                                                var associatedServiceTypes = list[key];
                                                                var mapContent = {};
                                                                mapContent[associatedServiceTypes.RequestType] = associatedServiceTypes;
                                                                PsJSON_List.push(mapContent);
                                                                rtypes.push(associatedServiceTypes.RequestType);
                                                            }
                                                            component.set("v.isQuestions",true);
                                                            component.set("v.Serviceobjlist",PsJSON_List);
                                                            component.set("v.requestTypes",rtypes);
                                                            component.set("v.selectedRequestType",rtypes[0]);
                                                            component.set("v.selectedRequest",PsJSON_List[0][rtypes[0]]);
                                                        }
                                                        
                                                        else
                                                        {
                                                            component.set("v.isQuestions",false);
                                                            component.set("v.Servdesc","");
                                                        }
                                                    }
                                                    else if(state === 'ERROR'){

                                                        component.set("v.isQuestions",false);  
                                                        component.set("v.Servdesc","");
                                                    }
                                                })
                                                $A.enqueueAction(action); 
                                                
                                            }
                                            else if(user.Account.RecordType.Name === 'Customer')
                                            {
                                                var action = component.get("c.getQuestionsforDescription");
                                                action.setParams({"accountType":"Customer"});
                                                action.setCallback(this, function(response) {
                                                    var state = response.getState();
                                                    if(state === 'SUCCESS'){
                                                        var list = response.getReturnValue();
                                                        // component.set("v.questions", list);
                                                        
                                                        var newArray = new Object();
                                                        var PsJSON_List=[];
                                                        var rtypes = [];
                                                        component.set("v.Serviceobjlist",PsJSON_List);
                                                        
                                                        if(list!=null)
                                                        {
                                                            for(var key in list){
                                                                var associatedServiceTypes = list[key];
                                                                var mapContent = {};
                                                                mapContent[key] = associatedServiceTypes;
                                                                PsJSON_List.push(mapContent);
                                                                rtypes.push(key);
                                                            }
                                                            component.set("v.isQuestions",true);
                                                            component.set("v.Serviceobjlist",PsJSON_List);
                                                            component.set("v.requestTypes",rtypes);
                                                            component.set("v.selectedRequestType",rtypes[0]);
                                                            component.set("v.selectedRequest",PsJSON_List[0][rtypes[0]]);
                                                        }
                                                        
                                                        else
                                                        {
                                                            component.set("v.isQuestions",false);
                                                            component.set("v.Servdesc","");
                                                        }
                                                    }
                                                    else if(state === 'ERROR'){

                                                        component.set("v.isQuestions",false);  
                                                        component.set("v.Servdesc","");
                                                    }
                                                })
                                                $A.enqueueAction(action);
                                                
                                            }
                                            else if(user.Account.RecordType.Name === 'Partner')
                                            {
                                                var action = component.get("c.getQuestionsforDescription");
                                                action.setParams({"accountType":"Partner"});
                                                action.setCallback(this, function(response) {
                                                    var state = response.getState();
                                                    if(state === 'SUCCESS'){
                                                        var list = response.getReturnValue();
                                                        // component.set("v.questions", list);
                                                        
                                                        var newArray = new Object();
                                                        var PsJSON_List=[];
                                                        var rtypes = [];
                                                        component.set("v.Serviceobjlist",PsJSON_List);
                                                        if(list!=null)
                                                        {
                                                            for(var key in list){
                                                                var associatedServiceTypes = list[key];
                                                                var mapContent = {};
                                                                mapContent[key] = associatedServiceTypes;
                                                                PsJSON_List.push(mapContent);
                                                                rtypes.push(key);
                                                            }
                                                            component.set("v.isQuestions",true);
                                                            component.set("v.Serviceobjlist",PsJSON_List);
                                                            component.set("v.requestTypes",rtypes);
                                                            component.set("v.selectedRequestType",rtypes[0]);
                                                            component.set("v.selectedRequest",PsJSON_List[0][rtypes[0]]);
                                                        }
                                                        
                                                        else
                                                        {
                                                            component.set("v.isQuestions",false);
                                                            component.set("v.Servdesc","");
                                                        }
                                                    }
                                                    else if(state === 'ERROR'){

                                                        component.set("v.isQuestions",false);  
                                                        component.set("v.Servdesc","");
                                                    }
                                                })
                                                $A.enqueueAction(action);
                                                
                                            }
                                        }
                                    }
                                    else 
                                    {
                                        
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
    },
    
    getServiceTypeforPartner : function(component) {
        var pickvar = component.get("c.getServiceTypesforPartner");
        pickvar.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                var list = response.getReturnValue();
                component.set("v.picvalue", list);
            }
            else if(state === 'ERROR'){
                
                alert('ERROR OCCURED.');
            }
        })
        $A.enqueueAction(pickvar);
    },
    showAssociatedDescription : function(component,event){

        var requestType = component.get("v.selectedRequestType");
        var requests = component.get("v.Serviceobjlist");
        requests= JSON.parse(JSON.stringify(requests));
        console.log('requests',requests);
        var requestMap = {};
        for(var i=0;i<requests.length;i++){
            var obj = requests[i];
            for(var key in obj){
                requestMap[key] = obj[key];
            }
            
        }
        console.log('requestMap',requestMap);
        var associatedServices = requestMap[requestType];  
        console.log('associatedServices',associatedServices);
        console.log('STYPE',associatedServices.ServiceType);
        component.set("v.selectedRequest",associatedServices);
    },
    getRecordType : function(component){
        let action = component.get ('c.getRecordType');
        action.setCallback (this, function (response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var recordTypeId = response.getReturnValue();
                console.log('recordTypeId',recordTypeId);
                component.set("v.TechSupportId", recordTypeId);
            }
        });
        $A.enqueueAction (action);
    },
    createModal : function (component, isSuccess, title, description) {
        component.set ('v.modalTitle', title);
        component.set ('v.isSuccess', isSuccess);
        component.set ('v.errorMessage', description);
        component.find ('alertModal').show ();
    },
    getQuestions:function(component,val)
    {
        var action = component.get("c.getQuestionsforDescription");
        var acctType = component.get("v.accountType")
        action.setParams({"accountType":acctType});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                var list = response.getReturnValue();
                // component.set("v.questions", list);
                
                var newArray = new Object();
                var PsJSON_List=[];
                var rtypes = [];
                component.set("v.Serviceobjlist",PsJSON_List);
                console.log(PsJSON_List);
                if(list!=null)
                {
                    for(var key in list){
                        var associatedServiceTypes = list[key];
                        var mapContent = {};
                        mapContent[key] = associatedServiceTypes;
                        console.log('mapContent',mapContent);
                        PsJSON_List.push(mapContent);
                        rtypes.push(key);
                    }
                    component.set("v.isQuestions",true);
                    component.set("v.Serviceobjlist",PsJSON_List);
                    component.set("v.requestTypes",rtypes);
                    component.set("v.selectedRequestType",rtypes[0]);
                    component.set("v.selectedRequest",PsJSON_List[0][rtypes[0]]);
                }
                
                else
                {
                    component.set("v.isQuestions",false);
                    component.set("v.Servdesc","");
                }
            }
            else if(state === 'ERROR'){

                component.set("v.isQuestions",false);  
                component.set("v.Servdesc","");
            }
        })
        $A.enqueueAction(action); 
    },
    setUpIframe : function (component, event) {

        
        //let path = window.location.pathname[window.location.pathname.length - 1] === '/' ? window.location.pathname : window.location.pathname + '/';
        
        component.set('v.lcHost', window.location.hostname);
        console.log('window.location.hostname,',window.location.hostname);
       // let frameSrc = 'https://servcloud2-uipath.cs24.force.com/customer/apex/UploadFilePage?&lcHost=servcloud2-uipath.cs24.force.com';
        let path = window.location.pathname.split('/').filter(function(e){ return e.replace(/(\r\n|\n|\r)/gm,"")})[0] || 'customer'; 
        let frameSrc = '/' +path + '/' + "UploadFilePage?"  + '&lcHost=' + component.get ('v.lcHost');
        console.log('frameSrc:' , frameSrc);
        component.set('v.frameSrc', frameSrc);
        
        let self = this;
        window.addEventListener("message", function(event) {

            if(event.data.state == 'LOADED'){
                component.set('v.vfHost', event.data.vfHost);
                console.log('event.data.vfHost',event.data.vfHost);
                console.log('INSIDE');
            }
            
            if(event.data.state == 'ONFILEOVERSIZE'){
                component.set ('v.isFileSelected', false);
                self.createModal (component, false, 'Error', event.data.message);
            }
            if(event.data.state == 'ONFILESELECTED'){
                component.set ('v.isFileSelected', true);
                console.log('INSIDE3');
            }
            if(event.data.state == 'ONFILEDESELECTED'){
                component.set ('v.isFileSelected', false);
                console.log('INSIDE4');
            }
            
            if(event.data.state == 'fileUploadprocessed'){
                component.set("v.showLoadingSpinner", false);
                if (event.data.messageType && event.data.messageType === 'success') {
                    //self.createModal (component, true, 'Success', $A.get("$Label.c.Case_Success_Message"));
                } else {
                    //self.createModal (component, true, 'Success', $A.get("$Label.c.Case_Error_File_Upload") );
                }
            }
        }, false);
    },
    sendMessage: function(component, message){
        message.origin = window.location.hostname;
        var vfWindow = component.find("vfFrame").getElement().contentWindow;
        vfWindow.postMessage(message, component.get("v.vfHost")); 
    }

})