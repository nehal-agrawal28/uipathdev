@isTest(isParallel=false)
private class OppOwnerUpdateQueueableTest_SL {
  @testSetup
  static void setup() {
    User testUser = DataFactory_CM.createUser('Test', 'User', 'System Administrator', true);
    Account testAccount = DataFactory_CM.createAccount('Customer', false);
    testAccount.OwnerId = testUser.Id;
    insert testAccount;
  }

  @isTest
  private static void setOwnerOnInsert() {
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.Id, false);
    opp.Converted_from_Lead__c = true;
    insert opp;

    OppOwnerUpdateQueueable_SL queueable = new OppOwnerUpdateQueueable_SL(new List<Opportunity>{ opp });
    queueable.execute(null);

    Test.startTest();
    Opportunity updatedOpp = [SELECT Id, OwnerId, Account.OwnerId FROM Opportunity LIMIT 1];
    System.assertEquals(updatedOpp.OwnerId, updatedOpp.Account.OwnerId, 'Opp Owner is set incorrectly');
    Test.stopTest();
  }
}