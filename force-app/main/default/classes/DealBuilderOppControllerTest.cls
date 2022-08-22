@IsTest
public inherited sharing class DealBuilderOppControllerTest {
  @TestSetup
  private static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Contract testContract = DataFactory_SL.createContract(testAccount.Id, false);
    testContract.EndDate = System.today();
    insert testContract;
  }

  @isTest
  private static void getInitialDataTest() {
    Test.startTest();
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    DealBuilderOppController.DealBuilderWrapper wrapper = DealBuilderOppController.getInitialData(testAccount.Id);
    System.assertEquals(true, wrapper.oppFields.size() > 0, 'No New_Opportunity fieldset found');
    Test.stopTest();
  }
}