/**
 * Responsibility: Update funnels
 */
public with sharing class OpportunityFunnelQueueable extends AbstractQueueable {
  private final List<Opportunity> opportunities;

  public OpportunityFunnelQueueable(List<Opportunity> opportunities) {
    super('OpportunityFunnelQueueable');
    this.opportunities = getOpportunities(opportunities);
  }

  public override void work() {
    Id recordTypeBDR = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('BDR').getRecordTypeId();
    Id recordTypeCPQ = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('CPQ_Default')
      .getRecordTypeId();
    Map<Id, List<Funnel__c>> existingFunnelsMap = getFunnelsByOpportunityId(opportunities);
    List<Funnel__c> funnelsToUpdate = new List<Funnel__c>();
    for (Opportunity o : opportunities) {
      if (existingFunnelsMap.containsKey(o.Id)) {
        List<Funnel__c> oppFunnels = existingFunnelsMap.get(o.Id);
        for (Funnel__c f : oppFunnels) {
          f = updateFunnel(f, o, recordTypeBDR, recordTypeCPQ);
          funnelsToUpdate.add(f);
        }
      }
    }
    update funnelsToUpdate;
  }

  public static Funnel__c updateFunnel(Funnel__c f, Opportunity o, Id recordTypeBDR, Id recordTypeCPQ) {
    if (o.StageName == LeadMetadata_MK.OPP_OPEN_STAGE) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_TQL_STAGE);
    }

    if (o.StageName == LeadMetadata_MK.OPP_MEETING_CANCELLED_STAGE) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_MEETING_CANCELLED_STAGE);
    }
    if (o.StageName == LeadMetadata_MK.OPP_MEETING_HELD_STAGE) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_SAL_STAGE);
    }
    if (o.StageName == LeadMetadata_MK.OPP_DECLINED_STAGE && o.RecordTypeId == recordTypeBDR) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_BDR_OPP_DECLINED_STAGE);
    }

    if (
      (o.StageName == LeadMetadata_MK.OPP_ACCEPTED_STAGE && o.RecordTypeId == recordTypeBDR) ||
      (o.StageName == LeadMetadata_MK.OPP_DISCOVERY_STAGE &&
      o.RecordTypeId == recordTypeCPQ)
    ) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_SQL_STAGE);
    }

    if (o.StageName == LeadMetadata_MK.OPP_CLOSED_WON_BOOKED_STAGE) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_CLOSED_WON_STAGE);
    }

    if (
      o.StageName == LeadMetadata_MK.OPP_CLOSED_LOST_STAGE ||
      o.StageName == LeadMetadata_MK.OPP_CLOSED_MERGED_STAGE
    ) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_CLOSED_LOST_STAGE);
    }
    String noSpaceStage = (f.Stage__c).replace(' ', '_');
    f.put('Stage_' + noSpaceStage + '_Timestamp__c', DateTime.Now());

    f.put('Opportunity_Owner_' + (o.StageName).replace(' ', '_') + '__c', o.Owner.Name);

    return f;
  }

  public static List<Opportunity> getOpportunities(List<Opportunity> opps) {
    List<Opportunity> allOpps = new List<Opportunity>();
    for (Opportunity opp : [SELECT Id, StageName, Owner.Name, RecordTypeId FROM Opportunity WHERE Id IN :opps]) {
      allOpps.add(opp);
    }
    return allOpps;
  }

  public static Map<Id, List<Funnel__c>> getFunnelsByOpportunityId(List<Opportunity> opportunities) {
    Map<Id, List<Funnel__c>> funnelMap = new Map<Id, List<Funnel__c>>();

    for (Funnel__c fun : [
      SELECT
        Id,
        Opportunity__c,
        Funnel_Type__c,
        Stage__c,
        Stage_SAL_Timestamp__c,
        Stage_SQL_Timestamp__c,
        Stage_TQL_Timestamp__c,
        Stage_Meeting_Cancelled_Timestamp__c,
        Stage_BDR_Opp_Declined_Timestamp__c,
        Stage_Closed_Won_Timestamp__c,
        Stage_Closed_Lost_Timestamp__c
      FROM Funnel__c
      WHERE Opportunity__c IN :opportunities AND Closed__c = FALSE
    ]) {
      if (!funnelMap.containsKey(fun.Opportunity__c)) {
        List<Funnel__c> newFunnelList = new List<Funnel__c>();
        newFunnelList.add(fun);
        funnelMap.put(fun.Opportunity__c, newFunnelList);
      } else {
        List<Funnel__c> exFunnelList = funnelMap.get(fun.Opportunity__c);
        exFunnelList.add(fun);
        funnelMap.put(fun.Opportunity__c, exFunnelList);
      }
    }
    return funnelMap;
  }

  // on opportunities status update
  public static void OpportunityFunnelOnUpdate(
    List<Opportunity> opportunities,
    Map<Id, SObject> existingopportunities
  ) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName, Opportunity.RecordTypeId },
      opportunities,
      existingopportunities
    );
    List<Opportunity> eligibleopportunities = Collection.of(opportunities)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.RecordTypeId)
          .isIn(new Set<String>{ OpportunityMetadata_SL.CPQDefaultRecordType, OpportunityMetadata_SL.BDRRecordType })
      )
      .filter(
        Match.field(Opportunity.StageName)
          .isIn(
            new Set<String>{
              LeadMetadata_MK.OPP_OPEN_STAGE,
              LeadMetadata_MK.OPP_MEETING_CANCELLED_STAGE,
              LeadMetadata_MK.OPP_MEETING_HELD_STAGE,
              LeadMetadata_MK.OPP_DECLINED_STAGE,
              LeadMetadata_MK.OPP_ACCEPTED_STAGE,
              LeadMetadata_MK.OPP_DISCOVERY_STAGE,
              LeadMetadata_MK.OPP_CLOSED_WON_BOOKED_STAGE,
              LeadMetadata_MK.OPP_CLOSED_LOST_STAGE,
              LeadMetadata_MK.OPP_CLOSED_MERGED_STAGE
            }
          )
      )
      .asList();

    if (!eligibleopportunities.isEmpty()) {
      AbstractQueueable.enqueue(new OpportunityFunnelQueueable(eligibleopportunities));
    }
  }
}