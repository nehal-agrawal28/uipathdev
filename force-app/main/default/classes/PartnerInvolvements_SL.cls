public with sharing class PartnerInvolvements_SL extends fflib_SObjectDomain implements IPartnerInvolvements_SL {
  public static IPartnerInvolvements_SL newInstance(List<Partner_Involvement__c> recordList) {
    return (IPartnerInvolvements_SL) Application.Domain.newInstance(recordList);
  }

  public static IPartnerInvolvements_SL newInstance(Set<Id> recordIdSet) {
    return (IPartnerInvolvements_SL) Application.Domain.newInstance(recordIdSet);
  }

  public PartnerInvolvements_SL(List<Partner_Involvement__c> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    PISourceValidationFunction_SL.preventDuplicateSources(records);
    PISoldToValidationFunction_SL.preventDuplicateSoldTo(records);
    PIPrimaryInfluenceFunction_SL.preventDuplicatePrimary(records);
    PIBusinessPartnerFieldsFunction_SL.deriveBusinessPartnerFields(records);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    PISourceValidationFunction_SL.preventDuplicateSources(records, existingRecords);
    PISoldToValidationFunction_SL.preventDuplicateSoldTo(records, existingRecords);
    PIPrimaryInfluenceFunction_SL.preventDuplicatePrimary(records, existingRecords);
    PIBusinessPartnerFieldsFunction_SL.deriveBusinessPartnerFields(records);
  }

  public override void onBeforeDelete() {
    PIDeleteValidationFunction_SL.preventDeletion(records);
  }

  public override void onAfterInsert() {
    PIOpportunityQueueable_SL.modifyOpportunities(records).execute();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    PIOpportunityQueueable_SL.modifyOpportunities(records, existingRecords).execute();
  }

  public override void onAfterDelete() {
    PIOpportunityQueueable_SL.modifyOpportunities(records).execute();
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new PartnerInvolvements_SL(sObjectList);
    }
  }
}