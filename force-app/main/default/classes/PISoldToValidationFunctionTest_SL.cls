@IsTest(IsParallel=false)
private with sharing class PISoldToValidationFunctionTest_SL {
  @TestSetup
  static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    Partner_Involvement__c firstPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE,
      false
    );
    Partner_Involvement__c secondPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.TIER_2_PARTNER_ROLE,
      false
    );

    insert new List<Partner_Involvement__c>{ firstPartner, secondPartner };
  }

  @isTest
  private static void preventDuplicateSoldToOnInsert() {
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Partner_Involvement__c testPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE,
      false
    );
    try {
      insert testPartner;
    } catch (Exception e) {
      System.assert(e.getMessage().contains(PartnerInvolvementMetadata_SL.DUPLICATE_SOLD_TO_MESSAGE));
    }

    System.assertEquals(null, testPartner.Id, 'preventDuplicateSoldTo on insert failed.');
  }

  @isTest
  private static void preventDuplicateSoldToOnUpdate() {
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Partner_Involvement__c testPartner = [
      SELECT Id, Partner_Sales_Role__c
      FROM Partner_Involvement__c
      WHERE Partner_Sales_Role__c != :PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE
      LIMIT 1
    ];
    try {
      testPartner.Partner_Sales_Role__c = PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE;
      update testPartner;
      System.assert(false, 'preventDuplicateSoldTo on update failed.');
    } catch (Exception e) {
      System.assert(e.getMessage().contains(PartnerInvolvementMetadata_SL.DUPLICATE_SOLD_TO_MESSAGE));
    }
  }
}