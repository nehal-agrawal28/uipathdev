trigger Contracts_SL on Contract(before insert, before update, after insert, after update, after delete) {
  // Creates Domain class instance and calls appropriate overridable methods according to Trigger state
  fflib_SObjectDomain.triggerHandler(Contracts_SL.class);
}