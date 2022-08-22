@IsTest
public with sharing class ReferralUpdateBatchTest {
  @IsTest
  static void testReferralUpdateBatch() {
    Account account = DataFactory_CM.createAccount('Customer', true);
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, true);

    workspan__Partner__c partner = new workspan__Partner__c();
    partner.Name = 'Amazon';
    partner.workspan__WorkSpanId__c = 'Amazon';
    insert partner;

    workspan__Referral__c referral = new workspan__Referral__c();
    referral.Name = 'Test referral';
    referral.workspan__CRMAccount__c = account.Id;
    referral.workspan__Opportunity__c = opportunity.Id;
    referral.workspan__ReferralType__c = 'Incoming';
    referral.workspan__Industry__c = 'Other';
    referral.workspan__PartnerWsIds__c = 'Amazon';
    insert referral;
    Test.startTest();
    Database.executeBatch(new ReferralUpdateBatch());
    new ReferralUpdateBatch().execute(null);
    Test.stopTest();

    referral = [SELECT Id, workspan__SalesStage__c, workspan__CloseDate__c FROM workspan__Referral__c];
    System.assertEquals(opportunity.StageName, referral.workspan__SalesStage__c, 'Stage not updated');
  }
}