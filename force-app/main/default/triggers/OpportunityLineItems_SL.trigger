trigger OpportunityLineItems_SL on OpportunityLineItem(before insert, before update) {
  // Creates Domain class instance and calls appropriate overridable methods according to Trigger state
  fflib_SObjectDomain.triggerHandler(OpportunityLineItems_SL.class);
}