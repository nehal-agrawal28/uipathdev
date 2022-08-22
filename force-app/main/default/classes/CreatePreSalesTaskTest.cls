/**
*
* Author:       Mirela Chituc
* Date:         02/09/2019
* Description:  Test class for CreatePreSalesTask
*
**/

@IsTest(isParallel=true)
public with sharing class CreatePreSalesTaskTest {

    
    
    public static testMethod void CreatePreSalesTaskTest1() {
        
        Id recordTypeId = Schema.SObjectType.Pre_Sales_Tasks__c.getRecordTypeInfosByDeveloperName().get('Immersion_Lab_Request').getRecordTypeId();
        String recordTypeIdStr = String.valueOf(recordTypeId);
        Test.startTest();

        List<CreatePreSalesTask.LayoutSection> result = CreatePreSalesTask.getPageLayoutFields(recordTypeIdStr);
        
        Test.stopTest();
    }
    
    public static testMethod void CreatePreSalesTaskTest2() {

        
        Id recordTypeId = Schema.SObjectType.Pre_Sales_Tasks__c.getRecordTypeInfosByDeveloperName().get('Account_Tasks').getRecordTypeId();
        String recordTypeIdStr = String.valueOf(recordTypeId);
        Test.startTest();

        List<CreatePreSalesTask.LayoutSection> result = CreatePreSalesTask.getPageLayoutFields(recordTypeIdStr);
        
        Test.stopTest();
    }

}