@IsTest
public with sharing class QuoteAssignCPQDefaultRTFunctionTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', true);
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);
  }

  @IsTest
  static void testSetRTOnInsert() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    quote.SBQQ__Status__c = 'Draft';

    fflib_SObjectDomain.Test.Database.onInsert(new List<SBQQ__Quote__c>{ quote });
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    System.assertEquals(quote.RecordTypeId, QuoteMetadata_SL.CPQDefaultRecordType);
  }

  @IsTest
  static void testSetRTOnUpdate() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);
    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    updatedQuote.SBQQ__Status__c = 'Draft';
    updatedQuote.Id = quote.Id;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<SBQQ__Quote__c>{ updatedQuote },
      new Map<Id, SObject>{ quote.Id => quote }
    );
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    System.assertEquals(updatedQuote.RecordTypeId, QuoteMetadata_SL.CPQDefaultRecordType);
  }
}