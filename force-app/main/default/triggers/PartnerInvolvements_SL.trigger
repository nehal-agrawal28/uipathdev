trigger PartnerInvolvements_SL on Partner_Involvement__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete
) {
  TriggerInjector.handle(Partner_Involvement__c.SobjectType);
}