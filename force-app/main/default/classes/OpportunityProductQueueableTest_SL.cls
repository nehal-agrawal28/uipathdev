@IsTest(IsParallel=false)
public with sharing class OpportunityProductQueueableTest_SL {
  @TestSetup
  static voId makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);

    Opportunity oppA = DataFactory_SL.createOpportunity(testAccount.Id, false);
    oppA.Amount = 100;
    oppA.Contract_Start_Date__c = Date.today();
    oppA.Contract_End_Date__c = Date.today().addDays(10);
    oppA.CloseDate = Date.today();

    Opportunity oppB = DataFactory_SL.createOpportunity(testAccount.Id, false);
    oppB.Amount = 100;
    oppB.Contract_Start_Date__c = Date.today();
    oppB.Contract_End_Date__c = Date.today().addDays(10);

    List<Opportunity> opps = new List<Opportunity>();
    opps.add(oppA);
    opps.add(oppB);
    insert opps;

    Product2 prod = DataFactory_SL.createProduct(false);
    prod.Name = 'Attended Robot';
    insert prod;
    PricebookEntry pbEntry = DataFactory_SL.createStdPricebookEntry(prod.Id, 10, true);

    OpportunityLineItem oppLineItem = DataFactory_SL.createOpportunityLineItem(pbEntry.Id, oppB.Id, false);
    OpportunityLineItem oppLineItem1 = DataFactory_SL.createOpportunityLineItem(pbEntry.Id, oppB.Id, false);
    OpportunityLineItem oppLineItem2 = DataFactory_SL.createOpportunityLineItem(pbEntry.Id, oppA.Id, false);

    oppLineItem.Effective_Start_Date__c = Date.today().addDays(1);
    oppLineItem1.Effective_Start_Date__c = Date.today().addDays(20);
    oppLineItem2.Effective_Start_Date__c = Date.today().addDays(1);

    List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
    oppLineItems.add(oppLineItem);
    oppLineItems.add(oppLineItem1);
    oppLineItems.add(oppLineItem2);

    insert oppLineItems;
  }

  @IsTest
  static voId onUpdate_updateBusinessType() {
    List<OpportunityLineItem> oppLineItems = [SELECT Id, Business_Type__c FROM OpportunityLineItem];

    for (OpportunityLineItem lineItem : oppLineItems) {
      System.assertEquals(null, lineItem.Business_Type__c, 'Business Type not set');
    }

    Map<Id, Opportunity> opps = new Map<Id, Opportunity>([SELECT Id, Type FROM Opportunity]);

    Test.startTest();
    new OpportunityProductQueueable_SL(opps.values()).work();
    Test.stopTest();

    oppLineItems = [SELECT Id, OpportunityId, Business_Type__c FROM OpportunityLineItem];
    for (OpportunityLineItem lineItem : oppLineItems) {
      System.assertEquals(opps.get(lineItem.OpportunityId).Type, lineItem.Business_Type__c, 'Business Type not set');
    }
  }

  @IsTest
  static voId onUpdate_deriveProductStartDate() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Opportunity existingRecord = DataFactory_SL.createOpportunity(accountId, false);
    Opportunity record = DataFactory_SL.createOpportunity(accountId, false);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    record.Id = opp.Id;
    existingRecord.Id = opp.Id;
    record.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;

    Test.startTest();
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ record },
      new Map<Id, SObject>{ opp.Id => existingRecord }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);
    Test.stopTest();

    System.assertEquals(Date.today().addDays(1), record.Product_Start_Date__c, 'Product Start date not set on update');
  }
}