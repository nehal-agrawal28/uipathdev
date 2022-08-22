@IsTest(IsParallel=false)
public with sharing class OppRenewalFunctionTest_SL {
  @TestSetup
  static void makeData() {
    Account account = DataFactory_CM.createAccount('Customer', true);
    Contact contact = DataFactory_CM.createContact(account.Id, true);

    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, false);
    opportunity.Included_in_Partner_Community__c = true;
    insert opportunity;

    Contract contract = DataFactory_SL.createContract(account.Id, false);
    contract.SBQQ__RenewalOpportunity__c = opportunity.Id;
    insert contract;
  }

  @IsTest
  static void onRenewal_deriveIncludedInCommunity() {
    Contract contract = [SELECT Id FROM Contract LIMIT 1];
    Opportunity record = new Opportunity();
    record.SBQQ__Renewal__c = true;
    record.SBQQ__RenewedContract__c = contract.Id;

    Test.startTest();
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ record });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);
    Test.stopTest();
  }
}