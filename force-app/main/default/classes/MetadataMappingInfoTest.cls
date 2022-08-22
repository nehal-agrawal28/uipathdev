@isTest
private class MetadataMappingInfoTest 
{	
	@isTest static void test_method_one() 
    {
        // Data Setup
        List<String> fieldList = new List<String>();
        fieldList.add('test');

		// Run Code
        Test.startTest();

            MetadataMappingInfo ctrl = new MetadataMappingInfo();

            ctrl.getStandardFields();
            ctrl.getSrcFieldNames();
            ctrl.getRecordList();
            ctrl.getCSToMDT_fieldMapping();
            ctrl.getCustomSettingName();
            ctrl.getCustomMetadadataTypeName();
            ctrl.getSrcFieldResultMap();
            ctrl.setCustomMetadadataTypeName('test');
            ctrl.setCustomSettingName('test');
            ctrl.setSrcFieldNames(fieldList);

        Test.stopTest();
	}
}