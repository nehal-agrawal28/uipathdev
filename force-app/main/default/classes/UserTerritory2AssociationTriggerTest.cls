/**
 * @AUTHOR: UIPath
 * @DATE: 07/09/2021
 * @DESCRIPTION: This is the test class for UserTerritory2Association Trigger test
 */
@isTest
public class UserTerritory2AssociationTriggerTest {
  public static Id territory2Id = [SELECT Id FROM Territory2 WHERE Name = 'AMER KAP I Sales 2' LIMIT 1]?.Id;
  public static Id regionterritory2Id = [SELECT Id FROM Territory2 WHERE Name = 'AMER KAP I' LIMIT 1]?.Id;

  @testSetup
  static void setup() {
    User managerUser = new User();
    managerUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    managerUser.Username = 'test839734manager@uiath.com';
    managerUser.LastName = 'Test';
    managerUser.Email = 'test839734manager@uiath.com';
    managerUser.Alias = 't839734m';
    managerUser.TimeZoneSidKey = 'America/Los_Angeles';
    managerUser.LocaleSidKey = 'en_US';
    managerUser.EmailEncodingKey = 'UTF-8';
    managerUser.LanguageLocaleKey = 'en_US';
    managerUser.LanguageLocaleKey = 'en_US';
    insert managerUser;

    List<User> lstObjUser = new List<User>();
    User objUser = new User();
    objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    objUser.Username = 'test839734@uiath.com';
    objUser.ManagerId = managerUser.Id;
    objUser.LastName = 'Test';
    objUser.Email = 'test839734@uiath.com';
    objUser.Alias = 't839734';
    objUser.TimeZoneSidKey = 'America/Los_Angeles';
    objUser.LocaleSidKey = 'en_US';
    objUser.EmailEncodingKey = 'UTF-8';
    objUser.LanguageLocaleKey = 'en_US';
    objUser.LanguageLocaleKey = 'en_US';
    lstObjUser.add(objUser);

    User objUser2 = new User();
    objUser2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    objUser2.Username = 'test2@uiath.com';
    objUser2.ManagerId = managerUser.Id;
    objUser2.LastName = 'Test';
    objUser2.Email = 'test2@uiath.com';
    objUser2.Alias = 't839734';
    objUser2.TimeZoneSidKey = 'America/Los_Angeles';
    objUser2.LocaleSidKey = 'en_US';
    objUser2.EmailEncodingKey = 'UTF-8';
    objUser2.LanguageLocaleKey = 'en_US';
    objUser2.LanguageLocaleKey = 'en_US';
    lstObjUser.add(objUser2);

    insert lstObjUser;

    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 salesTerr = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory');

    Territory2 salesTerr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 2');
    Territory2 salesTerr3 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 3');
    Territory2 salesTerr4 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 4');

    //Creating Interim Account Manager UserTerritory2Association Record
    TestFactory_ET.createUserTerritoryAssociation(salesTerr2.Id, objUser.Id, ETMConstant.INTERIM_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(salesTerr3.Id, managerUser.Id, ETMConstant.REGION_PARTNER_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(
      salesTerr4.Id,
      managerUser.Id,
      ETMConstant.VACANT_TERR_COMP_PART_MANAGER
    );
  }

  static testMethod void testValidatePartnerManagerRoles() {
    Boolean exceptionThrown = false;
    Territory2 salesTerr2 = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    User secondUser = [SELECT Id FROM user WHERE username = 'test839734@uiath.com' LIMIT 1];
    List<UserTerritory2Association> listOfUserTerr = new List<UserTerritory2Association>();

    Test.startTest();
    UserTerritory2Association userTerr1 = TestFactory_ET.createUserTerritoryAssociation(
      salesTerr2.Id,
      Userinfo.getUserId(),
      ETMConstant.GEO_PARTNER_MANAGER
    );
    UserTerritory2Association userTerr2 = TestFactory_ET.createUserTerritoryAssociation(
      salesTerr2.Id,
      secondUser.Id,
      ETMConstant.INTERIM_ACCOUNT_MANAGER
    );
    try {
      userTerr2.RoleInTerritory2 = ETMConstant.GEO_PARTNER_MANAGER;
      update userTerr2;
    } catch (Exception ex) {
      exceptionThrown = ex.getMessage().contains(ETMConstant.GEO_PARTNER_MANAGER) ? true : false;
    }
    Test.stopTest();
    System.assertEquals(
      true,
      exceptionThrown,
      'User Territory Association cannot have two records with partner manager roles'
    );
  }

  static testMethod void testValidateDoubleInterimAccountManager() {
    Boolean exceptionThrown = false;
    Territory2 salesTerr2 = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    Test.startTest();
    try {
      UserTerritory2Association IAMUTA = new UserTerritory2Association();
      IAMUTA.UserId = Userinfo.getUserId();
      IAMUTA.Territory2Id = salesTerr2.Id;
      IAMUTA.RoleInTerritory2 = ETMConstant.INTERIM_ACCOUNT_MANAGER;
      insert IAMUTA;
    } catch (Exception ex) {
      exceptionThrown = ex.getMessage().contains(System.Label.Duplicate_Interim_Account_Manager_Error_Message)
        ? true
        : false;
    }
    Test.stopTest();
    System.assertEquals(
      true,
      exceptionThrown,
      'User Territory Association cannot have two Interim Account Manager Records'
    );
  }

  static testMethod void testvalidatePAMUsers() {
    Boolean exceptionThrown = false;
    Territory2 salesTerr2 = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    Territory2 salesTerritory = TestFactory_ET.getTerritoryId('Test Sales Territory');
    User pamUser = [SELECT Id, isActive, Name FROM user WHERE username = 'test839734@uiath.com'];
    Test.startTest();
    try {
      UserTerritory2Association PAMUTA = TestFactory_ET.createUserTerritoryAssociation(
        salesTerritory.Id,
        pamUser.Id,
        ETMConstant.PRIMARY_ACCOUNT_MANAGER
      );
      pamUser.isActive = false;
      update pamUser;
    } catch (Exception ex) {
      exceptionThrown = ex.getMessage().contains(System.Label.ETM_PAM_User_Deactivation_Error_Msg) ? true : false;
    }
    Test.stopTest();
    System.assertEquals(
      true,
      exceptionThrown,
      'User cannot be deactivated while assigned as Primary Account Manager for a territory. Please remove user from the territory before deactivating.'
    );
  }

  static testMethod void testvalidateIAMUsers() {
    Boolean exceptionThrown = false;
    Territory2 salesTerr2 = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    User iamUser = [SELECT Id, isActive, Name FROM user WHERE username = 'test839734@uiath.com'];

    Test.startTest();
    try {
      iamUser.isActive = false;
      update iamUser;
    } catch (Exception ex) {
      exceptionThrown = ex.getMessage().contains(System.Label.ETM_Interim_User_Deactivation_Error_Msg) ? true : false;
    }
    Test.stopTest();
    System.assertEquals(
      true,
      exceptionThrown,
      'Please add Primary Account Manager in territory before deleting Interim Account Manager.'
    );
  }

  static testMethod void testRollupAccountManager() {
    Territory2 salesTerritory = TestFactory_ET.getTerritoryId('Test Sales Territory');
    User pamUser = [SELECT Id, Name FROM user WHERE username = 'test839734@uiath.com'];

    territory2Id = salesTerritory.Id;
    Test.startTest();
    //Creating Primary Account Manager UserTerritory2Association Record
    UserTerritory2Association PAMUTA = TestFactory_ET.createUserTerritoryAssociation(
      salesTerritory.Id,
      pamUser.Id,
      ETMConstant.PRIMARY_ACCOUNT_MANAGER
    );
    Test.stopTest();

    Territory2 objTerritory2 = [
      SELECT Id, Primary_Account_Manager_Name__c, Primary_Account_Manager_Id__c
      FROM Territory2
      WHERE Id = :territory2Id
      LIMIT 1
    ];
    System.assertEquals(
      objTerritory2.Primary_Account_Manager_Name__c,
      pamUser.Name,
      'After Creating Primary Account Manager UserTerritory2Association Record, Primary_Account_Manager_Name__c field get updated from User name'
    );
    System.assertEquals(
      objTerritory2.Primary_Account_Manager_Id__c,
      pamUser.Id,
      'After Creating Primary Account Manager UserTerritory2Association Record, Primary_Account_Manager_Id__c field get updated from User Id'
    );

    List<UserTerritory2Association> listOfInterimUTA = [
      SELECT Id
      FROM UserTerritory2Association
      WHERE Territory2Id = :territory2Id AND RoleInTerritory2 = :ETMConstant.INTERIM_ACCOUNT_MANAGER
      LIMIT 1
    ];

    System.assertEquals(
      0,
      listOfInterimUTA.size(),
      'After Creating Primary Account Manager UserTerritory2Association Record, Interim Account Manager UserTerritory2Association Record should be deleted'
    );

    PAMUTA.RoleInTerritory2 = ETMConstant.PRIMARY_TEMPORARY_ABSENCE;
    update PAMUTA;

    List<UserTerritory2Association> listOfInterimUTA2 = [
      SELECT Id
      FROM UserTerritory2Association
      WHERE Territory2Id = :territory2Id AND RoleInTerritory2 = :ETMConstant.INTERIM_SALES_MANAGER
    ];

    System.assertEquals(
      1,
      listOfInterimUTA2.size(),
      'After Updating UserTerritory2Association record from Primary Account Manager to Primary - Temporary Absence, new UserTerritory2Association record for Interim Account Manager will be created'
    );

    delete PAMUTA;
    Territory2 objTerritory2v1 = [
      SELECT Id, Primary_Account_Manager_Name__c, Primary_Account_Manager_Id__c
      FROM Territory2
      WHERE Id = :territory2Id
      LIMIT 1
    ];
    System.assertEquals(
      null,
      objTerritory2v1.Primary_Account_Manager_Name__c,
      'After removing Primary - Temporary Absence from Territory, Primary Account Manager value reset to Null'
    );
    System.assertEquals(
      null,
      objTerritory2v1.Primary_Account_Manager_Id__c,
      'After removing Primary - Temporary Absence from Territory, Primary Account Manager Id value reset to Null'
    );
  }

  static testMethod void testupdateLeadonTerritory() {
    Territory2 regionTerritory = TestFactory_ET.getTerritoryId('Region');
    regionterritory2Id = regionTerritory.Id;
    Test.startTest();
    UserTerritory2Association RVPUTA = TestFactory_ET.createUserTerritoryAssociation(
      regionTerritory.Id,
      Userinfo.getUserId(),
      ETMConstant.REGION_VP
    );
    Test.stopTest();

    Territory2 objTerritory2RVP = [
      SELECT Id, RVP_Name__c, RVP_Id__c
      FROM Territory2
      WHERE Id = :regionterritory2Id
      LIMIT 1
    ];
    system.debug('objTerritory2RVP' + objTerritory2RVP.RVP_Name__c + objTerritory2RVP.RVP_Id__c);
    System.assertEquals(
      objTerritory2RVP.RVP_Name__c,
      Userinfo.getName(),
      'After Creating Regional VP UserTerritory2Association Record, RVP_Name__c field gets updated from User name'
    );
    System.assertEquals(
      objTerritory2RVP.RVP_Id__c,
      RVPUTA.UserId,
      'After Creating Regional VP UserTerritory2Association Record, RVP_Id__c field gets updated from User Id'
    );

    delete RVPUTA;
    Territory2 objTerritory2del = [
      SELECT Id, RVP_Name__c, RVP_Id__c
      FROM Territory2
      WHERE Id = :regionterritory2Id
      LIMIT 1
    ];
    System.assertEquals(
      objTerritory2del.RVP_Name__c,
      null,
      'After deleting UserTerritory2Association Record, RVP_Name__c field gets updated to null'
    );
    System.assertEquals(
      objTerritory2del.RVP_Id__c,
      null,
      'After deleting UserTerritory2Association Record, RVP_Id__c field gets updated to null'
    );
  }

  static testMethod void updateRPMonTerritory() {
    Territory2 salesTerritory = TestFactory_ET.getTerritoryId('Test Sales Territory 3');
    User RPMUser = [SELECT Id, Name FROM user WHERE username = 'test839734@uiath.com'];
    territory2Id = salesTerritory.Id;
    Test.startTest();
    //Creating Region Partner Manager UserTerritory2Association Record
    UserTerritory2Association RPMUTA = new UserTerritory2Association();
    RPMUTA.Territory2Id = salesTerritory.Id;
    RPMUTA.UserId = RPMUser.Id;
    RPMUTA.RoleInTerritory2 = ETMConstant.REGION_PARTNER_MANAGER;
    insert RPMUTA;
    Test.stopTest();

    Territory2 objTerritory2 = [
      SELECT Id, Partner_Manager_Team_Credit__c
      FROM Territory2
      WHERE Id = :territory2Id
      LIMIT 1
    ];
    System.assertEquals(objTerritory2.Partner_Manager_Team_Credit__c, true, 'Asserted');
  }

  static testMethod void deleteVacantTerritoryManagersTest() {
    Territory2 salesTerritory = TestFactory_ET.getTerritoryId('Test Sales Territory 4');
    User GSIUser = [SELECT Id, Name FROM user WHERE username = 'test2@uiath.com'];
    // territory2Id = salesTerritory.Id;
    Test.startTest();
    //Creating Region Partner Manager UserTerritory2Association Record
    UserTerritory2Association GSIUTA = TestFactory_ET.createUserTerritoryAssociation(
      salesTerritory.Id,
      GSIUser.Id,
      ETMConstant.GSI_PARTNER_MANAGER
    );

    Test.stopTest();

    List<UserTerritory2Association> listOfVACUTA = [
      SELECT Id
      FROM UserTerritory2Association
      WHERE Territory2Id = :territory2Id AND RoleInTerritory2 = :ETMConstant.VACANT_TERR_COMP_PART_MANAGER
      LIMIT 1
    ];

    System.assertEquals(
      0,
      listOfVACUTA.size(),
      'After Creating GSI Partner Manager UserTerritory2Association Record, Vacant Territory Comp Manager UserTerritory2Association Record should be deleted'
    );
  }
}