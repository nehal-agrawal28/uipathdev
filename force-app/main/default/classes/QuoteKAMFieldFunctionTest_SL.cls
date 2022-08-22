@IsTest
public with sharing class QuoteKAMFieldFunctionTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    List<Account> customerAccount = DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 1, false);
    customerAccount.get(0).Classification__c = 'KAP';
    List<Account> partnerAccount = DataFactory_CM.createAccounts(AccountMetadata.partnerRecordType, 1, false);
    partnerAccount.get(0).Classification__c = 'KAP-GSI';
    insert new List<Account>{ customerAccount.get(0), partnerAccount.get(0) };

    Opportunity opp1 = DataFactory_SL.createOpportunity(customerAccount.get(0).Id, false);
    Opportunity opp2 = DataFactory_SL.createOpportunity(partnerAccount.get(0).Id, false);
    opp2.Deal_Type__c = 'BPO';
    insert new List<Opportunity>{ opp1, opp2 };

    Product2 prod = new Product2(
      Name = 'Product Uipath 2' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = Test.getStandardPricebookId(),
      Product2Id = prod.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };
  }

  @IsTest
  static void testKAPQuote() {
    Account account = [
      SELECT Id, KAM_Id__c
      FROM Account
      WHERE RecordTypeId = :AccountMetadata.customerRecordType
      LIMIT 1
    ];
    Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :account.Id LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);

    fflib_SObjectDomain.Test.Database.onInsert(new List<SBQQ__Quote__c>{ quote });
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    System.assertEquals(account.KAM_Id__c, quote.KAM__c);
  }

  @IsTest
  static void testGSIQuote() {
    Account account = [
      SELECT Id, KAM_GSI__c
      FROM Account
      WHERE RecordTypeId = :AccountMetadata.partnerRecordType
      LIMIT 1
    ];
    Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :account.Id LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);

    fflib_SObjectDomain.Test.Database.onInsert(new List<SBQQ__Quote__c>{ quote });
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    System.assertEquals(account.KAM_GSI__c, quote.KAM__c);
  }
}