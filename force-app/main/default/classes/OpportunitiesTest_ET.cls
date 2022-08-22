/**
 * @AUTHOR: UIPath
 * @DATE: 04/01/2022
 * @DESCRIPTION: Test class of Opportunities_ET
 */
@isTest
public class OpportunitiesTest_ET {
  public static testMethod void testOppBeforeUpdate() {
    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 terr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');
    System.runAs(new User(Id = userinfo.getUserId())) {
      List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 1', true);
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[0].Id, 'CPQ_Default', false);
      insert oppList;
      Test.startTest();
      oppList[0].StageName = ETMConstant.CLOSED_WON_BOOKED;
      update oppList;
      oppList[0] = [
        SELECT Id, Territory2Id, StageName, IsClosed, Closed_Territory__c, Territory_Updated_On__c, Owner_Sync_Status__c
        FROM Opportunity
        WHERE Id = :oppList[0].Id
      ];
      oppList[0].Territory2Id = terr2.Id;
      OpportunitiesService_ET service = (OpportunitiesService_ET) Application_ET.Service.newInstance(
        OpportunitiesService_ET.class
      );
      service.beforeUpdateOpportunity(
        oppList,
        new Map<Id, Opportunity>{ oppList[0].Id => new Opportunity(Id = oppList[0].Id) }
      );
      Test.stopTest();
      System.assertEquals(
        terr2.DeveloperName,
        oppList[0].Closed_Territory__c,
        'When Opportunity Stage is Closed Won Booked then Closed_Territory__c gets Territory Developer Name'
      );
      System.assertEquals(
        ETMConstant.OWNER_STATUS_OUT_OF_SYNC,
        oppList[0].Owner_Sync_Status__c,
        'Opportunity Owner Sync Status reset to Out of Sync'
      );
    }
  }
}