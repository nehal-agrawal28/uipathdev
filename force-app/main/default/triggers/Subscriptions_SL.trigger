trigger Subscriptions_SL on SBQQ__Subscription__c(before insert, before update, after insert, after update, after delete) {
  // Creates Domain class instance and calls appropriate overridable methods according to Trigger state
  fflib_SObjectDomain.triggerHandler(Subscriptions_SL.class);
}