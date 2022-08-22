public with sharing class OppCloneContactRoleQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  public OppCloneContactRoleQueueable_SL(List<SObject> records) {
    super('OppCloneContactRoleQueueable_SL');
    this.records = records;
    if (records != null && records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }

  public override void work() {
    this.saveContactRoles(this.records);
  }

  private void saveContactRoles(List<Opportunity> records) {
    Map<Id, Id> contractssByNewIds = new Map<Id, Id>();
    for (Opportunity record : records) {
      contractssByNewIds.put(record.SBQQ__AmendedContract__c, record.Id);
      contractssByNewIds.put(record.SBQQ__RenewedContract__c, record.Id);
    }
    contractssByNewIds.remove(null);
    if (contractssByNewIds.isEmpty()) {
      return;
    }

    Map<Id, Id> oppIdToContractIdMap = new Map<Id, Id>();
    for (Contract record : [
      SELECT Id, SBQQ__Opportunity__c, Name
      FROM Contract
      WHERE Id IN :contractssByNewIds.keySet()
    ]) {
      oppIdToContractIdMap.put(record.SBQQ__Opportunity__c, record.Id);
    }
    oppIdToContractIdMap.remove(null);
    if (oppIdToContractIdMap.isEmpty()) {
      return;
    }
    List<OpportunityContactRole> newContactRoles = new List<OpportunityContactRole>();
    for (OpportunityContactRole contactRole : [
      SELECT Id, OpportunityId, ContactId, IsPrimary, Role
      FROM OpportunityContactRole
      WHERE OpportunityId IN :oppIdToContractIdMap.keySet()
    ]) {
      OpportunityContactRole clonedRecord = contactRole.clone();
      clonedRecord.OpportunityId = contractssByNewIds.get(oppIdToContractIdMap.get(contactRole.OpportunityId));
      newContactRoles.add(clonedRecord);
    }
    insert newContactRoles;
  }

  public static void cloneContactRoles(List<Opportunity> records) {
    AbstractQueueable.enqueue(new OppCloneContactRoleQueueable_SL(records));
  }
}