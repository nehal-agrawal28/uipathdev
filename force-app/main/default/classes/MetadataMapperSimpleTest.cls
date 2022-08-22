@isTest
private class MetadataMapperSimpleTest 
{	
	@isTest static void test_method_one() 
    {
        // Run Code
        Test.startTest();

		  MetadataMapperSimple ctrl = new MetadataMapperSimple();
          ctrl.mapper('Region_Manager_Director__c.Region__c', 'VAT_Settings__mdt.Active__c', null);
          ctrl.validate();
          ctrl.mapSourceTarget();

        Test.stopTest();
	}
}