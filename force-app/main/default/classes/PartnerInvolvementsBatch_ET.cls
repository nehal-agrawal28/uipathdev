/**
 * @AUTHOR: UIPath
 * @DATE: 26/10/2021
 * @DESCRIPTION: This is PartnerInvolvementsBatch_ET class
 */
public without sharing class PartnerInvolvementsBatch_ET implements IGenericBatch {
  // Implemented execute method which gets called from generic batch execute
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    PartnerInvolvementsService_ET partnerService = (PartnerInvolvementsService_ET) Application_ET.Service.newInstance(
      PartnerInvolvementsService_ET.class
    );
    partnerService.syncPartnerTerritoriesOnCustomer('create', (List<Partner_Involvement__c>) sobjectList, null);
  }

  public void finish(Database.BatchableContext BC) {
  }
}