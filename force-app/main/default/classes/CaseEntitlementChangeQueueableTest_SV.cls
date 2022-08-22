@isTest
public class CaseEntitlementChangeQueueableTest_SV {
  @TestSetup
  static void makeData() {
    Account account = new Account(Name = 'John');
    account.BillingStreet = 'Test Street';
    account.BillingCity = 'Test City';
    account.BillingPostalCode = 'SW1 3DWW';
    account.BillingCountry = 'United Kingdom';
    account.Phone = '1234567890';
    account.Industry = 'Others';
    insert account;
    Entitlement entitlement0 = new Entitlement();
    entitlement0.AccountId = account.Id;
    entitlement0.Name = 'Standard Account';
    Entitlement entitlement1 = new Entitlement();
    entitlement1.AccountId = account.Id;
    entitlement1.Name = Label.SalesOperationEntitlementName;
    List<Entitlement> entitlementsToBeInserted = new List<Entitlement>{ entitlement0, entitlement1 };
    insert entitlementsToBeInserted;
  }
  static testMethod void entitlementChange_onUpdateCase() {
    Case salesOps = new Case();
    salesOps.RecordTypeId = CaseMetadata_SV.SalesOperationRecordType;
    salesOps.Subject = 'SalesOps Case';
    salesOps.Status = 'New';
    salesOps.Subscription_Code__c = 'TRIAL';
    salesOps.SuppliedEmail = 'test@test.com';
    insert salesOps;
    List<Entitlement> entitlements = [SELECT Id FROM Entitlement WHERE Name = :Label.SalesOperationEntitlementName];
    Map<Id, Case> existingCases = new Map<Id, Case>([SELECT Id, Comm_Update__c, EntitlementId FROM Case LIMIT 1]);
    salesOps.RecordTypeId = CaseMetadata_SV.IncidentRecordType;
    salesOps.EntitlementId = entitlements[0].Id;
    update salesOps;
    Test.startTest();
    new CaseEntitlementChangeQueueable_SV(new List<Case>{ salesOps }).work(); // .setTargetDate(new List<Case>{ salesOps }, existingCases);
    Test.stopTest();
  }
}