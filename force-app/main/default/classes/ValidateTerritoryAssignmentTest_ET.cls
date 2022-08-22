/**
 * @AUTHOR: UIPath
 * @DATE: 27/10/2021
 * @DESCRIPTION: Test class of ValidateTerritoryAssignment_ET
 */
@isTest
public class ValidateTerritoryAssignmentTest_ET {
  public static testMethod void testValidateTerritoryAssignment() {
    User objUser1 = new User();
    objUser1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    objUser1.Username = 'test8397341@uiath.com';
    objUser1.LastName = 'Test1';
    objUser1.Email = 'test8397341@uiath.com';
    objUser1.Alias = 't839734';
    objUser1.TimeZoneSidKey = 'America/Los_Angeles';
    objUser1.LocaleSidKey = 'en_US';
    objUser1.EmailEncodingKey = 'UTF-8';
    objUser1.LanguageLocaleKey = 'en_US';
    insert objUser1;

    User objUser2 = new User();
    objUser2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    objUser2.Username = 'test8397342@uiath.com';
    objUser2.LastName = 'Test2';
    objUser2.Email = 'test8397341@uiath.com';
    objUser2.Alias = 't839734';
    objUser2.TimeZoneSidKey = 'America/Los_Angeles';
    objUser2.LocaleSidKey = 'en_US';
    objUser2.EmailEncodingKey = 'UTF-8';
    objUser2.LanguageLocaleKey = 'en_US';
    insert objUser2;

    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');

    Territory2 firstTerr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');
    Territory2 secondTerr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 2');
    Territory2 thirdTerr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 3');

    System.runAs(new User(Id = userinfo.getUserId())) {
      List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 1', true);
      List<ObjectTerritory2Association> listOfTerr = [
        SELECT Id, Territory2.Name, Territory2Id, AssociationCause
        FROM ObjectTerritory2Association
      ];
      List<ObjectTerritory2Association> listOfObjectTerritories = new List<ObjectTerritory2Association>();

      ObjectTerritory2Association objTerrAss1 = new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = firstTerr2.Id,
        AssociationCause = 'Territory2Manual'
      );
      listOfObjectTerritories.add(objTerrAss1);

      ObjectTerritory2Association objTerrAss2 = new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = secondTerr2.Id,
        AssociationCause = 'Territory2Manual'
      );
      listOfObjectTerritories.add(objTerrAss2);

      ObjectTerritory2Association objTerrAss3 = new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = thirdTerr2.Id,
        AssociationCause = 'Territory2Manual'
      );
      listOfObjectTerritories.add(objTerrAss3);

      TestFactory_ET.createUserTerritoryAssociation(firstTerr2.Id, objUser1.Id, ETMConstant.PRIMARY_TEMPORARY_ABSENCE);
      TestFactory_ET.createUserTerritoryAssociation(secondTerr2.Id, objUser2.Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
      insert listOfObjectTerritories;

      Test.startTest();
      ValidateTerritoryAssignment_ET batch = new ValidateTerritoryAssignment_ET();
      batch.execute(null, [SELECT Id, ObjectId FROM ObjectTerritory2Association]);
      Test.stopTest();

      List<ObjectTerritory2Association> listOfObjectAssTerritories = [SELECT Id FROM ObjectTerritory2Association];
      System.assertEquals(
        2,
        listOfObjectAssTerritories.size(),
        'The third territory assignment is going to deleted from the batch'
      );
    }
  }
}