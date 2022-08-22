/* auraMethodController.js */
({
    retrieveCategoryItems : function(cmp, event) {
        var action = cmp.get("c.getCategoryItems"),
            params = event.getParam('arguments'),
            callback;

        if (params) {
            action.setParams({
                "groupName": params.groupName,
                "categoryName": params.categoryName
            });

            callback = params.callback;
        }

        action.setStorable();

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if (callback) callback(response.getReturnValue());

            }
        });

        $A.enqueueAction(action);
    },

    retrieveCategoriesParentage : function(cmp, event) {
        try {
            if (typeof event !== 'undefined') {
                var parentageAction = cmp.get("c.getCategoriesParentage"),
                    params = event.getParam('arguments'),
                    callback = params.callback;
                if (params.selectedCategories.length > 0) {
                    parentageAction.setParams({
                        "selectedCategories": params.selectedCategories,
                    });
                    //parentageAction.setStorable();//cannot be called on a client action.
                    parentageAction.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            if (callback) callback(response.getReturnValue());
                        }
                    });
                    $A.enqueueAction(parentageAction);
                } else {
                    if (typeof callback == 'function') callback('');
                }
            }
        }catch(ex){console.error(ex.message);}
    }

})