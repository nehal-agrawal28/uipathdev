/**
 * @AUTHOR: UIPath
 * @DATE: 20/10/2021
 * @DESCRIPTION: Test class of GenericBatch
 */
@isTest
public class GenericBatchTest {
  public static testMethod void batchTest() {
    Batch_Apex__c parent = new Batch_Apex__c(Name = 'Test Parent');
    insert parent;
    List<Batch_Apex__c> apexList = new List<Batch_Apex__c>();
    apexList.add(
      new Batch_Apex__c(
        Parent__c = parent.Id,
        Name = 'Test Batch 1',
        Start_Query__c = 'Select Id From ObjectTerritory2Association',
        Batch_Class__c = 'TerritoryAccountOwnerSyncBatch_ET',
        Order__c = 1,
        DateTime_Filter__c = 'SystemModstamp >= [DATE_VALUE]',
        Last_Run_DateTime__c = System.now().addDays(-1)
      )
    );

    apexList.add(
      new Batch_Apex__c(
        Parent__c = parent.Id,
        Name = 'Test Batch 2',
        Start_Query__c = 'Select Id From ObjectTerritory2Association',
        Batch_Class__c = 'TerritoryAccountOwnerSyncBatch_ET',
        Order__c = 2,
        DateTime_Filter__c = 'Territory2.SystemModstamp >= [DATE_VALUE]',
        Last_Run_DateTime__c = System.now().addDays(-1)
      )
    );
    insert apexList;
    TestFactory_ET.createAccounts(3, 'Customer', 'KAP I Sales 2', true);
    Test.startTest();
    Database.executeBatch(new GenericBatch('Test Parent', 1), 10);
    Test.stopTest();
    System.assertEquals(
      System.today(),
      [SELECT Last_Run_DateTime__c FROM Batch_Apex__c WHERE Name = 'Test Batch 1'][0].Last_Run_DateTime__c.date()
    );
  }
}