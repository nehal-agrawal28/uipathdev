/**
    * @DESCRIPTION: This is Test Class for ProductTriggerHandler class
    * @AUTHOR: Slalom Consulting
*/
@IsTest(isParallel=true)
public with sharing class ProductTriggerHandlerTest {


    @isTest static void canUpdateProduct() {

        Product2 product = new Product2(
                Name = 'Test product ',
                ProductCode = 'testProductName',
                Family = 'Core Product',
                Sync_Status__c = 'Synced',
                Ext_Id__c = 'testProductName600'
        );

        insert product;

        product.Name = 'New Product Name';

        Test.startTest();
        Database.SaveResult updateResult = Database.update(product, false);
        Test.stopTest();

        System.assert(updateResult.isSuccess());

    }
}