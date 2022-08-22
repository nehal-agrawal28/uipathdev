@IsTest
private class CPQContractMaintenanceBatchTest_SL {
  @TestSetup
  private static void makeData() {
    User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    User u1 = DataFactory_CM.createUser('Other', 'User1', 'System Administrator', false);
    User u2 = DataFactory_CM.createUser('Other', 'User2', 'System Administrator', false);
    System.runAs(runAsUser) {
      insert new List<User>{ u1, u2 };
    }

    Account acc = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
    acc.Name = 'CPQContractMaintenanceBatchTest_SL';
    acc.OwnerId = u1.Id;
    insert acc;

    Contract con = new Contract(
      AccountId = acc.Id,
      Status = 'Draft',
      StartDate = System.Today().addDays(-365),
      EndDate = System.Today().addDays(100),
      CurrencyIsoCode = 'USD',
      SBQQ__AmendmentOwner__c = u1.Id,
      SBQQ__RenewalOwner__c = u1.Id
    );
    insert con;

    Opportunity opp = DataFactory_SL.createOpportunity(acc.Id, false);
    opp.Deal_Type__c = 'Direct';
    opp.Amount = 20000;
    opp.SBQQ__RenewedContract__c = con.Id;
    opp.OwnerId = u1.Id;
    opp.CloseDate = System.Today().addDays(30);
    insert opp;
  }

  @isTest
  private static void contractMaintenanceBatchTest() {
    Account acc = [SELECT Id FROM Account WHERE Name = 'CPQContractMaintenanceBatchTest_SL' LIMIT 1];
    User u2 = [SELECT Id FROM User WHERE LastName = 'User2' LIMIT 1];

    Test.StartTest();

    acc.OwnerId = u2.Id;
    update acc;

    CPQContractMaintenanceBatch_SL scheduleBatch = new CPQContractMaintenanceBatch_SL();
    String sch = '0 0 23 * * ?';
    system.schedule('Test status Check', sch, scheduleBatch);
    Database.executeBatch(scheduleBatch, 500);

    Test.stopTest();

    Contract con = [SELECT SBQQ__AmendmentOwner__c FROM Contract WHERE AccountId = :acc.Id];
    System.assertEquals(u2.Id, con.SBQQ__AmendmentOwner__c);
  }
}