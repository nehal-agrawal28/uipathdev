({
    /* this is a comment to kick off Gearset */
    init : function (component)
    {
        const dealRegFlow = component.find("dealRegFlowId");
        dealRegFlow.startFlow("Deal_Registration_Flow_Partner_Community");
    }
})