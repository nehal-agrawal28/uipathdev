trigger Managed_ClauseStepTrigger on APXT_Redlining__Managed_Clause__c (after update, after insert, before delete, after delete, before insert, before update) { 
    FSTR.COTriggerHandler.handleStepObjectTrigger();
}