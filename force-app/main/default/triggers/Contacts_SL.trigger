trigger Contacts_SL on Contact(before insert, before update, after insert, after update, after delete) {
  // Creates Domain class instance and calls appropriate overridable methods according to Trigger state
  fflib_SObjectDomain.triggerHandler(Contacts_SL.class);
}