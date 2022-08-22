@isTest(isParallel=false)
public with sharing class OpportunityLineItemFunctionTest_SL {
  @TestSetup
  static void makeData() {
    DataFactory_CM.createAccount('Customer', true);
    Product2 newProduct = DataFactory_SL.createProduct(true);
    PriceBookEntry stdPriceBookEntry = DataFactory_SL.createStdPricebookEntry(newProduct.id, 2000, true);
  }

  @IsTest
  private static void testSetDefaultsOnInsert() {
    PriceBookEntry stdPriceBookEntry = [SELECT Id FROM PriceBookEntry LIMIT 1];
    OpportunityLineItem oli = DataFactory_SL.createOpportunityLineItem(stdPriceBookEntry.Id, null, false);
    oli.ServiceDate = System.today();
    oli.End_Date__c = System.today().addDays(50);

    fflib_SObjectDomain.Test.Database.onInsert(new List<OpportunityLineItem>{ oli });
    fflib_SObjectDomain.triggerHandler(OpportunityLineItems_SL.class);

    System.assertEquals('Core Product', oli.Product_Family_T__c, 'Type is not defaulted with product Family');
  }
}