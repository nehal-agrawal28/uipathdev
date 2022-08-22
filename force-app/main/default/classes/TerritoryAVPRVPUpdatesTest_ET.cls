/**
 * @AUTHOR: UIPath
 * @DATE: 30/05/2022
 * @DESCRIPTION: This is test class to update AVP RVP on Parnter Territories
 */
@isTest
public class TerritoryAVPRVPUpdatesTest_ET {
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

    Territory2Type partnerTerrType = [
      SELECT Id, DeveloperName
      FROM Territory2Type
      WHERE MasterLabel = :ETMConstant.PARTNER_MANAGEMENT
    ];

    regionTerr.Territory2TypeId = partnerTerrType.id;
    update regionTerr;

    TestFactory_ET.createUserTerritoryAssociation(regionTerr.Id, userList[0].Id, ETMConstant.PARTNER_LEADER);
  }

  public static testMethod void syncAVPRVPTerr() {
    Territory2 regionTerritory = TestFactory_ET.getTerritoryId('Region');

    User partnerUser = [SELECT Id, Name FROM user WHERE username = 'test839734@1uiath.com'];

    Test.startTest();
    TerritoryAVPRVPUpdates_ET batch = new TerritoryAVPRVPUpdates_ET();
    batch.execute(
      null,
      [
        SELECT
          id,
          name,
          Ultimate_Geo__c,
          Area__c,
          Region__c,
          Sales_Area__c,
          Sales_Geo__c,
          Sales_Region__c,
          DeveloperName,
          RVP_Id__c,
          AVP_Id__c,
          GVP_Id__c,
          AVP_Name__c,
          RVP_Name__c,
          GVP_Name__c,
          Territory2Type.MasterLabel,
          Territory2Type.DeveloperName,
          Sales_Territory__c
        FROM Territory2
        WHERE id = :regionTerritory.Id
      ]
    );
    Test.stopTest();
    Territory2 objTerritory2RVP = [
      SELECT Id, RVP_Name__c, RVP_Id__c
      FROM Territory2
      WHERE Id = :regionTerritory.Id
      LIMIT 1
    ];
    system.debug('objTerritory2RVP' + objTerritory2RVP.RVP_Name__c + objTerritory2RVP.RVP_Id__c);
    System.assertEquals(
      objTerritory2RVP.RVP_Name__c,
      partnerUser.Name,
      'After Creating Regional VP UserTerritory2Association Record, RVP_Name__c field gets updated from User name'
    );
  }
}