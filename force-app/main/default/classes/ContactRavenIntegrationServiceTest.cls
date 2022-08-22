@IsTest
public with sharing class ContactRavenIntegrationServiceTest {
  public static final String CONFIRMATION_MESSAGE = 'There should be a publish attempt in the logs';
  @IsTest
  public static void publishesUpdatesToRaven() {
    List<Account> accounts = new List<Account>();
    Account acc1 = new Account(
      Name = 'Test1',
      BillingCountry = 'India',
      BillingCountryCode = 'IN',
      BillingStateCode = 'KA',
      Region_Specific__c = 'India Business - Top Strategic Accounts',
      Country__c = 'India',
      State__c = 'Karnataka',
      Industry = 'Apparel',
      RecordTypeId = AccountMetadata.partnerRecordType
    );
    accounts.add(acc1);
    Account acc2 = new Account(
      Name = 'Test2',
      BillingCountry = 'India',
      BillingCountryCode = 'IN',
      BillingStateCode = 'KA',
      Region_Specific__c = 'India Business - Top Strategic Accounts',
      Country__c = 'India',
      State__c = 'Karnataka',
      Industry = 'Apparel',
      RecordTypeId = AccountMetadata.partnerRecordType
    );
    accounts.add(acc2);
    insert accounts;

    Contact cnt = new Contact(
      LastName = 'ContactOne',
      AccountId = acc1.Id,
      Email = 'contRec.Test11@emailDomain.com',
      Department__c = 'IT'
    );
    insert cnt;

    cnt.AccountId = acc2.Id;

    OrchestratorNotifierQueueable.forceSyncMode = true;
    update cnt;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(Constants_MK.CNT_UIPATH_CONNECTOR_RAVEN_TEMPLATE)) {
        logList.add(log);
      }
    }

    System.assertEquals(true, !logList.isEmpty(), CONFIRMATION_MESSAGE);
  }
}