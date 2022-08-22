@isTest
public with sharing class CPQCloneRecordsControllerTest {
  @TestSetup
  static void makeData() {
    Product2 product1 = new Product2(
      Name = 'Product CPQCloneRecordsControllerTest',
      ProductCode = 'PROD12121',
      isActive = true
    );
    insert product1;
  }

  @IsTest
  private static void getInitialDataTest() {
    Test.startTest();
    Product2 p = [SELECT Id FROM Product2 LIMIT 1];
    CPQCloneRecordsController.CPQCloneRecordsWrapper wrapper = CPQCloneRecordsController.getInitialData(
      p.Id,
      'Product2'
    );
    System.assertEquals(wrapper.record != null, true);
    Test.stopTest();
  }

  @IsTest
  private static void cloneAndSaveRecordsTest() {
    Test.startTest();
    Product2 p = [SELECT Id FROM Product2 LIMIT 1];
    String cloneId = CPQCloneRecordsController.cloneAndSaveRecords('TEST', p.Id, 'Product2');
    System.assertEquals(cloneId != null, true);

    try {
      String returnId = CPQCloneRecordsController.getNewFeatureId(null, null, null);
    } catch (Exception e) {
    }
    Test.stopTest();
  }
}