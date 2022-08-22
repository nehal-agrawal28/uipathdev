({
    getServiceType : function(component) {
        var pickvar = component.get("c.getServiceTypes");
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
    getQuestions:function(component,val)
    {
        var action = component.get("c.getQuestions");
        action.setParams({"ServiceType":val});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                var list = response.getReturnValue();
               // component.set("v.questions", list);
                var newArray = new Object();
                var PsJSON_List=[];
                component.set("v.Serviceobjlist",PsJSON_List);
                console.log(typeof(PsJSON_List));
                if(list!=null)
                {
                    
                    component.set("v.isQuestions",true);
                    component.set("v.Servdesc",list[0]["Servicedesc"])
                    for(let i in list)
                    {
                        var PsJSON_Obj = {
                           // sObject : 'Premium_Service__c',
                            Service_Type__c:val ,
                            Question__c:list[i]["Question"],
                            Question_Response__c:'',
                            Case__c:''
                        };
                         PsJSON_List.push(PsJSON_Obj);
                        }
                  component.set("v.Serviceobjlist",PsJSON_List);
                }
                
                else
                {
                    component.set("v.isQuestions",false);
                     component.set("v.Servdesc","");
                }
            }
            else if(state === 'ERROR'){
                
                alert('ERROR OCCURED.');
                component.set("v.isQuestions",false);  
                component.set("v.Servdesc","");
            }
        })
        $A.enqueueAction(action); 
    },
    CreateService:function(component)
    {
        let self = this;
        component.set("v.showLoadingSpinner", true);
      var PsJSON_List=component.get("v.Serviceobjlist");
        var PSListJSON=JSON.stringify(PsJSON_List);
        var action = component.get("c.createPremiumServiceCase");
        action.setParams({"PS_responseList":PSListJSON});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                //var list = response.getReturnValue();
                if (response.getReturnValue()!= null){
                    component.set("v.CaseObj",response.getReturnValue());
                    
                    component.set("v.CaseId",response.getReturnValue().Id);
                    component.set("v.showLoadingSpinner", false);
                    //Case is successfully created with Number #. You can also view your case in Premium Service Case List View
                    var successmsg= "Case is successfully created with Number #"+ response.getReturnValue().CaseNumber +". You can also view your case in Premium Service Case List View";
                  this.createModal (component,true,"Success",successmsg);  
                }
                else
                {
                      component.set("v.showLoadingSpinner", false);
                  this.createModal (component, false,"Error", $A.get("$Label.c.Error_Case_Creation_Msg"));  
                }
                
            }
           
            else if(state === 'ERROR'){
                component.set("v.showLoadingSpinner", false);
                this.createModal (component, false, "Error", $A.get("$Label.c.Error_Case_Creation_Msg"));
               // alert('ERROR OCCURED.');
                //component.set("v.isQuestions",false);  
            }
            
        })
         $A.enqueueAction(action);
    },
    createModal : function (component, isSuccess, title, description) {
        component.set ('v.modalTitle', title);
        component.set ('v.isSuccess', isSuccess);
        component.set ('v.errorMessage', description);
        component.find ('alertModal').show ();
    },
        
    
    
})