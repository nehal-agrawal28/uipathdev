@isTest
public with sharing class OppContactRoleFunctionTest_SL {
  @isTest
  private static void setTotalContactRoleTest() {
    Id customerRT = AccountMetadata.getAccountRecordTypeId('Customer');
    Account testAccount = DataFactory_CM.createAccount(customerRT, true);
    Contact testContact = DataFactory_CM.createContact(testAccount.id, true);

    Opportunity oldOpp = DataFactory_SL.createOpportunity(testAccount.id, true);

    OpportunityContactRole opprole = DataFactory_SL.createOpportunityContactRole(
      oldOpp.id,
      testContact.Id,
      'Business User',
      true
    );

    Opportunity updatedOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    updatedOpp.Id = oldOpp.id;
    updatedOpp.Deal_Type__c = 'Managed Services';
    updatedOpp.Custom_Billing_Segments__c = true;

    Test.startTest();
    update updatedOpp;
    Test.stopTest();

    System.assertEquals(1, [SELECT id, Total_Contact_Roles__c FROM Opportunity LIMIT 1].Total_Contact_Roles__c);
  }
}