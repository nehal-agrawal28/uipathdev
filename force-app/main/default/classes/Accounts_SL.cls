/**
 * Responsibility: Account Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class Accounts_SL extends fflib_SObjectDomain implements IAccounts_SL {
  public static IAccounts_SL newInstance(List<Account> recordList) {
    return (IAccounts_SL) Application.Domain.newInstance(recordList);
  }

  public static IAccounts_SL newInstance(Set<Id> recordIdSet) {
    return (IAccounts_SL) Application.Domain.newInstance(recordIdSet);
  }

  public Accounts_SL(List<Account> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    AccountQuoteKAMQueueable_SL.updateQuoteKAMField(Records, existingRecords);
  }

  public override void onAfterDelete() {
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Accounts_SL(sObjectList);
    }
  }
}