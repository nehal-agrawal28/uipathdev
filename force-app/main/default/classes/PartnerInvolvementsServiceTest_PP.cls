@IsTest
private class PartnerInvolvementsServiceTest_PP {
  @TestSetup
  static void setup() {
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();
  }

  @IsTest
  static void itShouldCreatePartnerInvolvementsAsResellerUser() {
    // given
    User resellerUser = [
      SELECT Id, Contact_Account_Id__c, ContactAccountBusinessPartnerType__c
      FROM User
      WHERE Name LIKE 'reselleruser%'
      LIMIT 1
    ];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    DealRegistration__c dealRegistration = TestFactory_PP.buildDealRegistration(
      resellerUser,
      distributorAccount.Id,
      resellerUser.Contact_Account_Id__c,
      null,
      false, // bpo = false
      true
    );
    insert dealRegistration;

    Opportunity opportunity = TestFactory_PP.buildDealRegistrationOpportunity(
      dealRegistration,
      resellerUser.Contact_Account_Id__c
    );
    insert opportunity;

    dealRegistration.Opportunity__c = opportunity.Id;
    update dealRegistration;

    Map<Id, Opportunity> opportunityByDealRegistration = new Map<Id, Opportunity>{ dealRegistration.Id => opportunity };
    Map<Id, DealRegistration__c> dealRegistrationById = new Map<Id, DealRegistration__c>{
      dealRegistration.Id => dealRegistration
    };

    PartnerInvolvementsService_PP partnerInvolvementsService = (PartnerInvolvementsService_PP) Application_PP.Service.newInstance(
      PartnerInvolvementsService_PP.class
    );

    List<Partner_Involvement__c> recordsBefore = [SELECT Id FROM Partner_Involvement__c];
    System.assertEquals(true, recordsBefore.isEmpty());

    Map<Id, User> ownerById = new Map<Id, User>(new List<User>{ resellerUser });

    // when
    Test.startTest();

    partnerInvolvementsService.createPartnerInvolvements(
      opportunityByDealRegistration,
      dealRegistrationById,
      ownerById
    );

    // then
    List<Partner_Involvement__c> recordsAfter = [
      SELECT
        Id,
        PartnerOpp_Name__c,
        Partner_Account_Name__c,
        Partner_Sales_Contribution__c,
        Partner_Sales_Role__c,
        Opportunity_Sourced__c,
        Partner_Technical_Contribution__c
      FROM Partner_Involvement__c
    ];

    Test.stopTest();

    System.assertEquals(2, recordsAfter.size());

    System.assertEquals(opportunity.Id, recordsAfter.get(0).PartnerOpp_Name__c);
    System.assertEquals(distributorAccount.Id, recordsAfter.get(0).Partner_Account_Name__c);
    System.assertEquals(
      System.Label.PartnerInvolvementSalesRoleSoldToPartner,
      recordsAfter.get(0).Partner_Sales_Role__c
    );
    System.assertEquals('None', recordsAfter.get(0).Partner_Sales_Contribution__c);
    System.assertEquals(false, recordsAfter.get(0).Opportunity_Sourced__c);
    System.assertEquals(
      System.Label.PartnerInvolvementDeliveryRoleNone,
      recordsAfter.get(0).Partner_Technical_Contribution__c
    );

    System.assertEquals(opportunity.Id, recordsAfter.get(1).PartnerOpp_Name__c);
    System.assertEquals(resellerUser.Contact_Account_Id__c, recordsAfter.get(1).Partner_Account_Name__c);
    System.assertEquals(
      System.Label.PartnerInvolvementSalesRoleTier2Partner,
      recordsAfter.get(1).Partner_Sales_Role__c
    );
    System.assertEquals('Led', recordsAfter.get(1).Partner_Sales_Contribution__c);
    System.assertEquals(true, recordsAfter.get(1).Opportunity_Sourced__c);
    System.assertEquals(
      System.Label.PartnerInvolvementDeliveryRoleNone,
      recordsAfter.get(1).Partner_Technical_Contribution__c
    );
  }
}