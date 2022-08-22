/**
 * @AUTHOR: UIPath
 * @DATE: 22/10/2021
 * @DESCRIPTION: This is the test class for User Trigger
 */
@isTest
public class UsersTest_ET {
  public static Id territory2Id = [SELECT Id FROM Territory2 WHERE Name = 'Test Sales Territory 1' LIMIT 1]?.Id;

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
    objUser.ManagerId = Userinfo.getUserId();
    insert objUser;

    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');

    Territory2 terr1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');
  }

  static testMethod void testValidatePAMUserDeactivation() {
    Boolean exceptionThrown = false;

    Test.startTest();
    try {
      List<User> userList = [SELECT Id FROM User WHERE username = 'test839734@uiath.com'];
      if (!userList.isEmpty()) {
        //Creating Interim Account Manager UserTerritory2Association Record
        UserTerritory2Association IAMUTA = new UserTerritory2Association();
        IAMUTA.UserId = userList[0].Id;
        IAMUTA.Territory2Id = territory2Id;
        IAMUTA.RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER;
        insert IAMUTA;

        userList[0].IsActive = false;
        update userList[0];
      }
    } catch (Exception ex) {
      exceptionThrown = ex.getMessage().contains(System.Label.ETM_PAM_User_Deactivation_Error_Msg) ? true : false;
    }
    Test.stopTest();
    System.assertEquals(true, exceptionThrown);
  }

  static testMethod void testValidateIAMUserDeactivation() {
    Boolean exceptionThrown = false;

    Test.startTest();
    try {
      List<User> userList = [SELECT Id FROM User WHERE username = 'test839734@uiath.com'];

      if (!userList.isEmpty()) {
        // Create current user as Primary
        UserTerritory2Association IAMUTA = new UserTerritory2Association();
        IAMUTA.UserId = userList[0].Id;
        IAMUTA.Territory2Id = territory2Id;
        IAMUTA.RoleInTerritory2 = ETMConstant.INTERIM_ACCOUNT_MANAGER;
        insert IAMUTA;

        // it should get assigned as IAM and not deactivate interim
        userList[0].IsActive = false;
        update userList[0];
      }
    } catch (Exception ex) {
      exceptionThrown = ex.getMessage().contains(System.Label.ETM_Interim_User_Deactivation_Error_Msg) ? true : false;
    }
    Test.stopTest();
    System.assertEquals(true, exceptionThrown);
  }
}