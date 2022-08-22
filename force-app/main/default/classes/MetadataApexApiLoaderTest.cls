@isTest
private class MetadataApexApiLoaderTest 
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

        Metadata.DeployResult dr = new Metadata.DeployResult();
        dr.status = Metadata.DeployStatus.Succeeded;

        Metadata.DeployResult dr1 = new Metadata.DeployResult();
        dr1.status = Metadata.DeployStatus.InProgress;

        Metadata.DeployResult dr2 = new Metadata.DeployResult();

        system.debug(dr.status);

		// Run Code
        Test.startTest();

            MetadataApexApiLoader ctrl = new MetadataApexApiLoader();

            ctrl.getMdDeployStatus();
            ctrl.getCallback();
            ctrl.migrateAsIsWithObjCreation('DeveloperName', 'VAT_Settings__mdt');
            ctrl.migrateAsIsMapping('DeveloperName', 'VAT_Settings__mdt');
            ctrl.migrateSimpleMapping('DeveloperName', 'VAT_Settings__mdt');
            ctrl.migrateCustomMapping('DeveloperName', 'VAT_Settings__mdt', 'test');

            ctrl.response.isSuccess = true;
            ctrl.buildResponse();
            ctrl.migrate(mmi);

            MetadataApexApiLoader.MetadataDeployStatus mds = new MetadataApexApiLoader.MetadataDeployStatus();
            mds.getJobId();
            mds.setJobId('01r18000000D7e1');
            mds.getDeployStatus();
            mds.getSuccess();
            mds.setSuccess(true);

            MetadataApexApiLoader.MetadataDeployCallback mdc = new MetadataApexApiLoader.MetadataDeployCallback();
            mdc.setMdDeployStatus(mds);
            mdc.handleResult(dr, null);
            mdc.handleResult(dr1, null);
            mdc.handleResult(dr2, null);

        Test.stopTest();
	}
}