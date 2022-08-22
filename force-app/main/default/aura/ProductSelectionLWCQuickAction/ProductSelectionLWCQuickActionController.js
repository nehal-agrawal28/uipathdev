({
    init: function(component, event, helper)
    {
        const action = component.get('c.getPriceBookAndCurrency');
        action.setParams({
            dealRegId: component.get('v.recordId')
        });
        action.setCallback(this, function(response)
        {
            const state = response.getState();
            if (state === 'SUCCESS')
            {
                const returnValue = response.getReturnValue();
                console.log({ returnValue });

                component.set('v.priceBookName', returnValue['priceBook']);
                component.set('v.currencyIsoCode', returnValue['currencyIsoCode']);
                component.set('v.finishedInit', true);
            }
        });

        $A.enqueueAction(action);
    },
    
    onclickAddProducts: function(component, event, helper)
    {
        const products = component.find("productSelectionCMP").getSelectedProducts()

        if(products.length)
        {
            const action = component.get('c.addProducts');
            action.setParams({
                dealRegId: component.get('v.recordId'),
                dealRegProducts: products
            });
            action.setCallback(this, function(response)
            {
                const state = response.getState();
                if(state === 'SUCCESS')
                {
                    const returnValue = response.getReturnValue();
                    console.log({returnValue});
    
                    $A.get("e.force:closeQuickAction").fire();
    
                    if(returnValue)
                        helper.showToast("Products were added successfully", "Success!", "success");
                    else
                        helper.showToast("Something went wrong, please contact the System Admin", "Error!", "error");
    
                    $A.get('e.force:refreshView').fire();
                }
                else
                {
                    helper.showToast("Something went wrong, please contact the System Admin", "Error!", "error");
                }
            });
    
            $A.enqueueAction(action);
        }
    },

    onclickNext: function(component, event, helper)
    {
        component.find("productSelectionCMP").toggleShowSelected()
    },

    onclickBack: function(component, event, helper)
    {
        component.find("productSelectionCMP").toggleShowSelected()
    },

    onclickCancel: function(component, event, helper)
    {
        $A.get("e.force:closeQuickAction").fire();
    },

    processShowSelectedChange: function(component, event, helper)
    {
        component.set('v.onSelectProductsScreen', !(event.getParam('showSelected')) );
        component.set('v.onSubmitProductsScreen', event.getParam('showSelected'));
    },

    processSelectedProductsLength: function(component, event, helper)
    {
        if(event.getParam('selectedProductsLength'))
            component.set('v.noProductsSelected', false);
        else
            component.set('v.noProductsSelected', true);
    },
})