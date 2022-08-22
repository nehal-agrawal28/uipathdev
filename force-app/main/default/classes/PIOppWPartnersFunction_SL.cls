public without sharing class PIOppWPartnersFunction_SL implements SObjectToSObjectFunction {
  public PIOppWPartnersFunction_SL(List<Opportunity> records) {
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  private SObject apply(Opportunity record) {
    List<Partner_Involvement__c> childRecords = record.Opportunity_Partners__r;

    if (childRecords.isEmpty()) {
      return record;
    }

    Map<String, List<Partner_Involvement__c>> partnersBySalesRole = getPartnersBySalesRole(childRecords);
    Map<String, List<Partner_Involvement__c>> partnersByDeliveryRole = getPartnersByDeliveryRole(childRecords);
    Map<Boolean, List<Partner_Involvement__c>> partnersByIsSourced = getPartnersByIsSourced(childRecords);

    this.deriveSoldToPartner(record, partnersBySalesRole);
    this.deriveTier2Partner(record, partnersBySalesRole);
    this.deriveTier3Partner(record, partnersBySalesRole);
    this.deriveImplementationPartner(record, partnersByDeliveryRole);
    this.deriveInfluencers(record, partnersBySalesRole);
    this.deriveIsPartnerSourced(record, partnersByIsSourced);

    return record;
  }

  @TestVisible
  private Map<String, List<Partner_Involvement__c>> getPartnersBySalesRole(List<Partner_Involvement__c> childRecords) {
    return (Map<String, List<Partner_Involvement__c>>) Collection.of(childRecords)
      .groupByStrings(Partner_Involvement__c.Partner_Sales_Role__c);
  }

  @TestVisible
  private Map<String, List<Partner_Involvement__c>> getPartnersByDeliveryRole(
    List<Partner_Involvement__c> childRecords
  ) {
    return (Map<String, List<Partner_Involvement__c>>) Collection.of(childRecords)
      .groupByStrings(Partner_Involvement__c.Partner_Delivery_Role__c);
  }

  @TestVisible
  private Map<Boolean, List<Partner_Involvement__c>> getPartnersByIsSourced(List<Partner_Involvement__c> childRecords) {
    return (Map<Boolean, List<Partner_Involvement__c>>) Collection.of(childRecords)
      .groupByBooleans(Partner_Involvement__c.Opportunity_Sourced__c);
  }

  private void deriveSoldToPartner(Opportunity record, Map<String, List<Partner_Involvement__c>> partnersBySalesRole) {
    record.Sold_to_Partner__c = null;
    if (partnersBySalesRole.containsKey(PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE)) {
      record.Sold_to_Partner__c = partnersBySalesRole.get(PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE)
        .get(0)
        .Partner_Account_Name__c;
    }
  }

  private void deriveTier2Partner(Opportunity record, Map<String, List<Partner_Involvement__c>> partnersBySalesRole) {
    record.Tier_2_Partner__c = null;
    if (partnersBySalesRole.containsKey(PartnerInvolvementMetadata_SL.TIER_2_PARTNER_ROLE)) {
      record.Tier_2_Partner__c = partnersBySalesRole.get(PartnerInvolvementMetadata_SL.TIER_2_PARTNER_ROLE)
        .get(0)
        .Partner_Account_Name__c;
    }
  }

  private void deriveTier3Partner(Opportunity record, Map<String, List<Partner_Involvement__c>> partnersBySalesRole) {
    record.Tier_3_Partner__c = null;
    if (partnersBySalesRole.containsKey(PartnerInvolvementMetadata_SL.TIER_3_PARTNER_ROLE)) {
      record.Tier_3_Partner__c = partnersBySalesRole.get(PartnerInvolvementMetadata_SL.TIER_3_PARTNER_ROLE)
        .get(0)
        .Partner_Account_Name__c;
    }
  }

  private void deriveImplementationPartner(
    Opportunity record,
    Map<String, List<Partner_Involvement__c>> partnersByDeliveryRole
  ) {
    record.Implementation_Partner__c = null;
    if (partnersByDeliveryRole.containsKey(PartnerInvolvementMetadata_SL.PRIMARY_IMPLEMENTATION)) {
      record.Implementation_Partner__c = partnersByDeliveryRole.get(
          PartnerInvolvementMetadata_SL.PRIMARY_IMPLEMENTATION
        )
        .get(0)
        .Partner_Account_Name__c;
    }
  }

  private void deriveInfluencers(Opportunity record, Map<String, List<Partner_Involvement__c>> partnersBySalesRole) {
    record.Influencers__c = null;
    if (partnersBySalesRole.containsKey(PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE)) {
      List<Partner_Involvement__c> influencers = partnersBySalesRole.get(
        PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE
      );
      Map<Boolean, List<Partner_Involvement__c>> primary = (Map<Boolean, List<Partner_Involvement__c>>) Collection.of(
          influencers
        )
        .groupByBooleans(Partner_Involvement__c.Primary_Influence__c);
      record.Primary_Influence_Partner__c = (primary.get(true) != null)
        ? primary.get(true).get(0).Partner_Account_Name__c
        : null;

      Map<String, List<Partner_Involvement__c>> approved = (Map<String, List<Partner_Involvement__c>>) Collection.of(
          influencers
        )
        .groupByStrings(Partner_Involvement__c.Influence_Approval_Status__c);

      if (approved.containsKey(PartnerInvolvementMetadata_SL.INFLUENCE_APPROVAL_STATUS)) {
        List<Partner_Involvement__c> approvedInfluencers = approved.get(
          PartnerInvolvementMetadata_SL.INFLUENCE_APPROVAL_STATUS
        );
        List<Id> approverIds = Collection.of(approvedInfluencers)
          .pluckIds(Partner_Involvement__c.Partner_Account_Name__c);
        record.Influencers__c = getIdsAsString(approverIds);
      }
    }
  }

  private void deriveIsPartnerSourced(Opportunity record, Map<Boolean, List<Partner_Involvement__c>> partnersbySource) {
    record.Is_Partner_Sourced__c = partnersbySource.containsKey(true);
  }

  private static String getIdsAsString(List<Id> ids) {
    if (ids == null || ids.isEmpty()) {
      return '';
    }
    ids.sort();
    Set<Id> uniqueIds = new Set<Id>(ids);
    return String.join(new List<Id>(uniqueIds), ';');
  }
}