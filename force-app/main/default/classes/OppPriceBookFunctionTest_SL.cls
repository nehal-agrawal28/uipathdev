@IsTest(isParallel=true)
public with sharing class OppPriceBookFunctionTest_SL {
  @TestSetup
  static void makeData() {
    Account acc = DataFactory_CM.createAccount('Customer', false);
    acc.Country__c = 'Japan';
    acc.Region__c = 'Japan';
    acc.Geo__c = 'APJ';
    acc.Area__c = 'Japan';
    insert acc;
    PriceBook2 pb = new PriceBook2(Name = Constants_SL.DEFAULT_PRICE_BOOK);
    insert pb;
  }

  @IsTest
  static void populatePricebookId_onInsert() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Opportunity newOpp = DataFactory_SL.createOpportunity(accountId, false);

    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ newOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(
      OpportunityMetadata_SL.DefaultPriceBookMap.get(Constants_SL.DEFAULT_PRICE_BOOK),
      newOpp.Pricebook2Id
    );
  }

  @IsTest
  static void dontPopulatePricebookId_onInsertOfJapan() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Opportunity newOpp = DataFactory_SL.createOpportunity(accountId, false);
    newOpp.RecordTypeId = OpportunityMetadata_SL.UiPathJapanPartnerStandardRecordType;

    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ newOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(null, newOpp.Pricebook2Id);
  }

  @IsTest
  static void dontPopulatePricebookId_onInsertOfJapanRegion() {
    Id accountId = [SELECT Id, Geo__c FROM Account].Id;
    Opportunity newOpp = DataFactory_SL.createOpportunity(accountId, false);
    newOpp.RecordTypeId = OpportunityMetadata_SL.StandardRecordType;

    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ newOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(null, newOpp.Pricebook2Id);
  }
}