@isTest
private class MetadataMapperFactoryTest 
{	
	@isTest static void test_method_one() 
    {
		// Run Code
        MetadataMapperType mt1 = MetadataMapperType.ASIS;
        MetadataMapperType mt2 = MetadataMapperType.SIMPLE;
        MetadataMapperType mt3 = MetadataMapperType.CUSTOM;

        Test.startTest();

            MetadataMapperFactory.getMapper(mt1);
            MetadataMapperFactory.getMapper(mt2);
            MetadataMapperFactory.getMapper(mt3);

        Test.stopTest();
	}
}