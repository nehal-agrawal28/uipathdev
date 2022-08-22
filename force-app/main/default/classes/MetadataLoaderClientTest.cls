@isTest
private class MetadataLoaderClientTest 
{	
	@isTest static void test_method_one() 
    {
		// Run Code
        Test.startTest();

            MetadataLoaderClient ctrl = new MetadataLoaderClient();
            ctrl.migrateMetatdataApex();
            ctrl.migrateAsIsWithObjCreation('DeveloperName', 'VAT_Settings__mdt');
            ctrl.migrateAsIsMapping('VAT_Settings_CS__c', 'VAT_Settings__mdt');
            ctrl.migrateSimpleMapping('VAT_Settings_CS__c.Active__c', 'VAT_Settings__mdt.IsActive__c');
            ctrl.migrateCustomMapping('VAT_Settings_CS__c', 'VAT_Settings__mdt', ' "Active__c" : "IsActive__c","Timeout__c" : "GlobalTimeout__c", "EndPointURL__c" :"URL__c", }');

        Test.stopTest();
	}
}