public without sharing class SubmitDealRegController_PP {
  @AuraEnabled
  public static void createOpportunityWithProducts(Id dealRegId) {
    final DealRegistrationsSelector_PP dealRegistrationsSelector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );

    final DealRegistration__c dealReg = dealRegistrationsSelector.selectById(new Set<Id>{ dealRegId }, false)[0];

    DealRegistrationsService_PP dealRegService = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
      DealRegistrationsService_PP.class
    );
    try {
      dealRegService.updateDealRegRecordType(dealReg, DealRegistrations_PP.SUBMITTED_RECORDTYPE_ID);
    } catch (Exception e) {
      AuraHandledException auraException = new AuraHandledException(e.getMessage());
      if (e.getMessage().contains(DealRegistrations_PP.BPO_DEALTYPE_IS_NOT_ALLOWED)) {
        auraException.setMessage(DealRegistrations_PP.BPO_DEALTYPE_IS_NOT_ALLOWED);
      }
      throw auraException;
    }
  }
}