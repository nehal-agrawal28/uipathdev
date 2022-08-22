@IsTest
private class DealRegistrationsServiceTest_PP {
  @TestSetup
  static void setup() {
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();
  }

  @IsTest
  static void itShouldCreateOpportunitiesFromDealRegistrations() {
    // given
    User resellerUser = [SELECT Id, Contact_Account_Id__c FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];
    final String campaignName = 'My Campaign Name';
    final Campaign campaign = new Campaign(
      Name = campaignName,
      Campaign_Name_Text__c = campaignName,
      Campaign_City__c = 'Naboo',
      Campaign_Country__c = 'Global'
    );
    insert campaign;

    DealRegistration__c dealRegistration = TestFactory_PP.buildDealRegistration(
      resellerUser,
      distributorAccount.Id,
      resellerUser.Contact_Account_Id__c,
      null,
      false, // bpo = false
      true // submitted record type
    );
    dealRegistration.CampaignId__c = campaignName;
    insert dealRegistration;

    List<Opportunity> opportunitiesBefore = [SELECT Id FROM Opportunity];

    System.assertEquals(true, opportunitiesBefore.isEmpty());

    DealRegistrationsSelector_PP selector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );

    List<DealRegistration__c> dealRegistrationsBefore = selector.selectById(new Set<Id>{ dealRegistration.Id }, false);

    System.assertEquals(false, dealRegistrationsBefore.isEmpty());

    DealRegistrationsService_PP service = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
      DealRegistrationsService_PP.class
    );

    // when
    Test.startTest();
    service.createOpportunitiesFromDealRegistrations(dealRegistrationsBefore);
    Test.stopTest();

    // then
    List<Opportunity> opportunitiesAfter = [SELECT Id, CampaignId FROM Opportunity];

    System.assertEquals(false, opportunitiesAfter.isEmpty());

    List<DealRegistration__c> dealRegistrationsAfter = selector.selectById(new Set<Id>{ dealRegistration.Id }, false);

    System.assertEquals(false, dealRegistrationsAfter.isEmpty());
    System.assert(String.isNotBlank(dealRegistrationsAfter.get(0).Opportunity__c));
    System.assertEquals(
      campaign.Id,
      opportunitiesAfter.get(0).CampaignId,
      'CampaignId was not copied from Deal Registration record'
    );
  }
}