@IsTest
public with sharing class OpportunityPopulateGADateFunctionTest_SL {
  @IsTest
  static void testSetGADateOnUpdate() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', true);
    Opportunity oldOpp = DataFactory_SL.createOpportunity(account.Id, true);

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, oldOpp.Id, false);
    quote.Max_GA_Date__c = System.Date.today();
    insert quote;

    Opportunity updatedOpp = oldOpp.clone();
    updatedOpp.Id = oldOpp.Id;
    updatedOpp.SBQQ__PrimaryQuote__c = quote.Id;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(updatedOpp.Max_GA_Date__c, quote.Max_GA_Date__c);
  }
}