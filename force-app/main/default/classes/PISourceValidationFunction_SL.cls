public without sharing class PISourceValidationFunction_SL implements SObjectToSObjectFunction {
  private List<Id> sourcedOpportunityIds = new List<Id>();

  public PISourceValidationFunction_SL(List<Partner_Involvement__c> records) {
    List<Id> relatedOpportunityIds = Collection.of(records).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c);
    List<Partner_Involvement__c> sourcedRecords = [
      SELECT Id, PartnerOpp_Name__c
      FROM Partner_Involvement__c
      WHERE PartnerOpp_Name__c IN :relatedOpportunityIds AND Id NOT IN :records AND Opportunity_Sourced__c = TRUE
    ];
    this.sourcedOpportunityIds = Collection.of(sourcedRecords).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c);
  }

  public SObject apply(Partner_Involvement__c record) {
    if (this.sourcedOpportunityIds != null && this.sourcedOpportunityIds.contains(record.PartnerOpp_Name__c)) {
      record.addError(PartnerInvolvementMetadata_SL.DUPLICATE_SOURCE_MESSAGE);
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Partner_Involvement__c) record);
  }

  public static void preventDuplicateSources(List<Partner_Involvement__c> records) {
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Partner_Involvement__c.Opportunity_Sourced__c)
          .hasValue()
          .also(Partner_Involvement__c.Opportunity_Sourced__c)
          .equals(true)
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new PISourceValidationFunction_SL(eligibleRecords));
    }
  }

  public static void preventDuplicateSources(List<Partner_Involvement__c> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Partner_Involvement__c.Opportunity_Sourced__c },
      records,
      existingRecords
    );
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      preventDuplicateSources(eligibleRecords);
    }
  }
}