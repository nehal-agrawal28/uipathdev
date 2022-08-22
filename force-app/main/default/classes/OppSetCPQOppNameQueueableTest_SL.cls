@isTest
public with sharing class OppSetCPQOppNameQueueableTest_SL {
  @TestSetup
  static void createSetupData() {
    Id customerRT = AccountMetadata.getAccountRecordTypeId('Customer');
    Account testAccount = DataFactory_CM.createAccount(customerRT, false);
    testAccount.name = 'Test Customer Account';
    testAccount.BillingCountry = 'Korea, Republic of';
    insert testAccount;
    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.name = 'TestOpportunity for testing when string is greater than 120 characters so that if scenarios are covered and tested';
    insert testOpp;
    Contract cont = DataFactory_SL.createContract(testAccount.id, false);
    cont.EndDate = Date.today().addDays(10);
    cont.SBQQ__Opportunity__c = testOpp.id;
    insert cont;
  }

  @isTest
  private static void setCPQOppNameTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Contract testContract = [SELECT id FROM Contract LIMIT 1];
    List<Opportunity> opps = new List<Opportunity>();
    for (Integer i = 0; i < 2; i++) {
      Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
      testOpp.Converted_from_Lead__c = false;
      if (i == 0) {
        testOpp.SBQQ__RenewedContract__c = testContract.id;
        testOpp.SBQQ__Renewal__c = true;
      } else {
        testOpp.SBQQ__AmendedContract__c = testContract.id;
      }
      opps.add(testOpp);
    }

    insert opps;
    OppSetCPQOppNameQueueable_SL queueable = new OppSetCPQOppNameQueueable_SL(opps);
    queueable.execute(null);

    System.assert(
      [SELECT id, Name FROM Opportunity WHERE SBQQ__Renewal__c = TRUE LIMIT 1]
        .Name.contains('Test Customer Account Renewal  -')
    );
  }

  @isTest
  private static void setCPQOppNameWhenNoElegibleOpporuniyTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.name = 'Original name';
    testOpp.Converted_from_Lead__c = false;
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ testOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);
    System.assertEquals('Original name', testOpp.name);
  }
}