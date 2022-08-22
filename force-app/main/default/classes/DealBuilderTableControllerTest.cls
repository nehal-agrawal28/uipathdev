@IsTest
public inherited sharing class DealBuilderTableControllerTest {
  @TestSetup
  private static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    Contract testContract = DataFactory_SL.createContract(testAccount.Id, false);
    testContract.EndDate = System.today();
    insert testContract;
  }

  @isTest
  private static void getInitialDataTest() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    DealBuilderTableController.DataWrapper wrapper = DealBuilderTableController.getData(acc.Id, 'New_Business_Upsell');
    System.assertEquals(true, wrapper.dataList.size() > 0, 'No open opp found');

    DealBuilderTableController.DataWrapper wrapper1 = DealBuilderTableController.getData(
      acc.Id,
      'Renewals_of_Contracts'
    );

    DealBuilderTableController.DataWrapper wrapper2 = DealBuilderTableController.getData(
      acc.Id,
      'Other_Renewals_NotMerged'
    );

    DealBuilderTableController.DataWrapper wrapper3 = DealBuilderTableController.getData(
      acc.Id,
      'Other_Renewals_Merged'
    );

    DealBuilderTableController.DataWrapper wrapper4 = DealBuilderTableController.getData(acc.Id, 'Open_Amendments');

    DealBuilderTableController.DataWrapper wrapper5 = DealBuilderTableController.getData(acc.Id, 'Active_Contracts');

    Test.stopTest();
  }
}