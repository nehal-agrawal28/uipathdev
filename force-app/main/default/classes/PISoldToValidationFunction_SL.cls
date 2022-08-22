public without sharing class PISoldToValidationFunction_SL implements SObjectToSObjectFunction {
  private List<Id> soldOpportunityIds = new List<Id>();

  public PISoldToValidationFunction_SL(List<Partner_Involvement__c> records) {
    List<Id> relatedOpportunityIds = Collection.of(records).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c);
    List<Partner_Involvement__c> soldToPartners = [
      SELECT Id, PartnerOpp_Name__c
      FROM Partner_Involvement__c
      WHERE
        PartnerOpp_Name__c IN :relatedOpportunityIds
        AND Id NOT IN :records
        AND Partner_Sales_Role__c = :PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE
    ];
    this.soldOpportunityIds = Collection.of(soldToPartners).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c);
  }

  public SObject apply(Partner_Involvement__c record) {
    if (this.soldOpportunityIds != null && this.soldOpportunityIds.contains(record.PartnerOpp_Name__c)) {
      record.addError(PartnerInvolvementMetadata_SL.DUPLICATE_SOLD_TO_MESSAGE);
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Partner_Involvement__c) record);
  }

  public static void preventDuplicateSoldTo(List<Partner_Involvement__c> records) {
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Partner_Involvement__c.Partner_Sales_Role__c)
          .equals(PartnerInvolvementMetadata_SL.SOLD_TO_PARTNER_ROLE)
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new PISoldToValidationFunction_SL(eligibleRecords));
    }
  }

  public static void preventDuplicateSoldTo(List<Partner_Involvement__c> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Partner_Involvement__c.Partner_Sales_Role__c },
      records,
      existingRecords
    );
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      preventDuplicateSoldTo(eligibleRecords);
    }
  }
}