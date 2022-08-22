@isTest(IsParallel=false)
private class DynamicApproverFactoryTest {
  @TestSetup
  private static void makeData() {
    SBQQ.TriggerControl.disable();
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    SBQQ__Quote__c masterQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, false);
    masterQuote.External_Ref__c = 'CPQQuoteClonerService';
    insert masterQuote;
    Product2 testProduct = DataFactory_SL.createProduct(true);
    SBQQ__Quote__c slaveQuote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = masterQuote.SBQQ__Opportunity2__c,
      SBQQ__Primary__c = false,
      SBQQ__Account__c = masterQuote.SBQQ__Account__c,
      Bill_To_Account__c = masterQuote.SBQQ__Account__c,
      SBQQ__PrimaryContact__c = masterQuote.SBQQ__PrimaryContact__c,
      SBQQ__Type__c = 'Quote',
      SBQQ__Status__c = 'Draft',
      // Payment_Terms__c = '30 Days Net',
      SBQQ__StartDate__c = Date.newInstance(System.today().year(), System.today().month(), 28),
      SBQQ__EndDate__c = Date.newInstance(System.today().year() + 3, System.today().month(), 27),
      SBQQ__ExpirationDate__c = System.today().addDays(30),
      RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('CPQ Default').getRecordTypeId()
    );
    insert slaveQuote;
  }

  @isTest
  private static void populateDynamicApproversTest() {
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

    Test.startTest();

    List<SBQQ__Quote__c> temp1 = DynamicApproverFactory.populateDynamicApprovers(new List<Id>{ quote.Id });
    System.assertEquals(temp1 != null, true);

    List<SBQQ__Quote__c> temp2 = DynamicApproverFactory.populateDynamicApprovers(
      new List<Id>{ quote.Id },
      'DefaultDynamicApproverService'
    );
    System.assertEquals(temp2 != null, true);

    Test.stopTest();
  }
}