/**
 * @AUTHOR: UIPath
 * @DATE: 07/12/2021
 * @DESCRIPTION: This is test class of territories_ET trigger
 */
@isTest
public class TerritoriesServiceTest_ET {
  public static Id regionterritory2Id = [SELECT Id FROM Territory2 WHERE Name = 'Region' LIMIT 1]?.Id;
  public static Id territory2Id = [SELECT Id FROM Territory2 WHERE Name = 'Test Sales Territory' LIMIT 1]?.Id;

  @testSetup
  static void setup() {
    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 salesTerr = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory');
  }

  static testMethod void testupdateAVPRVPonTerritory() {
    Test.startTest();
    UserTerritory2Association RVPUTA = new UserTerritory2Association();
    RVPUTA.UserId = Userinfo.getUserId();
    RVPUTA.Territory2Id = regionterritory2Id;
    RVPUTA.RoleInTerritory2 = ETMConstant.REGION_VP;
    insert RVPUTA;
    Test.stopTest();

    Territory2 objTerritory2RVP = [SELECT Id, RVP_Id__c FROM Territory2 WHERE Id = :territory2Id LIMIT 1];

    System.assertEquals(objTerritory2RVP.RVP_Id__c, Userinfo.getUserId(), 'RVP Rollup to child territory');
  }
}