public with sharing class OppChangeStageOnDealRegExFunction_SL implements SObjectToSObjectFunction {
  public OppChangeStageOnDealRegExFunction_SL() {
  }

  public SObject apply(Opportunity opp) {
    opp.StageName = OpportunityMetadata_SL.CLOSED_LOST;
    opp.Reason_1__c = OpportunityMetadata_SL.DROPPED_REASON_1;
    opp.Dropped_reason__c = OpportunityMetadata_SL.DEAL_REGISTRATION_EXPIRED_REASON;
    opp.Primary_Lost_Reason__c = OpportunityMetadata_SL.DEAL_REG_DECLINE_PRIMARY_LOST_REASON;
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void changeStageOnDealRegExpirationOnInsert(List<Opportunity> opps) {
    List<Opportunity> elegibleOpps = Collection.of(opps)
      .filter(
        Match.field(Opportunity.Deal_Reg_Status__c)
          .equals(OpportunityMetadata_SL.EXPIRED_DEAL_REG_STATUS)
          .also(Opportunity.StageName)
          .equals(OpportunityMetadata_SL.DEAL_REGISTRATION_STAGE)
      )
      .asList();

    if (!elegibleOpps.isEmpty()) {
      Collection.of(elegibleOpps).mapAll(new OppChangeStageOnDealRegExFunction_SL());
    }
  }

  public static void changeStageOnDealRegExpirationOnUpdate(List<Opportunity> opps, Map<Id, sObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Deal_Reg_Status__c, Opportunity.StageName },
      opps,
      existingOpps
    );

    List<Opportunity> elegibleOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.Deal_Reg_Status__c)
          .equals(OpportunityMetadata_SL.EXPIRED_DEAL_REG_STATUS)
          .also(Opportunity.StageName)
          .equals(OpportunityMetadata_SL.DEAL_REGISTRATION_STAGE)
      )
      .asList();
    if (!elegibleOpps.isEmpty()) {
      Collection.of(elegibleOpps).mapAll(new OppChangeStageOnDealRegExFunction_SL());
    }
  }
}