({
    
    handleSuccess: function(cmp, event, helper) {
        
        cmp.set("v.reloadForm", false);
        cmp.set("v.reloadForm", true);
        cmp.set("v.disableSave",false);     
        cmp.set("v.spinner",false);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "Living Summary Updated!",
            "type": "success"
        });
        toastEvent.fire();
        
        //setTimeout(window.location.reload(),2000);
        /* var params = event.getParams();
        
 		 var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": params.response.id,
                "slideDevName": "detail"
            });
            navEvt.fire();
        
        debugger;*/
          $A.get('e.force:refreshView').fire();
          
          
          
      },
    
    handleClick: function(cmp, event, helper ){
        event.preventDefault();
        cmp.set("v.disableSave",true);
        cmp.set("v.spinner",true); 
        cmp.set('v.saved', true);
        var fields = event.getParam('fields');
        cmp.find('myRecordForm').submit(fields);
        
    },
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.saved", false);
    },
    
})