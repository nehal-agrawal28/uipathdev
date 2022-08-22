({
    doInit : function(component, event, helper) {
        debugger;
        let Serviceobjlist={};
        
        helper.getServiceType (component);   
        
    },
     dateUpdate : function(component, event, helper) {
         var todayvalue=  event.getSource().get("v.value");
        
        var today = new Date();        
        var dd = today.getDate();
        var mm = today.getMonth() + 1; //January is 0!
        var yyyy = today.getFullYear();
     // if date is less then 10, then append 0 before date   
        if(dd < 10){
            dd = '0' + dd;
        } 
    // if month is less then 10, then append 0 before date    
        if(mm < 10){
            mm = '0' + mm;
        }
        
     var todayFormattedDate = yyyy+'-'+mm+'-'+dd;
        if(todayvalue != '' && todayvalue < todayFormattedDate){
            component.set("v.dateValidationError" , true);
        }else{
            component.set("v.dateValidationError" , false);
        }
    },
    callBackOnSuccess: function(component, event, helper)
    {
      //  window.location.reload(true);
         var sobjectId = component.get("v.CaseId");
    console.log(sobjectId);
    if (sobjectId.indexOf("500") >-1) { //Note 500 is prefix for Case Record
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/case/'+sobjectId,
            "isredirect" :false
        });
        urlEvent.fire();
    }
    },
    onChangeVal:function(component, event, helper) {
        var val = event.getSource().get("v.value");
        console.log('val'+val);
        if(val=="choose")
        {
            component.set("v.isQuestions",false);  
             component.set("v.Servdesc","");
        }
        else
        {
        helper.getQuestions(component,val);
        }
    },
    handleSubmitClick :function(component, event, helper) {
        
        helper.CreateService(component);
        
    }
    
    
})