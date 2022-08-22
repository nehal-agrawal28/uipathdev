public with sharing class DealRegistrationProducts_PP extends fflib_SObjectDomain {

  public DealRegistrationProducts_PP(List<DealRegistrationProduct__c> sObjectList) {
    super(sObjectList, DealRegistrationProduct__c.SObjectType);
  }

  public override void onBeforeDelete() {
    validateRecordTypeOfDealReg();
  }

  public override void onAfterDelete() {
    changeDealRegAmount();
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    changeDealRegAmount();
  }

  private void validateRecordTypeOfDealReg() {
    final Id SubmittedDealRegistrationRT = SObjectType.DealRegistration__c.getRecordTypeInfosByDeveloperName()
      .get('SubmittedDealRegistration')
      .getRecordTypeId();

    Map<Id, Set<Id>> dealRegProductIdsByDealRegId = new Map<Id, Set<Id>>{};
    for (DealRegistrationProduct__c dealRegProduct : (List<DealRegistrationProduct__c>) Records) {
      if (dealRegProductIdsByDealRegId.containsKey(dealRegProduct.DealRegistration__c)) {
        dealRegProductIdsByDealRegId.get(dealRegProduct.DealRegistration__c).add(dealRegProduct.Id);
      } else {
        dealRegProductIdsByDealRegId.put(dealRegProduct.DealRegistration__c, new Set<Id>{ dealRegProduct.Id });
      }
    }

    final DealRegistrationsSelector_PP dealRegistrationsSelector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );
    for (
      DealRegistration__c dealRegistration : dealRegistrationsSelector.selectByIdAndRTId(
        dealRegProductIdsByDealRegId.keySet(),
        new Set<Id>{ SubmittedDealRegistrationRT },
        false
      )
    ) {
      for (Id dealRegProductId : dealRegProductIdsByDealRegId.get(dealRegistration.Id)) {
        existingRecords.get(dealRegProductId).addError(System.Label.You_Can_Not_Delete_Products_Of_Submitted_Deal_Regs);
      }
    }
  }

  private void changeDealRegAmount() {
    List<DealRegistrationProduct__c> changedRecords;

    if (Trigger.isDelete) {
      changedRecords = Records;
    } else {
      changedRecords = getChangedRecords(new Set<Schema.SObjectField>{ DealRegistrationProduct__c.Quantity__c });
      if (changedRecords.isEmpty())
        return;
    }

    Set<Id> dealRegIdsToUpdate = Utilities_PP.pluckIdField(
      changedRecords,
      DealRegistrationProduct__c.DealRegistration__c
    );
    DealRegistrationsService_PP dealRegistrationsService = ((DealRegistrationsService_PP) Application_PP.Service.newInstance(
      DealRegistrationsService_PP.class
    ));
    dealRegistrationsService.updateAmounts(dealRegIdsToUpdate);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new DealRegistrationProducts_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new DealRegistrationProducts_PP(sObjectList);
    }
  }
}