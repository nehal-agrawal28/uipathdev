@isTest
private class JsonUtilitiesTest 
{	
	@isTest static void test_method_one() 
    {
		// Run Code
        Test.startTest();

            JsonUtilities.getValuesFromJson('{ "name": {"name" : "test"} }');

        Test.stopTest();
	}
}