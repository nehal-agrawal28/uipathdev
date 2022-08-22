/**
 * Created by Slalom- BM on 11-09-2020
 */
trigger CPQSubscriptionTrigger on SBQQ__Subscription__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    // Instantiate the CPQSubscriptionTriggerHandler Class. All the methods and trigger logic should be written in the CPQSubscriptionTriggerHandler
    new CPQSubscriptionTriggerHandler().run();

}