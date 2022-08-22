({
    doInit : function(component, event, helper) {
        let sObjectName = component.get("v.sObjectName");
        let fieldSet = component.get("v.fieldSet");
        let recordId = component.get("v.recordId");

        if(!$A.util.isEmpty(sObjectName) && !$A.util.isEmpty(fieldSet)){
            let action = component.get("c.getInitialData");
            action.setParam("sObjectName", sObjectName);
            action.setParam("fieldSetName", fieldSet);
            action.setParam("recordId", recordId);
            action.setCallback(this,function(response){
                component.set("v.showSpinner", false);
                
                if(response.getState() === "SUCCESS"){
                    let wrapper = response.getReturnValue();
                    component.set("v.fieldList", wrapper.fieldList);

                    if(wrapper.isObjectUpdateable == false){
                        component.set("v.isObjectUpdateable", false);
                        component.set("v.formLoading", false);
                    }
                }
                else{
                    console.log('Error FieldsetUIController.getInitialData:' + JSON.stringify(response.getError()));
                    helper.showToast('error','Error','Something went wrong while fetching fieldset data');
                }
            });
            action.setStorable(true);
            $A.enqueueAction(action);
        }
    },

    handleEdit : function(component, event, helper) {
        component.set("v.isEdit", true);
    },
    
    handleSubmit : function(component, event, helper) {
        component.set("v.showSpinner", true);
    },

    handleError : function(component, event, helper) {
        component.set("v.hasError", true);
        component.set("v.showSpinner", false);
    },

    handleSuccess : function(component, event, helper) {
        component.set("v.hasError", false);
        helper.showToast('success','Success','Record saved successfully');
        component.set("v.isEdit", false);
        component.set("v.showSpinner", false);

        $A.get("e.force:refreshView").fire();
    },

    handleCancel : function(component, event, helper) {
        component.set("v.hasError", false);
        component.set("v.isEdit", false);
    },

    handleLoad : function(component, event, helper) {
        component.set("v.formLoading", false);
    }
})