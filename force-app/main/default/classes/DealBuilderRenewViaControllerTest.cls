@IsTest
public inherited sharing class DealBuilderRenewViaControllerTest {
  @TestSetup
  private static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    Contract testContract = DataFactory_SL.createContract(testAccount.Id, false);
    testContract.EndDate = System.today();
    insert testContract;
  }

  @isTest
  private static void updateContractsTest() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    Contract contract = [SELECT Id FROM Contract LIMIT 1];

    Test.startTest();
    DealBuilderRenewViaController.DealBuilderWrapper wrapper = DealBuilderRenewViaController.getInitialData(acc.Id);

    DealBuilderRenewViaController.updateContracts(new List<String>{ contract.Id }, null, opp.Id);
    System.assertEquals(
      true,
      [SELECT Id FROM Contract WHERE SBQQ__RenewalOpportunity__c = :opp.Id].size() > 0,
      'Contract was not updated'
    );
    Test.stopTest();
  }

  @isTest
  private static void updateContractsNegativeTest() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Contract contract = [SELECT Id FROM Contract LIMIT 1];

    Test.startTest();

    Boolean exceptionCaught = false;
    try {
      DealBuilderRenewViaController.updateContracts(new List<String>{ contract.Id }, null, 'XYZ');
    } catch (Exception e) {
      exceptionCaught = true;
    }
    System.assertEquals(true, exceptionCaught, 'No exception caught');

    Test.stopTest();
  }
}