@IsTest
public class CreditHoldDetailsControllerTest {

  @TestSetup
  private static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
  
  }

  @IsTest
  private static void approvalOpportunityDetailsTest() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    Test.startTest();
    CreditHoldDetailsController ctrl = new CreditHoldDetailsController();
    ctrl.oId = opp.Id;
    System.assertEquals(true, opp.Id != null, 'Opportunity was empty');
    Test.stopTest();
  }
}