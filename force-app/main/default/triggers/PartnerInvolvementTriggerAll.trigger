trigger PartnerInvolvementTriggerAll on Partner_Involvement__c (before update, before Insert, before delete, after update, after Insert, after delete) 
{
    fflib_SObjectDomain.triggerHandler(PartnerInvolvements_PP.class);

    PartnerInvolvementTriggerAllHandler handler = new PartnerInvolvementTriggerAllHandler();
    
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {   
            // handler.preventCheckingOpportunitySourced(Trigger.New, null);
            // handler.preventSecondSoldToPartner(Trigger.New, null);
            // handler.setDefaultValue4JP(Trigger.New);
            // handler.applyPartnerInfluenceApprovalMatrix(Trigger.New, null);
        }
        if(Trigger.isUpdate)
        {
            // handler.preventCheckingOpportunitySourced(Trigger.New, Trigger.oldMap);
            // handler.preventSecondSoldToPartner(Trigger.New, Trigger.oldMap);
            // handler.applyPartnerInfluenceApprovalMatrix(Trigger.New, Trigger.oldMap);
        }
        // if(Trigger.isDelete)
        // {
        //     handler.preventDeletion(Trigger.old);
        // }
    }
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            // handler.modifyOpportunity(Trigger.New, null, 'insert');
            //PartnerInvolvementIntegrationService.publishInsertsToUiPathConnector(Trigger.new);
            // handler.setIsPartnerSourced(Trigger.New, null);
        }
        if(Trigger.isUpdate)
        {
            // handler.modifyOpportunity(Trigger.New, Trigger.oldMap, 'update');
            // handler.setIsPartnerSourced(Trigger.New, Trigger.oldMap);
        }
        if(Trigger.isDelete)
        {
            // handler.modifyOpportunity(Trigger.Old, null, 'delete');
            // handler.setIsPartnerSourced(null, Trigger.oldMap);
        }
    }
}