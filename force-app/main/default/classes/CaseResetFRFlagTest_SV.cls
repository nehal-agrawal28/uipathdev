@IsTest
public class CaseResetFRFlagTest_SV {
  @IsTest
  private static void testResetSalesOpsFRt() {
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id salesOpsRecordTypeID = CaseMetadata_SV.SalesOperationRecordType;

    Case cs = new Case(
      Id = caseId,
      Subject = 'Test',
      RecordTypeId = salesOpsRecordTypeID,
      Status = 'New',
      FR_Voilated__c = true
    );

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ cs });

    Case caseObjClone = cs.clone(false, false, false, false);
    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ caseObjClone });
    fflib_SObjectDomain.triggerHandler(Cases_SV.class);
    System.assertEquals(false, caseObjClone.FR_Voilated__c);
  }
}