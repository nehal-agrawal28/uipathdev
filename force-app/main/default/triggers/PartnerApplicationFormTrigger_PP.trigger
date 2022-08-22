trigger PartnerApplicationFormTrigger_PP on Partner_Application_Form__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  fflib_SObjectDomain.triggerHandler(PartnerApplicationForms_PP.class);
}