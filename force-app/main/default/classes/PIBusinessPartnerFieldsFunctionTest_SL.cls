@IsTest(IsParallel=false)
private without sharing class PIBusinessPartnerFieldsFunctionTest_SL {
  @TestSetup
  static void makeData() {
    Account firstCustomer = DataFactory_CM.createAccount('Customer', false);
    Account partner = DataFactory_CM.createAccounts(AccountMetadata.partnerRecordType, 1, false).get(0);
    partner.Business_Partner_Level__c = 'Registered';
    partner.Business_Partner_Type__c = 'GSI';
    partner.Business_Partner_Status__c = 'Good Standing';
    insert new List<Account>{ firstCustomer, partner };

    DataFactory_SL.createOpportunity(firstCustomer.Id, true);
  }

  @isTest
  private static void testPartnerFieldFunctionOnInsert() {
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Account testPartner = [
      SELECT Id, Business_Partner_Status__c, Business_Partner_Level__c, Business_Partner_Type__c
      FROM Account
      WHERE RecordTypeId = :AccountMetadata.partnerRecordType
      LIMIT 1
    ];

    Partner_Involvement__c secondPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
      false
    );
    secondPartner.Partner_Account_Name__c = testPartner.Id;

    fflib_SObjectDomain.Test.Database.onInsert(new List<Partner_Involvement__c>{ secondPartner });
    fflib_SObjectDomain.triggerHandler(PartnerInvolvements_SL.class);

    System.assertEquals(
      secondPartner.Business_Partner_Status__c,
      testPartner.Business_Partner_Status__c,
      'Business Partner Status is set incorrectly!'
    );
    System.assertEquals(
      secondPartner.Business_Partner_Level__c,
      testPartner.Business_Partner_Level__c,
      'Business Partner Level is set incorrectly!'
    );
    System.assertEquals(
      secondPartner.Business_Partner_Type__c,
      testPartner.Business_Partner_Type__c,
      'Business Partner Type is set incorrectly!'
    );
  }

  @isTest
  private static void testPartnerFieldFunctionOnUpdate() {
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Account testPartner = [
      SELECT Id, Business_Partner_Status__c, Business_Partner_Level__c, Business_Partner_Type__c
      FROM Account
      WHERE RecordTypeId = :AccountMetadata.partnerRecordType
      LIMIT 1
    ];
    Partner_Involvement__c firstPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE,
      false
    );

    Partner_Involvement__c firstPartnerUpdated = firstPartner.clone();
    firstPartnerUpdated.Partner_Account_Name__c = testPartner.Id;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Partner_Involvement__c>{ firstPartnerUpdated },
      new Map<Id, SObject>{ firstPartner.Id => firstPartner }
    );
    fflib_SObjectDomain.triggerHandler(PartnerInvolvements_SL.class);

    System.assertEquals(
      firstPartnerUpdated.Business_Partner_Status__c,
      testPartner.Business_Partner_Status__c,
      'Business Partner Status is set incorrectly!'
    );
    System.assertEquals(
      firstPartnerUpdated.Business_Partner_Level__c,
      testPartner.Business_Partner_Level__c,
      'Business Partner Level is set incorrectly!'
    );
    System.assertEquals(
      firstPartnerUpdated.Business_Partner_Type__c,
      testPartner.Business_Partner_Type__c,
      'Business Partner Type is set incorrectly!'
    );
  }
}