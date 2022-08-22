@isTest
private class MetadataMapperCustomTest 
{	
	@isTest static void test_method_one() 
    {
		// Run Code
        Test.startTest();

            MetadataMapperCustom ctrl = new MetadataMapperCustom();
            ctrl.mapper('Region_Manager_Director__c', 'VAT_Settings__mdt', '{"Field_cs_1__c", "Field_mdt_1__c"}');
            ctrl.validate();
            ctrl.mapSourceTarget();

        Test.stopTest();
	}
}