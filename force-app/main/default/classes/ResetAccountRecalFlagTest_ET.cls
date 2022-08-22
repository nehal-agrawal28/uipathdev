/**
 * @AUTHOR: UIPath
 * @DATE: 23/05/2022
 * @DESCRIPTION: Test class of ResetAccountRecalFlag_ET
 */
@isTest
public class ResetAccountRecalFlagTest_ET {
  @testSetup
  static void setup() {
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory', false);
    accountList[0].Recalculate_Compensation__c = true;
    insert accountList[0];
  }

  public static testMethod void testResetAccountBatch() {
    Test.startTest();
    ResetAccountRecalFlag_ET batch = new ResetAccountRecalFlag_ET();
    batch.execute(null, [SELECT Id, Recalculate_Compensation__c FROM Account WHERE Recalculate_Compensation__c = TRUE]);
    Test.stopTest();
    System.assertEquals(
      false,
      [SELECT Id, Recalculate_Compensation__c FROM Account LIMIT 1][0]
      .Recalculate_Compensation__c
    );
  }
}