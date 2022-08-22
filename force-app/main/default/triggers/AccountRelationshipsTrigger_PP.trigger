trigger AccountRelationshipsTrigger_PP on AccountRelationship(
  after delete,
  after insert,
  after undelete,
  after update,
  before delete,
  before insert,
  before update
) {
  fflib_SObjectDomain.triggerHandler(AccountRelationships_PP.class);
}