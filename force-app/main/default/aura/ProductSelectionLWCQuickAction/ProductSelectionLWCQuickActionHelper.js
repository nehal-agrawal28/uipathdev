({
    showToast : function(message, title, type)
    {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "title": title,
            "type": type
        });
        toastEvent.fire();
    }
})