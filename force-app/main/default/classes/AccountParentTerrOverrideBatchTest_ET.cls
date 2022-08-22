/**
 * @AUTHOR: UIPath
 * @DATE: 30/05/2022
 * @DESCRIPTION: This is AccountParentTerrOverrideBatch_ET test class
 */
@isTest
public class AccountParentTerrOverrideBatchTest_ET {
  @testSetup
  static void setup() {
    Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    User objUser = new User();
    objUser.ProfileId = systemAdminProfileId;
    objUser.Username = 'test839734@uiath.com';
    objUser.LastName = 'Test';
    objUser.Email = 'test839734@uiath.com';
    objUser.Alias = 't839734';
    objUser.TimeZoneSidKey = 'America/Los_Angeles';
    objUser.LocaleSidKey = 'en_US';
    objUser.EmailEncodingKey = 'UTF-8';
    objUser.LanguageLocaleKey = 'en_US';
    insert objUser;

    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 terr1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');
    TestFactory_ET.createUserTerritoryAssociation(terr1.Id, objUser.Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
  }

  public static testMethod void testAccountParentTerrOverrideBatch() {
    Territory2 terr = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 1', false);
    accountList[0].Is_Domestic_Child__c = true;
    insert accountList;
    System.runAs(new User(Id = userinfo.getUserId())) {
      Test.startTest();
      AccountParentTerrOverrideBatch_ET batchable = new AccountParentTerrOverrideBatch_ET();
      batchable.execute(null, accountList);
      Test.stopTest();
      List<Account> accList = [SELECT Id, Parent_Territory_Override__c FROM Account LIMIT 1];
      System.assertEquals(true, accList[0].Parent_Territory_Override__c);
    }
  }
}