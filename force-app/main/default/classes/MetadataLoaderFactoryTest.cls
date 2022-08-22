@isTest
private class MetadataLoaderFactoryTest 
{	
	@isTest static void test_method_one() 
    {
		// Data Setup
        MetadataOpType mt = MetadataOpType.APEXWRAPPER;
        MetadataOpType mt1 = MetadataOpType.METADATAAPEX;

        // Run Code
        Test.startTest();

            MetadataLoaderFactory.getLoader(mt);
            MetadataLoaderFactory.getLoader(mt1);

        Test.stopTest();
	}
}