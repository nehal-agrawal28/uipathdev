@isTest
private class MetadataMapperDefaultTest 
{	
	@isTest static void test_method_one() 
    {
        // Run Code
		Test.startTest();

            MetadataMapperDefault ctrl = new MetadataMapperDefault();
            ctrl.mapper('Region_Manager_Director__c', 'VAT_Settings__mdt', null);
            ctrl.validate();
            ctrl.mapSourceTarget();
            ctrl.getMappingInfo();

        Test.stopTest();
	}
}