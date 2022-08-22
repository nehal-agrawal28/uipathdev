public without sharing class OppUpdateAccountQueueable_SL extends AbstractQueueable {
  public final List<Id> accountIds;

  public OppUpdateAccountQueueable_SL(List<Id> accountIds) {
    super('OppUpdateAccountQueueable_SL');
    this.accountIds = accountIds;
  }

  public override void work() {
    this.updateAccounts(this.accountIds);
  }

  private void updateAccounts(List<Id> accountIds) {
    Set<Id> accIds = new Set<Id>(accountIds);
    List<Account> accountsToSave = buildAccounts(accIds);
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).disableAll();
    update accountsToSave;
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).enableAll();
  }

  private List<Account> buildAccounts(Set<Id> accountIds) {
    List<Account> records = new List<Account>();
    for (Account record : [
      SELECT
        Id,
        Earliest_Renewal_Expiry_Date__c,
        (
          SELECT Id, Renewal_Expiry_Date__c
          FROM Opportunities
          WHERE Renewal_Expiry_Date__c != NULL AND Renewal_Expiry_Date__c >= TODAY
          ORDER BY Renewal_Expiry_Date__c ASC
          LIMIT 1
        )
      FROM Account
      WHERE Id IN :accountIds
    ]) {
      record.Earliest_Renewal_Expiry_Date__c = (record.Opportunities).size() > 0
        ? record.Opportunities[0].Renewal_Expiry_Date__c
        : null;
      records.add(record);
    }
    return records;
  }

  public static void setRenewalExpiryDate(List<Opportunity> Records) {
    List<Id> accountIds = Collection.of(records).pluckIds(Opportunity.AccountId);
    AbstractQueueable.enqueue(new OppUpdateAccountQueueable_SL(accountIds));
  }

  public static void setRenewalExpiryDate(List<Opportunity> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.AccountId, Opportunity.Renewal_Expiry_Date__c },
      Records,
      existingRecords
    );
    List<Id> accountIds = Collection.of(records).pluckIds(Opportunity.AccountId);
    accountIds.addAll(Collection.of(existingRecords.values()).pluckIds(Opportunity.AccountId));

    List<Opportunity> eligibleRecords = (List<Opportunity>) Collection.of(Records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppUpdateAccountQueueable_SL(accountIds));
    }
  }
}