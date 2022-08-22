trigger QuoteProcessTrigger on SBQQ__Quote__c (after insert, before insert, before update, after update, before delete){
    FSTR.COTriggerHandler.handleProcessObjectTrigger();
}