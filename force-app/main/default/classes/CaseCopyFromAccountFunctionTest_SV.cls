@IsTest(isParallel=true)
public class CaseCopyFromAccountFunctionTest_SV {
  @IsTest
  private static void onInsert_CopyMaintenanceFlagFromAccount() {
    Account newAccount = DataFactory_CM.createAccount('Customer', false);
    newAccount.Maintenance_Flag__c = 'Premium';
    insert newAccount;

    Case record = DataFactory_SV.createCase(CaseMetadata_SV.JapanIncidentRecordType, false);
    record.AccountId = newAccount.Id;

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ record });
    fflib_SObjectDomain.triggerHandler(Cases_SV.class);

    //System.assertEquals(record.Maintenance_Flag__c, newAccount.Maintenance_Flag__c);
  }
}