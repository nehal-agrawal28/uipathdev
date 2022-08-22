trigger OpportunityTriggerAll on Opportunity(before update, after update, after insert) {
    final String triggerName = 'OpportunityTrigger';
    final String skipReason = TriggerUtilities.SKIP_TRIGGER.get(triggerName);
    if (skipReason != null) {
      return;
    }
  
    if (Trigger.isBefore) {
      // if (Trigger.isInsert) {
        // OpportunityTriggerHandlerAll handler = new OpportunityTriggerHandlerAll(Trigger.new);
        // handler.processBeforeInsert();
        // handler.LastOppStageUpdate(Trigger.new, Trigger.oldMap, 'insert');
        //handler.setExistingAccount(trigger.new, null);
      // }
      if (Trigger.isUpdate) {
        OpportunityTriggerHandlerAll handler = new OpportunityTriggerHandlerAll(Trigger.new, Trigger.oldMap);
        // handler.LastOppStageUpdate(Trigger.new, Trigger.oldMap, 'update');
        //handler.setExistingAccount(trigger.new, trigger.oldMap);
        //handler.UpdateCloseDate(trigger.new, trigger.oldMap);
        //handler.storeOppTeamMembers(Trigger.oldMap, Trigger.newMap);
      }
    }
  
    if (Trigger.isAfter) {
      if (Trigger.isInsert) {
        OpportunityTriggerHandlerAll handler = new OpportunityTriggerHandlerAll(Trigger.new);
        handler.processAfterInsert(Trigger.new);
        // CreateAssetOnClosedWonHandler.CreateAssetOnClosedWon(Trigger.new);// Pre-CPQ Code Not Needed any more : SLTECH-13611
        //OppRdcOrchestratorNotificationQueueable.publishAccountWhenFirstOppIsCreated(Trigger.new);
        //OpportunityIntegrationService.publishAccountWhenFirstOppIsCreated(Trigger.new);
        // OppSetAccountRenewalDateQueueable.createOpportunity(Trigger.new);
      }
      if (Trigger.isUpdate) {
        OpportunityTriggerHandlerAll handler = new OpportunityTriggerHandlerAll(Trigger.new, Trigger.oldMap);
        //handler.addEconomicBuyerAndChampionOCR('update');
        //OppOrchestratorNotificationQueueable.publishClosedWonOpps(trigger.new, trigger.oldMap);
        //handler.setOppTeamMembers(Trigger.oldMap, Trigger.newMap);
  
        // Because of the unusual implementation of this trigger framework, I had to create a new method
        // to get access to the actual trigger opportunities without having to query them
        handler.processAfterUpdateWithList(Trigger.new, Trigger.oldMap);
        // OpportunityOwnerRoleSnapshotQueueable.processClosedWonOpps(Trigger.new, Trigger.oldMap);
        //OpportunityIntegrationService.publishClosedWonBookedOpps(Trigger.new, Trigger.oldMap);
        // OppSetAccountRenewalDateQueueable.updateOpportunity(Trigger.new,Trigger.oldMap);
      }
      if(Trigger.isDelete)
        {
            // OppSetAccountRenewalDateQueueable.deleteOpportunity(null, Trigger.oldMap);
        }
    }
}