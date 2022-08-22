@isTest
public with sharing class OppAccCustomerStageQueueableTest_SL {
  @TestSetup
  static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Contact cont = DataFactory_CM.createContact(testAccount.id, true);

    Product2 prod = DataFactory_SL.createProduct(false);
    prod.Name = 'Attended Robot';
    insert prod;
    PricebookEntry pbEntry = DataFactory_SL.createStdPricebookEntry(prod.id, 10, true);

    List<Opportunity> opps = new List<Opportunity>();
    List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.Amount = 100;
    testOpp.Contract_Start_Date__c = Date.today();
    testOpp.Contract_End_Date__c = Date.today().addDays(10);
    testOpp.CloseDate = Date.today();
    opps.add(testOpp);

    Opportunity testOpp1 = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp1.Amount = 100;
    testOpp1.Contract_Start_Date__c = Date.today();
    testOpp1.Contract_End_Date__c = Date.today().addDays(10);
    opps.add(testOpp1);

    insert opps;

    //create contact role
    DataFactory_SL.createOpportunityContactRole(testOpp.Id, cont.Id, 'Business User', true);
    DataFactory_SL.createOpportunityContactRole(testOpp1.Id, cont.Id, 'Business User', true);

    OpportunityLineItem oppLineItem = DataFactory_SL.createOpportunityLineItem(pbEntry.id, testOpp1.id, false);
    oppLineItems.add(oppLineItem);

    OpportunityLineItem oppLineItem1 = DataFactory_SL.createOpportunityLineItem(pbEntry.id, testOpp1.id, false);
    oppLineItems.add(oppLineItem1);

    OpportunityLineItem oppLineItem2 = DataFactory_SL.createOpportunityLineItem(pbEntry.id, testOpp.id, false);
    oppLineItems.add(oppLineItem2);

    insert oppLineItems;
  }

  @isTest
  private static void updateCustomerStageTest() {
    List<Opportunity> opps = [SELECT id, accountid FROM Opportunity WHERE StageName != 'Closed Won Booked'];
    opps[1].CloseDate = Date.today().addDays(10);
    opps[1].StageName = 'Closed Won Booked';
    update opps[1];
    opps[0].StageName = 'Closed Won Booked';
    opps[0].CloseDate = Date.today().addDays(10);
    Test.startTest();
    update opps[0];
    OppAccCustomerStageQueueable_SL oppQueueable = new OppAccCustomerStageQueueable_SL(opps);
    oppQueueable.work();
    Test.stopTest();
    System.assertEquals('Expand', [SELECT id, Customer_Stage__c FROM Account LIMIT 1].Customer_Stage__c);
  }

  @isTest
  private static void updateCustomerStageWithZeroRobots() {
    List<Opportunity> updateOpps = new List<Opportunity>();
    for (Opportunity opp : [SELECT id, AccountId, Type FROM Opportunity]) {
      opp.Type = 'Renewal';
      opp.CloseDate = Date.today().addDays(10);
      opp.StageName = 'Closed Won Booked';
      updateOpps.add(opp);
    }

    Test.startTest();
    update updateOpps;
    OppAccCustomerStageQueueable_SL oppQueueable = new OppAccCustomerStageQueueable_SL(updateOpps);
    oppQueueable.work();
    Test.stopTest();

    System.assertEquals('Prove', [SELECT id, Customer_Stage__c FROM Account LIMIT 1].Customer_Stage__c);
  }
}