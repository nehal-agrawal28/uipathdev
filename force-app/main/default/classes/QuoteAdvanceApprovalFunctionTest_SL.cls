@IsTest
public with sharing class QuoteAdvanceApprovalFunctionTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', true);
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

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
  static void testQuoteApprovalApproved() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);

    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(
      quote.SBQQ__Account__c,
      quote.SBQQ__Opportunity2__c,
      false
    );
    updatedQuote.Id = quote.Id;
    updatedQuote.ApprovalStatus__c = QuoteMetadata_SL.APPROVED;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<SBQQ__Quote__c>{ updatedQuote },
      new Map<Id, SObject>{ quote.Id => quote }
    );

    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);
    System.assertEquals(QuoteMetadata_SL.APPROVED, updatedQuote.SBQQ__Status__c);
  }

  @IsTest
  static void testQuoteApprovalPending() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);

    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(
      quote.SBQQ__Account__c,
      quote.SBQQ__Opportunity2__c,
      false
    );
    updatedQuote.Id = quote.Id;
    updatedQuote.ApprovalStatus__c = QuoteMetadata_SL.PENDING;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<SBQQ__Quote__c>{ updatedQuote },
      new Map<Id, SObject>{ quote.Id => quote }
    );

    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);
    System.assertEquals(QuoteMetadata_SL.IN_REVIEW, updatedQuote.SBQQ__Status__c);
  }

  @IsTest
  static void testQuoteApprovalRejected() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);

    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(
      quote.SBQQ__Account__c,
      quote.SBQQ__Opportunity2__c,
      false
    );
    updatedQuote.Id = quote.Id;
    updatedQuote.ApprovalStatus__c = QuoteMetadata_SL.REJECTED;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<SBQQ__Quote__c>{ updatedQuote },
      new Map<Id, SObject>{ quote.Id => quote }
    );

    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);
    System.assertEquals(QuoteMetadata_SL.REJECTED, updatedQuote.SBQQ__Status__c);
  }

  @IsTest
  static void testQuoteApprovalDraft() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);

    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(
      quote.SBQQ__Account__c,
      quote.SBQQ__Opportunity2__c,
      false
    );
    updatedQuote.Id = quote.Id;
    updatedQuote.ApprovalStatus__c = QuoteMetadata_SL.RECALLED;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<SBQQ__Quote__c>{ updatedQuote },
      new Map<Id, SObject>{ quote.Id => quote }
    );

    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);
    System.assertEquals(QuoteMetadata_SL.DRAFT, updatedQuote.SBQQ__Status__c);
  }
}