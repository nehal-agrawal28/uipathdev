/**
 * Responsibility: Created and update funnels
 */
public with sharing class LeadFunnelQueueable_MK extends AbstractQueueable {
  private final List<Lead> leads;
  private final Map<Id, SObject> existingLeads;

  public LeadFunnelQueueable_MK(List<Lead> leads, Map<Id, SObject> existingLeads) {
    super('LeadFunnelQueueable_MK');
    this.leads = getLeads(leads);
    this.existingLeads = existingLeads;
  }

  public override void work() {
    Id recordTypeBDR = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('BDR').getRecordTypeId();
    Id recordTypeCPQ = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('CPQ_Default')
      .getRecordTypeId();
    if (existingLeads == null)
      this.LeadsInsert(this.leads, recordTypeBDR, recordTypeCPQ);
    else
      this.LeadsUpdate(this.leads, this.existingLeads, recordTypeBDR, recordTypeCPQ);
  }

  private void LeadsInsert(List<Lead> leads, Id recordTypeBDR, Id recordTypeCPQ) {
    Set<String> oppStages = new Set<String>{ 'Open', 'Discovery' };
    List<Funnel__c> funnelsToInsert = new List<Funnel__c>();
    for (Lead l : leads) {
      Funnel__c f = new Funnel__c();
      f = createUpdateFunnel(f, l, null, oppStages, recordTypeBDR, recordTypeCPQ);
      funnelsToInsert.add(f);
    }
    if (funnelsToInsert.size() > 0)
      insert funnelsToInsert;
  }

  private void LeadsUpdate(List<Lead> leads, Map<Id, SObject> existingLeads, Id recordTypeBDR, Id recordTypeCPQ) {
    Set<String> oppStages = new Set<String>{ 'Open', 'Discovery' };
    List<Funnel__c> funnelsToInsert = new List<Funnel__c>();
    List<Funnel__c> funnelsToUpdate = new List<Funnel__c>();
    Map<Id, Funnel__c> existingFunnelsMap = getFunnelsByLeadId(leads);
    Map<Id, List<Funnel__c>> closedFunnelsMap = getClosedFunnelsByLeadId(leads);
    Set<String> includedStatuses = new Set<String>{ 'Suspect', 'MQL', 'Sales Generated' };
    for (Lead l : leads) {
      Lead oldLead = (Lead) existingLeads.get(l.Id);
      Funnel__c f = new Funnel__c();
      Boolean isFunnel = false;
      if (existingFunnelsMap.containsKey(l.Id)) {
        f = existingFunnelsMap.get(l.Id);
        isFunnel = true;
      }
      f = createUpdateFunnel(f, l, oldLead, oppStages, recordTypeBDR, recordTypeCPQ);
      if (isFunnel == false && includedStatuses.contains(l.Status))
        funnelsToInsert.add(f);
      else
        funnelsToUpdate.add(f);
      if (l.Status == LeadMetadata_MK.QUALIFIED_STATUS) {
        if (closedFunnelsMap.containsKey(l.Id)) {
          List<Funnel__c> closedFunnelsForLead = closedFunnelsMap.get(l.Id);
          for (Funnel__c fun : closedFunnelsForLead) {
            if (fun.Contact__c == null && l.ConvertedContactId != null) {
              fun.Contact__c = l.ConvertedContactId;
              //if(fun.Opportunity__c == null && l.ConvertedOpportunityId != null)
              //fun.Opportunity__c = l.ConvertedOpportunityId;
              funnelsToUpdate.add(fun);
            }
          }
        }
      }
    }
    if (funnelsToInsert.size() > 0)
      insert funnelsToInsert;
    if (funnelsToUpdate.size() > 0)
      update funnelsToUpdate;
  }

  public static Funnel__c createUpdateFunnel(
    Funnel__c f,
    Lead l,
    Lead oldLead,
    Set<String> oppStages,
    Id recordTypeBDR,
    Id recordTypeCPQ
  ) {
    if (f.Lead__c == null)
      f.put('Lead__c', l.Id);

    if (l.Status == LeadMetadata_MK.SUSPECT_STATUS) {
      if (String.isEmpty(f.Funnel_Type__c))
        f.put('Funnel_Type__c', LeadMetadata_MK.FUNNEL_MQL_TYPE);
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_SUSPECT_STAGE);
    }

    if (l.Status == LeadMetadata_MK.MQL_STATUS) {
      f.put('Funnel_Type__c', LeadMetadata_MK.FUNNEL_MQL_TYPE);
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_MQL_STAGE);
    }

    if (l.Status == LeadMetadata_MK.SALES_GENERATED_STATUS) {
      if (
        oldLead != null &&
        (oldLead.Status == LeadMetadata_MK.SUSPECT_STATUS ||
        oldLead.Status == LeadMetadata_MK.DECLINED_STATUS ||
        oldLead.Status == LeadMetadata_MK.DISQUALIFIED_STATUS)
      ) {
        f.put('Funnel_Type__c', LeadMetadata_MK.FUNNEL_SALES_PROGRESSED_TYPE);
        f.put('Stage__c', LeadMetadata_MK.FUNNEL_SPL_STAGE);
      } else {
        if (String.isEmpty(f.Funnel_Type__c))
          f.put('Funnel_Type__c', LeadMetadata_MK.FUNNEL_SALES_GENERATED_TYPE);
        f.put('Stage__c', LeadMetadata_MK.FUNNEL_SGL_STAGE);
      }
    }

    if (l.Status == LeadMetadata_MK.ACCEPTED_STATUS) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_TAL_STAGE);
    }
    if (l.Status == LeadMetadata_MK.DISQUALIFIED_STATUS) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_DISQUALIFIED_STAGE);
    }
    if (l.Status == LeadMetadata_MK.DECLINED_STATUS) {
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_DECLINED_STAGE);
    }

    if (l.Status == LeadMetadata_MK.QUALIFIED_STATUS) {
      f.put('Contact__c', l.ConvertedContactId);
      f.put('Stage__c', LeadMetadata_MK.FUNNEL_CONVERTED_STAGE);
      f.put(
        'Contact_Owner_' +
        (l.ConvertedContact.Contact_Status__c).replace(' ', '_') +
        '__c',
        l.ConvertedContact.Owner.Name
      );
      if (l.ConvertedOpportunityId != null) {
        f.put('Opportunity__c', l.ConvertedOpportunityId);
        if (oppStages.contains(l.ConvertedOpportunity.StageName))
          f.put(
            'Opportunity_Owner_' +
            (l.ConvertedOpportunity.StageName).replace(' ', '_') +
            '__c',
            l.ConvertedContact.Owner.Name
          );
        if (
          (l.ConvertedOpportunity.CreatedDate < (Datetime.now()).addHours(-1)) ||
          !oppStages.contains(l.ConvertedOpportunity.StageName)
        )
          f.put('Stage__c', LeadMetadata_MK.FUNNEL_CONVERTED_STAGE);
        else {
          if (l.ConvertedOpportunity.RecordTypeId == recordTypeBDR)
            f.put('Stage__c', LeadMetadata_MK.FUNNEL_TQL_STAGE);
          if (l.ConvertedOpportunity.RecordTypeId == recordTypeCPQ)
            f.put('Stage__c', LeadMetadata_MK.FUNNEL_SQL_STAGE);
        }
      }
    }
    if (f.Stage__c != null) {
      String noSpaceStage = (f.Stage__c).replace(' ', '_');
      f.put('Stage_' + noSpaceStage + '_Timestamp__c', DateTime.Now());
    }
    f.put('Lead_Owner_' + (l.Status).replace(' ', '_') + '__c', l.Owner.Name);
    f.put('Lead_LatestOwnerGroup_' + (l.Status).replace(' ', '_') + '__c', l.Latest_MQL_Owner_Group__c);
    return f;
  }

  public static List<Lead> getLeads(List<Lead> leads) {
    List<Lead> leadsList = new List<Lead>();
    for (Lead l : [
      SELECT
        Id,
        Status,
        Owner.Name,
        ConvertedContactId,
        ConvertedContact.Owner.Name,
        ConvertedContact.Contact_Status__c,
        ConvertedOpportunityId,
        ConvertedOpportunity.Owner.Name,
        ConvertedOpportunity.StageName,
        ConvertedOpportunity.CreatedDate,
        ConvertedOpportunity.RecordTypeId,
        Latest_MQL_Owner_Group__c
      FROM Lead
      WHERE Id IN :leads
    ]) {
      leadsList.add(l);
    }
    return leadsList;
  }

  public static Map<Id, Funnel__c> getFunnelsByLeadId(List<Lead> leads) {
    Map<Id, Funnel__c> funnelMap = new Map<Id, Funnel__c>();

    for (Funnel__c fun : [
      SELECT
        Id,
        Lead__c,
        Contact__c,
        Opportunity__c,
        Funnel_Type__c,
        Stage__c,
        Closed__c,
        Stage_Suspect_Timestamp__c,
        Stage_SGL_Timestamp__c,
        Stage_SAL_Timestamp__c,
        Stage_MQL_Timestamp__c,
        Stage_SQL_Timestamp__c,
        Stage_SPL_Timestamp__c,
        Stage_TQL_Timestamp__c,
        Stage_TAL_Timestamp__c,
        Stage_Declined_Timestamp__c,
        Stage_Disqualified_Timestamp__c,
        Opportunity_Owner_Open__c,
        Opportunity_Owner_Discovery__c
      FROM Funnel__c
      WHERE Lead__c IN :leads AND Opportunity__c = NULL AND Closed__c = FALSE
    ]) {
      funnelMap.put(fun.Lead__c, fun);
    }
    return funnelMap;
  }

  public static Map<Id, List<Funnel__c>> getClosedFunnelsByLeadId(List<Lead> leads) {
    Map<Id, List<Funnel__c>> funnelMap = new Map<Id, List<Funnel__c>>();
    for (Funnel__c fun : [
      SELECT Id, Lead__c, Contact__c, Opportunity__c
      FROM Funnel__c
      WHERE Lead__c IN :leads AND Closed__c = TRUE
    ]) {
      if (!funnelMap.containsKey(fun.Lead__c)) {
        List<Funnel__c> newFunnelList = new List<Funnel__c>();
        newFunnelList.add(fun);
        funnelMap.put(fun.Lead__c, newFunnelList);
      } else {
        List<Funnel__c> extFunnelList = funnelMap.get(fun.Lead__c);
        extFunnelList.add(fun);
        funnelMap.put(fun.Lead__c, extFunnelList);
      }
    }
    return funnelMap;
  }

  // on lead insert
  public static void leadFunnelOnInsert(List<Lead> leads) {
    List<Lead> eligibleLeads = Collection.of(leads)
      .filter(
        Match.field(Lead.Status)
          .isIn(
            new Set<String>{
              LeadMetadata_MK.SUSPECT_STATUS,
              LeadMetadata_MK.MQL_STATUS,
              LeadMetadata_MK.SALES_GENERATED_STATUS
            }
          )
      )
      .asList();
    if (!eligibleLeads.isEmpty()) {
      AbstractQueueable.enqueue(new LeadFunnelQueueable_MK(eligibleLeads, null));
    }
  }

  // on lead.status update
  public static void leadFunnelOnUpdate(List<Lead> leads, Map<Id, SObject> existingLeads) {
    SObjectPredicate hasChanged = new HasRecordChanged(new Set<SObjectField>{ Lead.Status }, leads, existingLeads);
    List<Lead> eligibleLeads = Collection.of(leads)
      .filter(hasChanged)
      .filter(
        Match.field(Lead.Status)
          .isIn(
            new Set<String>{
              LeadMetadata_MK.SUSPECT_STATUS,
              LeadMetadata_MK.MQL_STATUS,
              LeadMetadata_MK.SALES_GENERATED_STATUS,
              LeadMetadata_MK.DISQUALIFIED_STATUS,
              LeadMetadata_MK.ACCEPTED_STATUS,
              LeadMetadata_MK.DECLINED_STATUS,
              LeadMetadata_MK.QUALIFIED_STATUS
            }
          )
      )
      .asList();

    if (!eligibleLeads.isEmpty()) {
      AbstractQueueable.enqueue(new LeadFunnelQueueable_MK(eligibleLeads, existingLeads));
    }
  }
}