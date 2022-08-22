@isTest
private class MetadataObjectCreatorTest 
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
        csToMDT_fieldMapping.put('area__c', 'area__c');

        Map<String, Schema.DescribeFieldResult> fdMap = new Map<String, Schema.DescribeFieldResult>();

        Schema.DescribeFieldResult dfr = USA_Industry__mdt.Area__c.getDescribe();
        
        fdMap.put('area__c', dfr);

        MetadataMappingInfo mmi = new MetadataMappingInfo();
        mmi.setCustomMetadadataTypeName('USA_Industry__mdt');
        mmi.setRecordList(recordList);
        mmi.setCSToMDT_fieldMapping(csToMDT_fieldMapping);
        mmi.setSrcFieldResultMap(fdMap);

		// Run Code
        Test.startTest();

            Test.setMock(WebServiceMock.class, new MetadataWrapperCalloutMock());

            MetadataObjectCreator.createCustomObject(mmi);
            MetadataObjectCreator.createCustomField(mmi);

            MetadataMigrationException ctrl = new MetadataMigrationException();

        Test.stopTest();
	}
}