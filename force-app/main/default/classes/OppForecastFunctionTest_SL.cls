@isTest(isParallel=false)
private class OppForecastFunctionTest_SL {
  @testSetup
  static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);

    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.Id, false);
    testOpp.ForecastCategoryName = 'Omitted';
    testOpp.In_Forecast__c = false;
    insert testOpp;
  }

  @isTest
  private static void setInForecastOnWonPendingOpp() {
    Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
    Test.startTest();
    opp.StageName = 'Closed Won Pending';
    opp.Won_Reasons__c = 'Successful POC';
    update opp;

    Opportunity updatedOpp = [
      SELECT Id, In_Forecast__c, Closed_Pending_Checkbox__c
      FROM Opportunity
      WHERE Id = :opp.Id
    ];
    System.assertEquals(updatedOpp.In_Forecast__c, true, 'Opp In Forecast is incorrect');
    System.assertEquals(updatedOpp.Closed_Pending_Checkbox__c, true, 'Opp Closed Pending Checkbox is incorrect');
    Test.stopTest();
  }

  @isTest
  private static void setInForecastOnLostOpp() {
    Id accId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);

    Opportunity oldRecord = DataFactory_SL.createOpportunity(accId, false);
    oldRecord.Id = oppId;
    oldRecord.ForecastCategoryName = 'Commit';
    oldRecord.In_Forecast__c = true;

    Opportunity newRecord = DataFactory_SL.createOpportunity(accId, false);
    newRecord.Id = oppId;
    newRecord.StageName = OpportunityMetadata_SL.CLOSED_LOST;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ newRecord },
      new Map<Id, SObject>{ oldRecord.Id => oldRecord }
    );

    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);
    System.assertEquals(newRecord.In_Forecast__c, false, 'Opp In Forecast is incorrect');
  }

  @isTest
  private static void setInForecastOnWonBookedOpp() {
    Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];

    Test.startTest();

    opp.StageName = 'Closed Won Booked';
    update opp;

    Opportunity updatedOpp = [SELECT Id, In_Forecast__c FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(updatedOpp.In_Forecast__c, true, 'Opp In Forecast is incorrect');
    Test.stopTest();
  }

  @isTest
  private static void setInForecastCommittedOppOnUpdate() {
    Opportunity opp = [SELECT Id, ForecastCategoryName FROM Opportunity LIMIT 1];

    Test.startTest();

    opp.ForecastCategoryName = 'Commit';
    update opp;

    Opportunity updatedOpp = [SELECT Id, In_Forecast__c FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(updatedOpp.In_Forecast__c, true, 'Opp In Forecast is incorrect');
    Test.stopTest();
  }

  @isTest
  private static void setInForecastCommittedOppOnInsert() {
    Account acct = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();

    Opportunity testOpp = DataFactory_SL.createOpportunity(acct.Id, false);
    testOpp.ForecastCategoryName = 'Commit';
    insert testOpp;

    Opportunity updatedOpp = [SELECT Id, In_Forecast__c FROM Opportunity WHERE Id = :testOpp.Id];
    System.assertEquals(updatedOpp.In_Forecast__c, true, 'Opp In Forecast is incorrect');
    Test.stopTest();
  }

  @isTest
  private static void setInForecastUpsideOpp() {
    Account acct = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();

    Opportunity testOpp = DataFactory_SL.createOpportunity(acct.Id, false);
    insert testOpp;
    testOpp.ForecastCategoryName = 'Commit';
    update testOpp;

    Opportunity updatedOpp = [SELECT Id, In_Forecast__c FROM Opportunity WHERE Id = :testOpp.Id];
    System.assertEquals(updatedOpp.In_Forecast__c, true, 'Opp In Forecast is incorrect');
    Test.stopTest();
  }

  @isTest
  private static void setOwnerOnInsert() {
    Opportunity opp = [SELECT Id, ForecastCategoryName FROM Opportunity LIMIT 1];
    opp.ForecastCategoryName = 'Pipeline';
    update opp;

    OppInForecastFalseCategoryQueueable_SL queueable = new OppInForecastFalseCategoryQueueable_SL(
      new List<Opportunity>{ opp }
    );
    queueable.execute(null);

    Test.startTest();
    Opportunity updatedOpp = [SELECT Id, In_Forecast__c FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(updatedOpp.In_Forecast__c, false, 'Opp In Forecast is incorrect');
    Test.stopTest();
  }
}