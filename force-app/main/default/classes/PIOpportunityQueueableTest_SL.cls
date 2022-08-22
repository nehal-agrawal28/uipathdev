@IsTest
public with sharing class PIOpportunityQueueableTest_SL {
  @TestSetup
  static void makeData() {
    DataFactory_SL.createQuoteApprovalMatrix('EMEA', UserInfo.getUserId(), 'Influence', 'Operations', 'EMEA', true);

    Account firstCustomer = DataFactory_CM.createAccount('Customer', false);
    firstCustomer.Geo__c = 'EMEA';
    Account partner = DataFactory_CM.createAccounts(AccountMetadata.partnerRecordType, 1, false).get(0);
    partner.Geo__c = 'EMEA';
    partner.Business_Partner_Type__c = 'GSI';
    partner.Regional_Business_Partner_Type__c = 'RSI';

    insert new List<Account>{ firstCustomer, partner };
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(firstCustomer.Id, true);
    Partner_Involvement__c influencer = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE,
      false
    );
    influencer.Partner_Account_Name__c = partner.Id;
    influencer.Partner_Account_Geo_Text__c = 'EMEA';
    influencer.X1st_Approver__c = UserInfo.getUserId();
    Partner_Involvement__c solToPartner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE,
      false
    );
    solToPartner.Partner_Account_Name__c = partner.Id;

    Partner_Involvement__c tier2Partner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.TIER_2_PARTNER_ROLE,
      false
    );
    tier2Partner.Partner_Account_Name__c = partner.Id;
    Partner_Involvement__c tier3Partner = DataFactory_SL.createPartnerInvolvement(
      testOpportunity.Id,
      PartnerInvolvementMetadata_SL.TIER_3_PARTNER_ROLE,
      false
    );
    tier3Partner.Partner_Account_Name__c = partner.Id;

    insert new List<Partner_Involvement__c>{ influencer, solToPartner, tier2Partner, tier3Partner };
  }

  @IsTest
  static void whenPartnersAreAdded_UpdateOpp() {
    List<Opportunity> opportunities = getOpportunities();

    Test.startTest();
    //new PIOpportunityQueueable_SL(opportunities).work();
    Test.stopTest();

    Opportunity opp = getOpportunities().get(0);
    List<Partner_Involvement__c> partners = opp.Opportunity_Partners__r;

    Map<String, List<Partner_Involvement__c>> partnersByRole = (Map<String, List<Partner_Involvement__c>>) Collection.of(
        partners
      )
      .groupByStrings(Partner_Involvement__c.Partner_Sales_Role__c);
    Partner_Involvement__c soldToPartner = partnersByRole.get(PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE)
      .get(0);
    Partner_Involvement__c influencer = partnersByRole.get(PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE).get(0);
    Partner_Involvement__c tier2Partner = partnersByRole.get(PartnerInvolvementMetadata_SL.TIER_2_PARTNER_ROLE).get(0);
    Partner_Involvement__c tier3Partner = partnersByRole.get(PartnerInvolvementMetadata_SL.TIER_3_PARTNER_ROLE).get(0);

    System.assertEquals(soldToPartner.Partner_Account_Name__c, opp.Sold_to_Partner__c, 'Sold To Not updated');
    System.assertEquals(
      influencer.Partner_Account_Name__c,
      opp.Primary_Influence_Partner__c,
      'Primary Influence Not updated'
    );
    System.assertEquals(tier2Partner.Partner_Account_Name__c, opp.Tier_2_Partner__c, 'Tier 2 Not updated');
    System.assertEquals(tier3Partner.Partner_Account_Name__c, opp.Tier_3_Partner__c, 'Tier 3 Not updated');
  }

  @IsTest
  static void whenImplementationAdded_UpdateOpp() {
    List<Opportunity> opportunities = getOpportunities();
    List<Partner_Involvement__c> partners = opportunities.get(0).Opportunity_Partners__r;
    Partner_Involvement__c deliveryPartner = partners.get(0);
    deliveryPartner.Partner_Delivery_Role__c = PartnerInvolvementMetadata_SL.PRIMARY_IMPLEMENTATION;
    update deliveryPartner;

    Test.startTest();
    //new PIOpportunityQueueable_SL(opportunities).work();
    Test.stopTest();

    Opportunity opp = getOpportunities().get(0);

    System.assertEquals(
      deliveryPartner.Partner_Account_Name__c,
      opp.Implementation_Partner__c,
      'Implementation Partner Not updated'
    );
  }

  @IsTest
  static void whenInfluencersAdded_UpdateOpp() {
    List<Opportunity> opportunities = getOpportunities();
    List<Partner_Involvement__c> partners = opportunities.get(0).Opportunity_Partners__r;
    partners.get(0).Influence_Approval_Status__c = PartnerInvolvementMetadata_SL.INFLUENCE_APPROVAL_STATUS;
    partners.get(0).Partner_Sales_Role__c = PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE;
    partners.get(1).Influence_Approval_Status__c = PartnerInvolvementMetadata_SL.INFLUENCE_APPROVAL_STATUS;
    partners.get(1).Partner_Sales_Role__c = PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE;

    update partners;

    Test.startTest();
    //new PIOpportunityQueueable_SL(opportunities).work();
    Test.stopTest();

    Opportunity opp = getOpportunities().get(0);

    System.assert(opp.Influencers__c.contains(partners.get(0).Partner_Account_Name__c), 'Influencers Not updated');
  }

  @IsTest
  static void whenIsSourcedChecked_UpdateOpp() {
    List<Opportunity> opportunities = getOpportunities();
    List<Partner_Involvement__c> partners = opportunities.get(0).Opportunity_Partners__r;
    partners.get(0).Opportunity_Sourced__c = true;

    update partners;

    Test.startTest();
    //new PIOpportunityQueueable_SL(opportunities).work();
    Test.stopTest();

    Opportunity opp = getOpportunities().get(0);

    System.assertEquals(true, opp.Is_Partner_Sourced__c, 'Partner Sourced Not updated');
  }

  private static List<Opportunity> getOpportunities() {
    return [
      SELECT
        Id,
        Sold_to_Partner__c,
        Tier_2_Partner__c,
        Tier_3_Partner__c,
        Implementation_Partner__c,
        Primary_Influence_Partner__c,
        Influencers__c,
        Influence__c,
        Is_Partner_Sourced__c,
        (
          SELECT
            Id,
            PartnerOpp_Name__c,
            Primary_Influence__c,
            Partner_Sales_Role__c,
            Partner_Delivery_Role__c,
            Partner_Account_Name__c,
            Influence_Approval_Status__c,
            Opportunity_Sourced__c
          FROM Opportunity_Partners__r
        )
      FROM Opportunity
    ];
  }
}