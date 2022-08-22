/**
 * @AUTHOR: UIPath
 * @DATE: 30/05/2022
 * @DESCRIPTION: This is OpportunityMYDUpdates test class
 */
@isTest
public class OpportunityMYDUpdatesTest_ET {
  @testSetup
  static void setup() {
    Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

    List<User> userList = new List<User>();

    for (Integer i = 1; i < 3; i++) {
      User objUser = new User();
      objUser.ProfileId = systemAdminProfileId;
      objUser.Username = 'test839734@' + i + 'uiath.com';
      objUser.LastName = 'Test';
      objUser.Email = 'test839734@uiath.com';
      objUser.Alias = 't839734';
      objUser.TimeZoneSidKey = 'America/Los_Angeles';
      objUser.LocaleSidKey = 'en_US';
      objUser.EmailEncodingKey = 'UTF-8';
      objUser.LanguageLocaleKey = 'en_US';
      userList.add(objUser);
    }
    insert userList;

    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');

    Territory2 terr1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');

    TestFactory_ET.createUserTerritoryAssociation(terr1.Id, userList[0].Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
  }

  public static testMethod void syncOpportunityMYDwithTerr() {
    Territory2 terr = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 1', true);
    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = terr.Id,
        AssociationCause = 'Territory2Manual'
      );
    }
    List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[0].Id, 'CPQ_Default', false);
    insert oppList;
    List<Opportunity> updatedOppList = [
      SELECT
        Id,
        Territory2.Name,
        Territory2.Primary_Account_Manager_Id__c,
        Territory2.Interim_Account_Manager_Id__c,
        Closed_Territory__c,
        Deal_Type__c,
        AccountId,
        Owner_Sync_Status__c,
        Lead_Sales_Engineer__c
      FROM Opportunity
    ];
    updatedOppList[0].Territory2 = terr;
    updatedOppList[0].Territory2Id = terr.Id;
    Test.startTest();
    OpportunityMYDUpdates_ET batch = new OpportunityMYDUpdates_ET();
    batch.execute(null, updatedOppList);
    Test.stopTest();
    System.assertEquals(
      'Test Sales Territory 1',
      [SELECT Closed_Territory__c FROM Opportunity LIMIT 1][0]
      .Closed_Territory__c
    );
  }
}