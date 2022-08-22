@isTest
private class MetadataUtilTest 
{	
	@isTest static void test_method_one() 
    {
		// Data Setup
        MetadataService.Metadata[] customMetadataRecords = new MetadataService.Metadata[25];

        Set<String> standardFields = new Set<String>();
        standardFields.add('test-1-key');

        List<List<String>> fieldValues = new List<List<String>>();
        List<String> fieldValueList = new List<String>();
        fieldValueList.add('Label_test');

        fieldValues.add(fieldValueList);

        List<String> header = new List<String>();

        String selectedType = 'USA_Industry__mdt';
        Integer startIndex = 3;

        Map<String, String> fieldsAndValues = new Map<String, String>();
        fieldsAndValues.put('test-2-key', 'test-2-value');

        // Run Code
        Test.startTest();

            Test.setMock(WebServiceMock.class, new MetadataWrapperCalloutMock());

            MetadataUtil.Status statusEnum = MetadataUtil.Status.NOT_CHECKED;
            MetadataUtil.checkMetadataAPIConnection();

            MetadataUtil.transformToCustomMetadataAndCreateUpdate(standardFields, null, header, selectedType, startIndex);            

            header = new List<String>();
            MetadataUtil.transformToCustomMetadataAndCreateUpdate(standardFields, fieldValues, header, selectedType, startIndex);

            MetadataUtil.transformToCustomMetadata(standardFields, fieldsAndValues);
            MetadataUtil.upsertMetadataAndValidate(customMetadataRecords);

            header = new List<String>();
            header.add('Label');
            MetadataUtil.transformToCustomMetadataAndCreateUpdate(standardFields, fieldValues, header, selectedType, startIndex);

            MetadataMapperType varEnum = MetadataMapperType.ASIS;

        Test.stopTest();
	}
}