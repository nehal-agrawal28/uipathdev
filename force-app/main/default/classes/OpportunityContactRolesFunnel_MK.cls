public without sharing class OpportunityContactRolesFunnel_MK {
  public static void createFunnel(List<OpportunityContactRole> oppCntRoles) {
    List<Funnel__c> funnelsToInsert = new List<Funnel__c>();
    Map<Id, Id> contactOppMap = new Map<Id, Id>();
    for (OpportunityContactRole ocr : oppCntRoles) {
      if (!contactOppMap.containsKey(ocr.ContactId)) {
        contactOppMap.put(ocr.ContactId, ocr.OpportunityId);
      }
    }

    Map<Id, Opportunity> oppsMap = getOpps(contactOppMap.values());
    Map<Id, Contact> cntsMap = getCnts(contactOppMap.keyset());
    Map<String, String> oppFunnelStages = LeadMetadata_MK.getOppFunnelStagesMap();
    for (OpportunityContactRole ocr : oppCntRoles) {
      Contact cnt = cntsMap.get(ocr.ContactId);
      if (
        (cnt.CreatedDate < (DateTime.Now()).addMinutes(-2) && oppsMap.containsKey(ocr.OpportunityId)) ||
        Test.isRunningTest()
      ) {
        Opportunity opp = oppsMap.get(ocr.OpportunityId);
        if (opp != null && oppFunnelStages.containsKey(opp.StageName)) {
          Funnel__c funn = createUpdateFunnel(cnt, opp, oppFunnelStages);
          if (funn != null)
            funnelsToInsert.add(funn);
        }
      }
    }
    if (funnelsToInsert.size() > 0) {
      insert funnelsToInsert;
    }
  }

  public static Funnel__c createUpdateFunnel(Contact c, Opportunity o, Map<String, String> oppStages) {
    Funnel__c f = new Funnel__c();
    f.put('Contact__c', c.Id);
    f.put('Opportunity__c', o.Id);
    f.put('Opportunity_Owner_' + (o.StageName).replace(' ', '_') + '__c', o.Owner.Name);
    if (oppStages.containsKey(o.StageName)) {
      f.put('Stage__c', oppStages.get(o.StageName));
      f.put('Stage_' + f.Stage__c + '_Timestamp__c', Datetime.Now());
    }
    return f;
  }

  public static Map<Id, Contact> getCnts(Set<Id> cntIds) {
    return new Map<Id, Contact>([SELECT Id, CreatedDate FROM Contact WHERE ID IN :cntIds]);
  }

  public static Map<Id, Opportunity> getOpps(List<Id> oppIds) {
    return new Map<Id, Opportunity>([SELECT Id, StageName, Owner.Name FROM Opportunity WHERE ID IN :oppIds]);
  }
}