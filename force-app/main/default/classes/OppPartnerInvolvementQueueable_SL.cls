public with sharing class OppPartnerInvolvementQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;

  public OppPartnerInvolvementQueueable_SL(List<SObject> opps) {
    super('OppPartnerInvolvementQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.clonePartnerInvolvments(this.opps);
  }

  private void clonePartnerInvolvments(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = [
      SELECT
        Id,
        SBQQ__AmendedContract__c,
        SBQQ__AmendedContract__r.SBQQ__Opportunity__c,
        SBQQ__RenewedContract__c,
        SBQQ__RenewedContract__r.SBQQ__Opportunity__c,
        SBQQ__Renewal__c
      FROM Opportunity
      WHERE Id IN :records
    ];

    Map<Id, Id> oppsMap = new Map<Id, Id>();
    for (Opportunity opp : eligibleRecords) {
      if (opp.SBQQ__AmendedContract__c != null) {
        oppsMap.put(opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c, opp.Id);
      }
      if (opp.SBQQ__RenewedContract__c != null && opp.SBQQ__Renewal__c == true) {
        oppsMap.put(opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__c, opp.Id);
      }
    }

    if (oppsMap.isEmpty()) {
      return;
    }

    String selectFieldsQuery = String.join(getCreateableFields(), ', ');

    Set<Id> oppsMapKeys = oppsMap.keySet();
    List<Partner_Involvement__c> relatedPartnerInvolvments = Database.query(
      'SELECT ' +
      String.escapeSingleQuotes(selectFieldsQuery) +
      ' FROM Partner_Involvement__c WHERE PartnerOpp_Name__c IN :oppsMapKeys'
    );

    Map<Id, List<Partner_Involvement__c>> involvementsByOriginalOppIds = Collection.of(relatedPartnerInvolvments)
      .groupByIds(Partner_Involvement__c.PartnerOpp_Name__c);

    List<Partner_Involvement__c> partnerInvolvmentToInsert = new List<Partner_Involvement__c>();
    for (Id originalOppId : involvementsByOriginalOppIds.keySet()) {
      List<Partner_Involvement__c> partnerInvolvementList = involvementsByOriginalOppIds.get(originalOppId);
      Id newOppId = oppsMap.get(originalOppId);
      for (Partner_Involvement__c partnerInvolvement : partnerInvolvementList) {
        Partner_Involvement__c newPartnerInvolvement = partnerInvolvement.clone();
        newPartnerInvolvement.PartnerOpp_Name__c = newOppId;
        partnerInvolvmentToInsert.add(newPartnerInvolvement);
      }
    }
    insert partnerInvolvmentToInsert;
  }

  public static void clonePartnerInvolvements(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(Match.field(Opportunity.RecordTypeId).equals(OpportunityMetadata_SL.CPQDefaultRecordType))
      .filter(new FilterOpportunities())
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppPartnerInvolvementQueueable_SL(eligibleRecords));
    }
  }

  public static List<String> getCreateableFields() {
    List<String> createableFields = new List<String>();
    Schema.DescribeSObjectResult objectDescribe = Partner_Involvement__c.SObjectType.getDescribe();
    Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
    for (String fieldName : fieldMap.keySet()) {
      Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
      if (fieldResult.isCreateable()) {
        createableFields.add(fieldName);
      }
    }
    return createableFields;
  }

  private class FilterOpportunities implements SObjectPredicate {
    private Boolean apply(Opportunity opp) {
      return (opp.SBQQ__AmendedContract__c != null ||
      (opp.SBQQ__RenewedContract__c != null &&
      opp.SBQQ__Renewal__c == true));
    }

    public Boolean apply(SObject record) {
      return apply((Opportunity) record);
    }
  }
}