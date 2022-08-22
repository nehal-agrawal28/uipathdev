@isTest
private class MetadataResponseTest 
{	
	@isTest static void test_method_one() 
    {
        // Data Setup
        MetadataMappingInfo mmi = new MetadataMappingInfo();

        List<MetadataResponse.Message> mrList = new List<MetadataResponse.Message>();

		// Run Code
        Test.startTest();

            MetadataResponse ctrl = new MetadataResponse();
            MetadataResponse ctrl2 = new MetadataResponse(true, mmi, mrList);

            ctrl2.isSuccess();
            ctrl2.setIsSuccess(true);
            ctrl2.setMappingInfo(mmi);
            ctrl2.getMappingInfo();
            ctrl2.getMessages();
            ctrl2.setMessages(mrList);
            ctrl2.debug();

            MetadataResponse.Message message = new MetadataResponse.Message();
            MetadataResponse.Message message2 = new MetadataResponse.Message(2, 'testString');

            // MetadataOpType - code coverage
            MetadataOpType enumTest = MetadataOpType.APEXWRAPPER; 

        Test.stopTest();
	}
}