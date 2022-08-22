@IsTest(IsParallel=false)
private with sharing class PIPrimaryInfluenceFunctionTest_SL {
  @TestSetup
  static void makeData() {
    DataFactory_SL.createQuoteApprovalMatrix('EMEA', UserInfo.getUserId(), 'Influence', 'Operations', 'EMEA', true);

    Account firstCustomer = DataFactory_CM.createAccount('Customer', false);
    firstCustomer.Geo__c = 'EMEA';
    Account partner = DataFactory_CM.createAccounts(AccountMetadata.partnerRecordType, 1, false).get(0);
    partner.Geo__c = 'EMEA';
    //partner.Business_Partner_Type__c = 'GSI';
    partner.Regional_Business_Partner_Type__c = 'RSI';
    insert new List<Account>{ firstCustomer, partner };

    System.runAs(new User(Id = Userinfo.getUserId())) {
      Territory2Model objTerrModel = [SELECT Id, DeveloperName FROM Territory2Model LIMIT 1];
      Territory2Type objTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE DeveloperName = 'Velocity'
        LIMIT 1
      ];

      Territory2 EMEATerritory = new Territory2();
      EMEATerritory.AccountAccessLevel = 'Edit';
      EMEATerritory.CaseAccessLevel = 'Read';
      EMEATerritory.Name = 'EMEA Territory';
      EMEATerritory.DeveloperName = 'EMEA_Territory';
      EMEATerritory.Territory2ModelId = objTerrModel.Id;
      EMEATerritory.Ultimate_Geo__c = 'EMEA';
      EMEATerritory.Sales_Territory__c = true;
      EMEATerritory.Area__c = 'EMEA Area';
      EMEATerritory.Region__c = 'EMEA Region';
      EMEATerritory.Territory2TypeId = objTerrType.Id;
      insert EMEATerritory;

      UserTerritory2Association objUserTerrAssEMEA = new UserTerritory2Association();
      objUserTerrAssEMEA.RoleInTerritory2 = 'Primary Account Manager';
      objUserTerrAssEMEA.UserId = UserInfo.getUserId();
      objUserTerrAssEMEA.Territory2Id = EMEATerritory.Id;
      insert objUserTerrAssEMEA;

      insert new ObjectTerritory2Association(
        ObjectId = firstCustomer.Id,
        Territory2Id = EMEATerritory.Id,
        AssociationCause = 'Territory2Manual'
      );
    }
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(firstCustomer.Id, true);
    Partner_Involvement__c firstPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
      false
    );
    firstPartner.Partner_Account_Name__c = partner.Id;
    firstPartner.X1st_Approver__c = UserInfo.getUserId();
    Partner_Involvement__c secondPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE,
      false
    );
    secondPartner.Partner_Account_Name__c = partner.Id;
    insert new List<Partner_Involvement__c>{ firstPartner, secondPartner };
  }

  @isTest
  private static void preventDuplicatePrimaryOnInsert() {
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Partner_Involvement__c testPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
      false
    );
    testPartner.Primary_Influence__c = true;
    testPartner.Partner_Account_Name__c = [
      SELECT Id
      FROM Account
      WHERE RecordTypeId = :AccountMetadata.partnerRecordType
    ]
    .Id;
    testPartner.X1st_Approver__c = UserInfo.getUserId();
    try {
      insert testPartner;
    } catch (Exception e) {
      System.assert(e.getMessage().contains(PartnerInvolvementMetadata_SL.DUPLICATE_PRIMARY_INFLUENCE));
    }

    System.assertEquals(null, testPartner.Id, 'preventDuplicatePrimary on insert failed.');
  }

  @isTest
  private static void preventDuplicatePrimaryOnUpdate() {
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Partner_Involvement__c testPartner = [
      SELECT Id, Primary_Influence__c, Partner_Sales_Role__c, Opportunity_Sourced__c
      FROM Partner_Involvement__c
      WHERE Primary_Influence__c = FALSE
      LIMIT 1
    ];
    testPartner.Partner_Sales_Role__c = PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE;
    testPartner.X1st_Approver__c = UserInfo.getUserId();
    try {
      update testPartner;
      System.assertNotEquals(true, testPartner.Primary_Influence__c, 'Failed to detect duplicate on update');
    } catch (Exception e) {
      System.debug(e);
      System.assert(e.getMessage().contains(PartnerInvolvementMetadata_SL.DUPLICATE_PRIMARY_INFLUENCE));
    }
  }

  @isTest
  private static void setPrimaryOnInsert() {
    delete [SELECT Id FROM Partner_Involvement__c];
    Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    Partner_Involvement__c testPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
      false
    );

    fflib_SObjectDomain.Test.Database.onInsert(new List<Partner_Involvement__c>{ testPartner });
    fflib_SObjectDomain.triggerHandler(PartnerInvolvements_SL.class);
    System.assertEquals(true, testPartner.Primary_Influence__c, 'Primary Influence failed to be set on insert');
  }
}