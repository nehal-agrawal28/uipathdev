@isTest
private class MetadataMigrationControllerTest 
{	
	@isTest static void test_method_one() 
    {
		// Run Code
        Test.startTest();

            Test.setMock(WebServiceMock.class, new MetadataWrapperCalloutMock());

            MetadataMigrationController ctrl = new MetadataMigrationController();

            ctrl.opTypeFieldObjCreation = 'METADATAAPEX';
            ctrl.migrateAsIsWithObjCreation();

            ctrl.selectedOpTypeAsIs = 'METADATAAPEX';
            ctrl.migrateAsIsMapping();

            ctrl.selectedOpTypeSimple = 'METADATAAPEX';
            ctrl.migrateSimpleMapping();

            ctrl.selectedOpTypeCustom = 'METADATAAPEX';
            ctrl.migrateCustomMapping();

        Test.stopTest();
	}
}