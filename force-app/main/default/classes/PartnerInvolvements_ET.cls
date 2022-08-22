public with sharing class PartnerInvolvements_ET extends fflib_SObjectDomain {
  public PartnerInvolvements_ET(List<Partner_Involvement__c> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    PIApprovalMatrixFunction_ET.deriveApprovers(records);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    PIApprovalMatrixFunction_ET.deriveApprovers(records, existingRecords);
  }

  public override void onAfterInsert() {
    PartnerInvolvementsService_ET partnerService = (PartnerInvolvementsService_ET) Application_ET.Service.newInstance(
      PartnerInvolvementsService_ET.class
    );
    partnerService.syncPartnerTerritoriesOnCustomer('create', records, null);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    PartnerInvolvementsService_ET partnerService = (PartnerInvolvementsService_ET) Application_ET.Service.newInstance(
      PartnerInvolvementsService_ET.class
    );
    List<Partner_Involvement__c> changedRecords = getChangedRecords(
      new Set<Schema.SObjectField>{ Partner_Involvement__c.Partner_Account_Name__c }
    );
    if (changedRecords.isEmpty())
      return;
    partnerService.syncPartnerTerritoriesOnCustomer(
      'update',
      changedRecords,
      (Map<Id, Partner_Involvement__c>) existingRecords
    );
  }

  public override void onAfterDelete() {
    PartnerInvolvementsService_ET partnerService = (PartnerInvolvementsService_ET) Application_ET.Service.newInstance(
      PartnerInvolvementsService_ET.class
    );
    partnerService.syncPartnerTerritoriesOnCustomer('delete', records, null);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new PartnerInvolvements_ET(sObjectList);
    }
  }
}