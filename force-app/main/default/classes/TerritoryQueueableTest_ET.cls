/**
 * @AUTHOR: UIPath
 * @DATE: 24/03/2022
 * @DESCRIPTION: This is test class of TerritoryQueueable_ET class
 */
@isTest
public class TerritoryQueueableTest_ET {
  static testMethod void testTerritoryQueueable() {
    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 salesTerr = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory', false);
    salesTerr.Recalculate_Compensation__c = true;
    insert salesTerr;

    Test.startTest();
    new TerritoryQueueable_ET(new Set<Id>{ salesTerr.Id }, false).work();
    Test.stopTest();
    Territory2 terr = [SELECT Id, Recalculate_Compensation__c FROM Territory2 WHERE Id = :salesTerr.Id LIMIT 1];
    System.assertEquals(false, terr.Recalculate_Compensation__c);
  }
}