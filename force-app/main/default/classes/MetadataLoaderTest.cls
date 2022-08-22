@isTest
private class MetadataLoaderTest 
{	
	@isTest static void test_method_one() 
    {
		// Run Code
        Test.startTest();

            MetadataLoader ctrl = new MetadataLoader();
            ctrl.migrateAsIsWithObjCreation('DeveloperName', 'VAT_Settings__mdt');
            ctrl.migrateAsIsMapping('DeveloperName', 'VAT_Settings__mdt');

        Test.stopTest();
	}
}