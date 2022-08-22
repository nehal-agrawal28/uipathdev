@IsTest
public with sharing class QuoteSalesRepFunctionTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();

    User manager = DataFactory_CM.createUser('Manager', 'of Rep', 'System Administrator', true);
    User salesRep = DataFactory_CM.createUser('Sales', 'Rep', 'System Administrator', false);
    salesRep.ManagerId = manager.Id;
    insert salesRep;

    Account account = DataFactory_CM.createAccount('Customer', true);
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, false);
    opp.OwnerId = salesRep.Id;
    insert opp;
  }

  @IsTest
  static void testSalesRepFieldsOnInsert() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);

    fflib_SObjectDomain.Test.Database.onInsert(new List<SBQQ__Quote__c>{ quote });
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    Opportunity querriedOpp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
    System.assertEquals(querriedOpp.OwnerId, quote.SBQQ__SalesRep__c);
  }

  @IsTest
  static void testSalesRepFieldsOnUpdate() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];
    User salesRep = [SELECT Id, ManagerId FROM User WHERE Name = 'Sales Rep' LIMIT 1];

    Opportunity opp2 = DataFactory_SL.createOpportunity(account.Id, false);
    opp2.OwnerId = salesRep.Id;
    opp2.Name = 'SecondOpp';
    insert opp2;

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp1.Id, true);
    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(account.Id, opp2.Id, false);
    updatedQuote.Id = quote.Id;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<SBQQ__Quote__c>{ updatedQuote },
      new Map<Id, SObject>{ quote.Id => quote }
    );
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    System.assertEquals(salesRep.Id, updatedQuote.SBQQ__SalesRep__c);
  }
}