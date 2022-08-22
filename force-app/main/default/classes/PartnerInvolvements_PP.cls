public without sharing class PartnerInvolvements_PP extends fflib_SObjectDomain {
  public PartnerInvolvements_PP(List<Partner_Involvement__c> partnerInvolvements) {
    super(partnerInvolvements);
    Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    if (!FeatureManagement.checkPermission('PartnerManagementAdmin')) {
      preventDealRegSourcedChanges();
    }
  }

  private void preventDealRegSourcedChanges() {
    Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ Partner_Involvement__c.Opportunity_Sourced__c };
    List<Partner_Involvement__c> changedRecords = (List<Partner_Involvement__c>) getChangedRecords(fields);

    Set<Id> opportunityIds = Utilities_PP.pluckIdField(changedRecords, Partner_Involvement__c.PartnerOpp_Name__c);

    List<DealRegistration__c> dealRegs = [
      SELECT Opportunity__c, Id
      FROM DealRegistration__c
      WHERE Opportunity__c = :opportunityIds
    ];

    for (Partner_Involvement__c involvement : changedRecords) {
      for (DealRegistration__c deal : dealRegs) {
        if (deal.Opportunity__c == involvement.PartnerOpp_Name__c) {
          involvement.addError(
            'You can not change the Opportunity Sourced flag when the opportunity is created through Deal Registration.'
          );
          continue;
        }
      }
    }
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new PartnerInvolvements_PP(sObjectList);
    }
  }
}