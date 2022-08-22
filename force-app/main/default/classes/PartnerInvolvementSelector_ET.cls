public without sharing class PartnerInvolvementSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Partner_Involvement__c.Opportunity_Sourced__c,
      Partner_Involvement__c.Partner_Account_Name__c,
      Partner_Involvement__c.PartnerOpp_Name__c,
      Partner_Involvement__c.Partner_Manager__c,
      Partner_Involvement__c.Partner_Manager_Territory__c,
      Partner_Involvement__c.Region_Partner_Manager__c,
      Partner_Involvement__c.Region_Partner_Manager_Territory__c
    };
  }
  public Schema.SObjectType getSObjectType() {
    return Partner_Involvement__c.sObjectType;
  }

  public List<Partner_Involvement__c> selectByOppId(Set<Id> OppIds) {
    return (List<Partner_Involvement__c>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Partner_Account_Name__r.Classification__c')
        .selectField('PartnerOpp_Name__r.Is_Partner_Sourced__c')
        .setCondition('PartnerOpp_Name__c =: OppIds')
        .toSOQL()
    );
  }

  /*public List<Partner_Involvement__c> getoppPartnerInvolvementMap(Set<Id> OppIds) {
    List<Partner_Involvement__c> partnerInvList = selectByOppId(OppIds);
    Map<String, Partner_Involvement__c> oppPartnerInvolvementMap = new Map<String, Partner_Involvement__c>();
    for(Partner_Involvement__c pInv : partnerInvList)
    {
        oppPartnerInvolvementMap.put(pInv.PartnerOpp_Name__c, pInv);
    }
     return oppPartnerInvolvementMap;
  }*/
}