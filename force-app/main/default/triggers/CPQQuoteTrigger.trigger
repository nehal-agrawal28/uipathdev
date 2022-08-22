/**
* @author Girish Lakshmanan
* @date 18/03/2019
* @description Simply Delegates all events to the handler.
*/

trigger CPQQuoteTrigger on SBQQ__Quote__c (before insert, before update, before delete, after insert, after undelete) {
    new CPQQuoteTriggerHandler().run();
}