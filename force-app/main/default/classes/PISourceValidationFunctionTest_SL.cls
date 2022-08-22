@IsTest(IsParallel=false)
private with sharing class PISourceValidationFunctionTest_SL {
  @TestSetup
  static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    Partner_Involvement__c firstPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE,
      false
    );
    firstPartner.Opportunity_Sourced__c = true;
    Partner_Involvement__c secondPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.TIER_2_PARTNER_ROLE,
      false
    );

    insert new List<Partner_Involvement__c>{ firstPartner, secondPartner };
  }

  @isTest
  private static void preventDuplicateSourceOnInsert() {
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Partner_Involvement__c testPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.TIER_2_PARTNER_ROLE,
      false
    );
    testPartner.Opportunity_Sourced__c = true;
    try {
      insert testPartner;
    } catch (Exception e) {
      System.assert(e.getMessage().contains(PartnerInvolvementMetadata_SL.DUPLICATE_SOURCE_MESSAGE));
    }

    System.assertEquals(null, testPartner.Id, 'preventDuplicateSources on insert failed.');
  }

  @isTest
  private static void preventDuplicateSourceOnUpdate() {
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Partner_Involvement__c testPartner = [
      SELECT Id, Opportunity_Sourced__c
      FROM Partner_Involvement__c
      WHERE Opportunity_Sourced__c = FALSE
      LIMIT 1
    ];
    testPartner.Opportunity_Sourced__c = true;
    try {
      update testPartner;
      System.assert(false, 'preventDuplicateSources on update failed.');
    } catch (Exception e) {
      System.assert(e.getMessage().contains(PartnerInvolvementMetadata_SL.DUPLICATE_SOURCE_MESSAGE));
    }
  }
}