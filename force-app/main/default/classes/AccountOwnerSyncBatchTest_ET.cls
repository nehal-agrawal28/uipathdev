/**
 * @AUTHOR: UIPath
 * @DATE: 20/10/2021
 * @DESCRIPTION: Test class of AccountOwnerSyncBatch_ET
 */
@isTest
public class AccountOwnerSyncBatchTest_ET {
  @testSetup
  static void setup() {
    User objUser = new User();
    objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
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
    Territory2 salesTerr = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory');

    TestFactory_ET.createUserTerritoryAssociation(salesTerr.Id, objUser.Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
    List<Account> accountList;
    System.runAs(objUser) {
      accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory', true);
      TestFactory_ET.createOpportunities(1, accountList[0].Id, 'CPQ_Default', true);
    }
    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = salesTerr.Id,
        AssociationCause = 'Territory2Manual'
      );
    }
  }

  public static testMethod void accountOwnerSync() {
    Test.startTest();
    AccountOwnerSyncBatch_ET batch = new AccountOwnerSyncBatch_ET();
    batch.execute(null, [SELECT Id FROM Account]);
    Test.stopTest();
    System.assertEquals('Synched', [SELECT Owner_Sync_Status__c FROM Account LIMIT 1][0].Owner_Sync_Status__c);
  }

  public static testMethod void accountOwnerSyncFinish() {
    Test.startTest();
    AccountOwnerSyncBatch_ET batch = new AccountOwnerSyncBatch_ET();
    batch.setOfExceptionAccountIds.add([SELECT Id FROM Account][0].Id);
    batch.finish(null);
    Test.stopTest();
  }
}