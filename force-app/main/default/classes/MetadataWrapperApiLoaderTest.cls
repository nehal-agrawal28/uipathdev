@isTest
private class MetadataWrapperApiLoaderTest 
{	
	@isTest(seeAllData=true)
    static void test_method_one() 
    {
        // Data Setup
        MetadataService.Metadata[] customMetadataRecords = new MetadataService.Metadata[25];

        List<USA_Industry__mdt> recordList =
            [
                SELECT Id
                FROM USA_Industry__mdt
                LIMIT 50
            ];

        Map<String, String> csToMDT_fieldMapping = new Map<String, String>();
        csToMDT_fieldMapping.put('Area__c', 'Area__c');

        MetadataMappingInfo mmi = new MetadataMappingInfo();
        mmi.setCustomMetadadataTypeName('USA_Industry__mdt');
        mmi.setRecordList(recordList);
        mmi.setCSToMDT_fieldMapping(csToMDT_fieldMapping);

        Set<String> standardFields = new Set<String>();
        standardFields.add('test-1-key');

        Map<String, String> fieldsAndValues = new Map<String, String>();
        fieldsAndValues.put('test-2-key', 'test-2-value');

		// Run Code
        Test.startTest();

            Test.setMock(WebServiceMock.class, new MetadataWrapperCalloutMock());

            MetadataWrapperApiLoader.getPort();

            MetadataWrapperApiLoader ctrl = new MetadataWrapperApiLoader();

            ctrl.response.isSuccess = true;
            ctrl.buildResponse();
            ctrl.migrateAsIsWithObjCreation('test1', 'test2');
            ctrl.migrateAsIsMapping('test1', 'test2');
            ctrl.migrateSimpleMapping('test1', 'test2');
            ctrl.migrateCustomMapping('test1', 'test2', 'test3');
            ctrl.migrate(mmi);
            ctrl.transformToCustomMetadata(standardFields, fieldsAndValues);
            ctrl.upsertMetadataAndValidate(customMetadataRecords);

        Test.stopTest();
	}
}