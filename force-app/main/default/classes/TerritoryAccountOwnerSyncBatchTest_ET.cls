/**
 * @AUTHOR: UIPath
 * @DATE: 20/10/2021
 * @DESCRIPTION: Test class of TerritoryAccountOwnerSyncBatch_ET
 */
@isTest
public class TerritoryAccountOwnerSyncBatchTest_ET {
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
    TerritoryAccountOwnerSyncBatch_ET batch = new TerritoryAccountOwnerSyncBatch_ET();
    batch.execute(
      null,
      [
        SELECT
          ObjectId,
          Id,
          Territory2.Interim_Account_Manager_Id__c,
          Territory2.Primary_Account_Manager_Id__c,
          Territory2.Ultimate_Geo__c,
          Territory2.Area__c,
          Territory2.Region__c
        FROM ObjectTerritory2Association
        WHERE Territory2.SystemModstamp >= Yesterday AND Territory2.Sales_Territory__c = TRUE
        ORDER BY SystemModstamp DESC
      ]
    );
    Test.stopTest();
    System.assertEquals('Synched', [SELECT Owner_Sync_Status__c FROM Account LIMIT 1][0].Owner_Sync_Status__c);
  }

  public static testMethod void territoryAccountOwnerSyncFinish() {
    Test.startTest();
    TerritoryAccountOwnerSyncBatch_ET batch = new TerritoryAccountOwnerSyncBatch_ET();
    batch.setOfExceptionAccountIds.add([SELECT Id FROM Account][0].Id);
    batch.finish(null);
    Test.stopTest();
  }
}