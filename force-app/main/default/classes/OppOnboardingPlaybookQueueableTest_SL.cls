@isTest(isParallel=false)
private class OppOnboardingPlaybookQueueableTest_SL {
  @testSetup
  static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    DataFactory_SL.createOpportunity(testAccount.Id, true);
  }

  @isTest
  private static void setOppTypeOnUpdate() {
    Opportunity insertedOpp = [SELECT Id, OwnerId, Customer_Onboarding__c FROM Opportunity LIMIT 1];
    insertedOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_BOOKED;
    insertedOpp.Customer_Onboarding__c = true;
    update insertedOpp;

    OppOnboardingPlaybookQueueable_SL queueable = new OppOnboardingPlaybookQueueable_SL(
      new List<Opportunity>{ insertedOpp }
    );
    queueable.execute(null);

    Test.startTest();
    List<Task> tasks = [SELECT Id FROM Task];
    //System.assertEquals(7, tasks.size(), 'Too many or not enough Tasks created');
    Test.stopTest();
  }

  @isTest
  private static void setOppTypeRenewalOnInsert() {
    Account acct = [SELECT Id, OwnerId FROM Account LIMIT 1];
    Opportunity opp = DataFactory_SL.createOpportunity(acct.Id, false);
    opp.Customer_Onboarding__c = true;
    opp.OwnerId = acct.OwnerId;
    opp.StageName = OpportunityMetadata_SL.CLOSED_WON_BOOKED;

    OppOnboardingPlaybookQueueable_SL queueable = new OppOnboardingPlaybookQueueable_SL(new List<Opportunity>{ opp });
    queueable.execute(null);

    Test.startTest();
    List<Task> tasks = [SELECT Id FROM Task];
    //System.assertEquals(7, tasks.size(), 'Too many or not enough Tasks created');
    Test.stopTest();
  }
}