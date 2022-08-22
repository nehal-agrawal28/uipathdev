trigger Ideas_ST on Sales_Technology_Idea__c(after insert, after update) {
  // Creates Domain class instance and calls appropriate overridable methods according to Trigger state
  fflib_SObjectDomain.triggerHandler(Ideas_ST.class);
}