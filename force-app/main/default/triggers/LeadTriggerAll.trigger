trigger LeadTriggerAll on Lead(before insert, before update, after insert, after update) {
  if (LeadTriggerAllHandler.skipLeadTriggerHandler == false) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
      if (Trigger.isUpdate) {
        LeadTriggerAllHandler.setDisableOwnerChange(Trigger.new, Trigger.oldMap);
        LeadTriggerAllHandler.setOriginalMQLOwnerGroup(Trigger.new, Trigger.oldMap);
        LeadTriggerAllHandler.setLeadOwnerOnStatusChange(Trigger.new, Trigger.oldMap);
      }
      LeadTriggerAllHandler.moveLeadStatusToNew(Trigger.new);
      LeadTriggerAllHandler.setExistingAccount(Trigger.new, Trigger.oldMap);
      LeadTriggerAllHandler.setRegion(Trigger.new);
      LeadTriggerAllHandler.setLastStatusChangeDate(Trigger.new, Trigger.oldMap);
      // Not Reguired for ETM
      //LeadTriggerAllHandler.setTerritoryRelatedFields(trigger.new);
      //LeadTriggerAllHandler.setContactStatus(trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
      if (LeadTriggerAllHandler.isFirstTimeUpdateFunnel == true) {
        LeadFunnelQueueable_MK.leadFunnelOnUpdate(Trigger.New, Trigger.oldMap);
        LeadTriggerAllHandler.isFirstTimeUpdateFunnel = false;
      }
      LeadTriggerAllHandler.fireAssignmentRules(Trigger.new);
      LeadTriggerAllHandler.fireAssignmentRulesOnUpdate(Trigger.new, Trigger.oldMap);
      LeadTriggerAllHandler.autoConvertLeadToExistingAcc(Trigger.new, Trigger.oldMap);
      LeadTriggerAllHandler.onAfterUpdate(Trigger.New, Trigger.oldMap);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
      LeadTriggerAllHandler.setManuallyProgressed(Trigger.new, Trigger.oldMap);
      LeadTriggerAllHandler.setWorkingDuration(Trigger.new, Trigger.oldMap);
      LeadTriggerAllHandler.resetStatusWhenGettingTierValue(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
      //System.debug('@@@ ' + Trigger.new[0].Status);
      if (LeadTriggerAllHandler.isFirstTimeInsertFunnel == true) {
        LeadFunnelQueueable_MK.leadFunnelOnInsert(Trigger.New);
        LeadTriggerAllHandler.isFirstTimeInsertFunnel = false;
      }
      LeadTriggerAllHandler.fireAssignmentRulesOnInsert(Trigger.new);
      LeadTriggerAllHandler.onAfterInsert(Trigger.New);
    }
  }
}