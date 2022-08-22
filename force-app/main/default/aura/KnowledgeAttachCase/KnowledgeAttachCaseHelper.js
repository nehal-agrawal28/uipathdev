({
	showToast : function(type, message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : type,
            "message" : message
        });
        toastEvent.fire();
	}
})