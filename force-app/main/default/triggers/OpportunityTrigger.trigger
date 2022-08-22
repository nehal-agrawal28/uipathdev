trigger OpportunityTrigger on Opportunity (before update, before Insert, after update, after Insert) {




    /*final String triggerName = 'OpportunityTrigger';
    final String skipReason = TriggerUtilities.SKIP_TRIGGER.get(triggerName);
    if (skipReason != null) {

        //System.debug('Skip trigger: ' + skipReason);
        return;
    }



    if (trigger.isBefore) {
        if (trigger.isInsert) {
            OpportunityTriggerHandler handler = new OpportunityTriggerHandler(trigger.new);
            handler.processBeforeInsert();
            handler.setExistingAccount(trigger.new, null);
        }
        if (trigger.isUpdate) {
            OpportunityTriggerHandler handler = new OpportunityTriggerHandler(trigger.new, trigger.oldMap);
            //handler.setManagingDirector(Trigger.new);
            handler.setExistingAccount(trigger.new, trigger.oldMap);
            handler.UpdateCloseDate(trigger.new, trigger.oldMap);
        }
    }

    if (trigger.isAfter) {
        if (trigger.isInsert) {
            OpportunityTriggerHandler handler = new OpportunityTriggerHandler(trigger.new);
            handler.processAfterInsert();
            handler.PAMToOpportunity('insert');
            //OpportunityTriggerHandler.ShareOpportunities(Trigger.new);
            CreateAssetOnClosedWonHandler.CreateAssetOnClosedWon(Trigger.new);

        }
        if(trigger.isUpdate)
        {
            OpportunityTriggerHandler handler = new OpportunityTriggerHandler(trigger.new, trigger.oldMap);
            handler.PAMToOpportunity('update');
            handler.addAccountOwnerAsSplit('update');
            handler.addEconomicBuyerAndChampionOCR('update');
          
            
            
           // Because of the unusual implementation of this trigger framework, I had to create a new method
           // to get access to the actual trigger opportunities without having to query them
            

            handler.processAfterUpdateWithList(trigger.new, trigger.oldMap);
            OppOrchestratorNotificationQueueable q1 = new OppOrchestratorNotificationQueueable(trigger.oldMap,trigger.newMap);
            q1.execute(null);
        }
       
    }*/
}