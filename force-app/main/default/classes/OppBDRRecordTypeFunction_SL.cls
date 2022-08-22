public inherited sharing class OppBDRRecordTypeFunction_SL implements SObjectToSObjectFunction {
  public static final String BDR_OPEN_STAGE = 'Open';
  public static final String BDR_ACCEPTED_STAGE = 'Accepted';
  public static final String CPQ_DEFAULT_STAGE = 'Discovery';
  private static final String BDR_DEAL_TYPE = 'Direct';
  private static final String TYPE_BDR_RT = 'SET_BDR_RT';
  private static final String TYPE_BDR_ACCEPTED = 'BDR_ACCEPTED';
  private String recordTypeIdBDR;
  private String type;

  public OppBDRRecordTypeFunction_SL(String type) {
    this.type = type;
    this.recordTypeIdBDR = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('BDR')
      .getRecordTypeId();
  }

  public SObject apply(Opportunity record) {
    if (this.type == TYPE_BDR_RT) {
      // Set BDR record type and Direct deal type
      record.RecordTypeId = recordTypeIdBDR;
      record.Deal_Type__c = BDR_DEAL_TYPE;
      record.StageName = BDR_OPEN_STAGE;
    } else if (this.type == TYPE_BDR_ACCEPTED) {
      // Change accepted BDR opp to CPQ Default
      record.RecordTypeId = OpportunityMetadata_SL.CPQDefaultRecordType;
      record.StageName = CPQ_DEFAULT_STAGE;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   * Set Opportunity RT BDR on insert
   */
  public static void deriveBRDRecordType(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Opportunity.SBQQ__RenewedContract__c)
          .equals(null)
          .also(Opportunity.SBQQ__AmendedContract__c)
          .equals(null)
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      User currentUser = [SELECT Id, BDR__c FROM User WHERE Id = :UserInfo.getUserId()];
      if (currentUser.BDR__c) {
        Collection.of(eligibleRecords).mapAll(new OppBDRRecordTypeFunction_SL(TYPE_BDR_RT));
      }
    }
  }

  /**
   * Set Opportunity RT after BDR is accepted
   */
  public static void deriveAcceptedBRDRecordType(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.StageName).equals(BDR_ACCEPTED_STAGE))
      .filter(Match.field(Opportunity.Amount).notequals(null))
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppBDRRecordTypeFunction_SL(TYPE_BDR_ACCEPTED));
    }
  }
}