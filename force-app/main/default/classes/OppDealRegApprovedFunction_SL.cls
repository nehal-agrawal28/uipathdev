public inherited sharing class OppDealRegApprovedFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(Opportunity record) {
    if (record.RecordTypeId == OpportunityMetadata_SL.DealRegistrationRecordType) {
      record.Converted_from_Deal_Reg__c = true;
      record.RecordTypeId = OpportunityMetadata_SL.CPQDefaultRecordType;
      record.StageName = 'Discovery';
    }
    record.Deal_Reg_Approved_Date__c = System.Today();
    record.Deal_Reg_Expire_Date_new__c = System.Today().addDays(90);
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   * Set Opportunity RT on update
   */
  public static void deriveDefaults(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Deal_Reg_Status__c },
      records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.Deal_Reg_Status__c).equals('Approved'))
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppDealRegApprovedFunction_SL());
    }
  }

  /**
   * Set Opportunity RT on insert
   */
  public static void deriveDefaults(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(Match.field(Opportunity.Deal_Reg_Status__c).equals('Approved'))
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppDealRegApprovedFunction_SL());
    }
  }
}