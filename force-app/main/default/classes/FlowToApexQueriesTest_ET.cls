/**
 * @AUTHOR: UIPath
 * @DATE: 26/05/2022
 * @DESCRIPTION: This is the test class for FlowToApexQueries_ET
 */
@isTest
public class FlowToApexQueriesTest_ET {
  public static Id territory2Id = [SELECT Id FROM Territory2 WHERE Name = 'AMER KAP I Sales 2' LIMIT 1]?.Id;
  public static Id regionterritory2Id = [SELECT Id FROM Territory2 WHERE Name = 'AMER KAP I' LIMIT 1]?.Id;

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
    objUser.LanguageLocaleKey = 'en_US';
    insert objUser;

    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 salesTerr = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory');
    TestFactory_ET.createUserTerritoryAssociation(salesTerr.Id, objUser.Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
  }

  static testMethod void testGetUserTerritory2Associations() {
    Territory2 salesTerr2 = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    List<FlowToApexQueries_ET.Request> requests = new List<FlowToApexQueries_ET.Request>();
    FlowToApexQueries_ET.Request req = new FlowToApexQueries_ET.Request();
    req.listOfTerritory2Ids = new List<Id>{ salesTerr2.Id };
    requests.add(req);
    List<List<Response_ET>> responses = FlowToApexQueries_ET.getUserTerritory2Associations(requests);
    System.assert(responses != null);
  }
}