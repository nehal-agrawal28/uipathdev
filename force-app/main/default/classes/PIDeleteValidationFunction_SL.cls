public without sharing class PIDeleteValidationFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, Opportunity> lockedOpportunities;
  public PIDeleteValidationFunction_SL(List<Partner_Involvement__c> records) {
    List<Id> relatedOpportunityIds = Collection.of(records).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c);

    this.lockedOpportunities = new Map<Id, Opportunity>(
      [
        SELECT Id, RecordTypeId
        FROM Opportunity
        WHERE
          Id IN :relatedOpportunityIds
          AND RecordTypeId IN (
            :OpportunityMetadata_SL.UipathStandardLockedRecordType,
            :OpportunityMetadata_SL.CPQLockedRecordType
          )
      ]
    );
  }

  public SObject apply(Partner_Involvement__c record) {
    if (lockedOpportunities.containsKey(record.PartnerOpp_Name__c)) {
      record.addError(PartnerInvolvementMetadata_SL.CANNOT_DELETE_MESSAGE);
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Partner_Involvement__c) record);
  }

  public static void preventDeletion(List<Partner_Involvement__c> records) {
    if (PartnerInvolvementMetadata_SL.ProfilesAllowedToDelete.contains(UserInfo.getProfileId())) {
      return;
    }
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records)
      .filter(Match.field(Partner_Involvement__c.PartnerOpp_Name__c).hasValue())
      .asList();

    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new PIDeleteValidationFunction_SL(eligibleRecords));
    }
  }
}