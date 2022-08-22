@IsTest
public with sharing class OppPartnerInvolvementTest_SL {
  @TestSetup
  static void makeData() {
    Account newAccount = DataFactory_CM.createAccount('Customer', true);
    Contact cnt = DataFactory_CM.createContact(newAccount.Id, true);
    Opportunity newOpportunity = DataFactory_SL.createOpportunity(newAccount.Id, true);
    Partner_Involvement__c newPartner1 = DataFactory_SL.createPartnerInvolvement(
      newOpportunity.Id,
      'Sold to Partner (Buying Directly from UiPath)',
      true
    );
    Partner_Involvement__c newPartner2 = DataFactory_SL.createPartnerInvolvement(
      newOpportunity.Id,
      'Tier 2 Partner (Buying from Sold to Partner)',
      true,
      'None'
    );

    Contract newContract = DataFactory_SL.createContract(newAccount.Id, false);
    newContract.StartDate = Date.Today();
    newContract.Status = 'Draft';
    newContract.ContractTerm = 4;
    newContract.SBQQ__Opportunity__c = newOpportunity.Id;
    insert newContract;
  }

  @isTest
  private static void testClonePartnerInvolvment1() {
    Account newAccount = [SELECT Id FROM Account LIMIT 1];
    Contact cnt = [SELECT Id FROM Contact LIMIT 1];
    Opportunity newOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Contract newContract = [SELECT Id FROM Contract LIMIT 1];

    Opportunity newOpportunity1 = DataFactory_SL.createOpportunity(newAccount.Id, false);
    newOpportunity1.RecordTypeId = OpportunityMetadata_SL.CPQDefaultRecordType;
    newOpportunity1.Customer_Primary_Contact__c = cnt.Id;
    newOpportunity1.SBQQ__AmendedContract__c = newContract.Id;

    Test.startTest();
    insert newOpportunity1;
    new OppPartnerInvolvementQueueable_SL(new List<SObject>{ newOpportunity1 }).work();
    Test.stopTest();

    List<Partner_Involvement__c> clonedPartnerInvolvements = [
      SELECT Id
      FROM Partner_Involvement__c
      WHERE PartnerOpp_Name__c = :newOpportunity1.Id
    ];
    System.assertEquals(true, clonedPartnerInvolvements.size() > 1);
  }
}