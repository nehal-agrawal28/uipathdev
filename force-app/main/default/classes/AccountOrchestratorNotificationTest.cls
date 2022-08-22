/**
 * TODO REWRITE with fflib Mocking
 */
@isTest
private class AccountOrchestratorNotificationTest {
  @isTest
  private static void canPublishEventToQueue() {
    Account account1 = new Account(
      Name = 'Test1',
      BillingCountry = 'India',
      BillingCountryCode = 'IN',
      BillingStateCode = 'KA',
      Country__c = 'India',
      Region_Specific__c = 'India Business - Top Strategic Accounts',
      State__c = 'Karnataka',
      Industry = 'Apparel',
      Sync_Status__c = CommonsConstants.ACC_SYNC_STATUS_VALID
    );
    insert account1;

    AccountOrchestratorNotificationQueueable q1 = new AccountOrchestratorNotificationQueueable(
      new List<SObject>{ account1 }
    );
    q1.execute(null);

    System.assert(AccountOrchestratorNotificationQueueable.numEvents >= 1, 'At least 1 Account Event was published');

    // TODO figure out a way to assert a created event.
    // This doesn't work because the connector doesn't allow Template creation without a connection to a live Orchestrator
    //System.assertEquals(account1.Id, [SELECT Id,UiPath__RecordId__c FROM UiPath__OrchestratorNotification__c WHERE UiPath__RecordId__c = :account1.Id].UiPath__RecordId__c);
  }
}