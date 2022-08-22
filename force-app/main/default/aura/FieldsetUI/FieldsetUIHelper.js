({
    showToast : function(type, title, message, mode){ 
        mode = mode || 'dismissible';
        let toast = $A.get("e.force:showToast");
        if(toast){
            toast.setParams({
                "type"   : type,
                "title"  : title,
                "message": message,
                "mode"   : mode
            }).fire();
        }
        else{
            alert(message);
        }
    }
})