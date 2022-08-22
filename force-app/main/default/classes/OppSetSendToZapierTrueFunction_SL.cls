public with sharing class OppSetSendToZapierTrueFunction_SL implements SObjectToSObjectFunction {
  public OppSetSendToZapierTrueFunction_SL() {
  }

  public SObject apply(Opportunity opp) {
    opp.Send_to_Zapier__c = true;
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void setSendToZapierAsTrue(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      opps,
      existingOpps
    );

    Collection.of(opps)
      .filter(hasChanged)
      .mapSome(
        Match.field(Opportunity.StageName).equals(OpportunityMetadata_SL.CLOSED_WON_BOOKED),
        new OppSetSendToZapierTrueFunction_SL()
      );
  }
}