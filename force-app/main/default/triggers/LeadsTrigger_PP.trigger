trigger LeadsTrigger_PP on Lead(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  fflib_SObjectDomain.triggerHandler(Leads_PP.class);
}