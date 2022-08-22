@IsTest
public with sharing class OppEconomicBuyerQueueableTest_SL {
  @TestSetup
  static void makeData() {
    Account acc = DataFactory_CM.createAccount('Customer', true);
    Contact con = DataFactory_CM.createContact(acc.Id, true);
  }

  @IsTest
  static void whenOppHasEcoBuyerThenCreateContactRole() {
    List<OpportunityContactRole> contactRoles = getContactRoles(OpportunityMetadata_SL.ECONOMIC_BUYER);
    Id accountId = [SELECT Id FROM Account].Id;
    Id contactId = [SELECT Id FROM Contact].Id;
    System.assertEquals(true, contactRoles.isEmpty(), 'Contact Roles should be empty');
    Opportunity opp = DataFactory_SL.createOpportunity(accountId, false);
    opp.Economic_Buyer__c = contactId;
    insert opp;
    contactRoles = getContactRoles(OpportunityMetadata_SL.ECONOMIC_BUYER);
    // System.assertEquals(true, contactRoles.isEmpty(), 'Contact Roles should be empty');
    // Test.startTest();
    // new OppEconomicBuyerQueueable_SL(new List<Opportunity>{ opp }).work();
    // Test.stopTest();
    contactRoles = getContactRoles(OpportunityMetadata_SL.ECONOMIC_BUYER);
    System.assertEquals(1, contactRoles.size(), 'Economic Contact Role is not created');
  }

  @IsTest
  static void whenOppHasChampionThenCreateContactRole() {
    List<OpportunityContactRole> contactRoles = getContactRoles(OpportunityMetadata_SL.CHAMPION);
    Id accountId = [SELECT Id FROM Account].Id;
    Id contactId = [SELECT Id FROM Contact].Id;
    System.assertEquals(true, contactRoles.isEmpty(), 'Contact Roles should be empty');
    Opportunity opp = DataFactory_SL.createOpportunity(accountId, false);
    opp.Champion_Actual__c = contactId;
    insert opp;
    contactRoles = getContactRoles(OpportunityMetadata_SL.CHAMPION);
    // System.assertEquals(true, contactRoles.isEmpty(), 'Contact Roles should be empty');
    // Test.startTest();
    // new OppChampionQueueable_SL(new List<Opportunity>{ opp }).work();
    // Test.stopTest();
    contactRoles = getContactRoles(OpportunityMetadata_SL.CHAMPION);
    System.assertEquals(1, contactRoles.size(), 'Champion Contact Roles is not created');
  }

  private static List<OpportunityContactRole> getContactRoles(String role) {
    return [SELECT Id FROM OpportunityContactRole WHERE Role = :role];
  }
}