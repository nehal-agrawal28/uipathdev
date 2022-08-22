@isTest
private class AccountQuoteKAMQueueableTest_SL {
  @testSetup
  static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);
  }

  @isTest
  private static void updateQuoteKAPOnUpdate() {
    // Query Account
    Account account = [SELECT Id, Classification__c FROM Account LIMIT 1];
    account.Classification__c = 'KAP';
    update account;

    Test.startTest();
    new AccountQuoteKAMQueueable_SL(new List<Account>{ account }).work();
    Test.stopTest();

    SBQQ__Quote__c updatedQuote = [SELECT Id, KAM__c, SBQQ__Account__r.KAM_Id__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(updatedQuote.KAM__c, updatedQuote.SBQQ__Account__r.KAM_Id__c, 'KAM__c was not updated!');
  }

  @isTest
  private static void updateQuoteKAPGSIOnUpdate() {
    // Query Account
    Account account = [SELECT Id, Classification__c FROM Account LIMIT 1];
    account.Classification__c = 'KAP-GSI';
    account.RecordTypeId = AccountMetadata.partnerRecordType;
    update account;

    Test.startTest();
    new AccountQuoteKAMQueueable_SL(new List<Account>{ account }).work();
    Test.stopTest();

    SBQQ__Quote__c updatedQuote = [SELECT Id, KAM__c, SBQQ__Account__r.KAM_GSI__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(updatedQuote.KAM__c, updatedQuote.SBQQ__Account__r.KAM_GSI__c, 'KAM__c was not updated!');
  }
}