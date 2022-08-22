@isTest
public class RHX_TEST_Pre_Sales_Tasks {
    static testMethod void RHX_Testmethod() {
      Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
        Pre_Sales_Tasks__c testTask = new Pre_Sales_Tasks__c();
        testTask.Detailed_Description__c = 'Test PreSales';
        testTask.Assignment_Type__c = 'Online';
        testTask.Has_an_NDA_been_signed__c = 'Yes';
        testTask.Customer_Contact_email__c = 'mail@gmail.com';
        testTask.Due_Date__c = Date.newInstance(2025,12,31 );
        testTask.Products_in_Scope__c = 'Automation Cloud';
        testTask.Type__c = Constants.PRESALES_TASK_TYPE_1;
        testTask.Delivery_Tag__c = 'UiPath Led - partner is absent';
        testTask.Demo_Audience__c = Constants.PRESALES_TASK_DEMO_AUDIENCE_1;
        testTask.Customer_familiar_with_UiPath_tools_prod__c = Constants.PRESALES_TASK_CUSTOMER_FAMILIAR_WITH_TOOLS_1;
        testTask.Request_Description__c = 'This is a test description';
       // testTask.Opportunity__c = o.Id ;
        insert testTask;
        
        rh2.ParentUtil.UpsertRollupTestRecords(new List<Pre_Sales_Tasks__c> { testTask });
    }
}