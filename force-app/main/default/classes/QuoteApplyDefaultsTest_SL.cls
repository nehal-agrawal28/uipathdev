@IsTest
public with sharing class QuoteApplyDefaultsTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    List<Account> customerAccount1 = DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 1, false);
    List<Account> customerAccount2 = DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 1, false);
    customerAccount2.get(0).Name = 'Testing';
    insert new List<Account>{ customerAccount1.get(0), customerAccount2.get(0) };

    Opportunity opp1 = DataFactory_SL.createOpportunity(customerAccount1.get(0).Id, false);
    opp1.SBQQ__Renewal__c = true;

    Opportunity opp2 = DataFactory_SL.createOpportunity(customerAccount2.get(0).Id, false);
    insert new List<Opportunity>{ opp1, opp2 };

    /*Partner_Involvement__c newPartner1 = DataFactory_SL.createPartnerInvolvement(
      opp1.Id,
      'Sold to Partner (Buying Directly from UiPath)',
      true
    );
    Partner_Involvement__c newPartner2 = DataFactory_SL.createPartnerInvolvement(
      opp1.Id,
      'Tier 2 Partner (Buying from Sold to Partner)',
      true
    );*/

    Contract newContract = DataFactory_SL.createContract(customerAccount1.get(0).Id, false);
    newContract.StartDate = Date.Today();
    newContract.Status = 'Draft';
    newContract.ContractTerm = 4;
    newContract.SBQQ__Opportunity__c = opp1.Id;
    insert newContract;
  }

  @IsTest
  static void testSetQuoteDefaults() {
    Account account = [SELECT Id FROM Account WHERE RecordTypeId = :AccountMetadata.customerRecordType LIMIT 1];
    Opportunity opp = [
      SELECT Id, Sold_to_Partner__c, Tier_2_Partner__c
      FROM Opportunity
      WHERE AccountId = :account.Id
      LIMIT 1
    ];

    Opportunity opp2 = [
      SELECT Id, Sold_to_Partner__c, Tier_2_Partner__c, AccountId
      FROM Opportunity
      WHERE AccountId != :account.Id
      LIMIT 1
    ];

    Test.startTest();
    opp.Sold_to_Partner__c = account.Id;
    opp.Tier_2_Partner__c = account.Id;
    opp.Deal_Type__c = 'Resale';
    update opp;
    Test.stopTest();
    Opportunity opp1 = [SELECT Id, Sold_to_Partner__c FROM Opportunity WHERE AccountId = :account.Id LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);

    fflib_SObjectDomain.Test.Database.onInsert(new List<SBQQ__Quote__c>{ quote });
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    SBQQ__Quote__c fetchUpdatedQuote1 = [
      SELECT Id, SBQQ__Type__c, SBQQ__Partner__c
      FROM SBQQ__Quote__c
      WHERE Id = :quote.Id
    ];

    SBQQ__Quote__c quote2 = DataFactory_SL.createCPQQuote(opp2.AccountId, opp2.Id, true);

    fflib_SObjectDomain.Test.Database.onInsert(new List<SBQQ__Quote__c>{ quote2 });
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    System.assertEquals(Constants.QUOTE_RENEWAL_TYPE, fetchUpdatedQuote1.SBQQ__Type__c);
    System.assertEquals(account.Id, fetchUpdatedQuote1.SBQQ__Partner__c);
  }
}