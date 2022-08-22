public without sharing class ProductSelectionController_PP {
  @AuraEnabled(cacheable=true)
  public static List<PricebookEntry> getPricebookEntries(String priceBook, String currencyIsoCode) {
    final PricebookEntriesSelector_PP pricebookEntriesSelector = (PricebookEntriesSelector_PP) Application_PP.Selector.newInstance(
      PricebookEntry.SObjectType
    );
    return pricebookEntriesSelector.selectByPricebookNameAndCurrency(
      new Set<String>{ priceBook },
      currencyIsoCode,
      false
    );
  }

  @AuraEnabled
  public static Id createDealRegWithProducts(
    DealRegistration__c dealReg,
    List<DealRegistrationProduct__c> dealRegProducts
  ) {
    final UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    final User partnerUser = usersSelector.selectById(new Set<Id>{ UserInfo.getUserId() }, false)[0];

    dealReg.Account__c = partnerUser.Contact_Account_Id__c;
    dealReg.OwnerId = partnerUser.Id;
    dealReg.CloseDate__c = Date.today().addDays(30);

    try {
      DealRegistrationsService_PP dealRegistrationsService = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
        DealRegistrationsService_PP.class
      );
      return dealRegistrationsService.createDealRegWithProducts(dealReg, dealRegProducts);
    } catch (Exception e) {
      PartnerPortalException.LogException(e, 'Creating Deal Registration', 'Error while creating Deal Registration');
      return null;
    }
  }

  @AuraEnabled
  public static Map<String, String> getPriceBookAndCurrency(String dealRegId) {
    final DealRegistrationsSelector_PP dealRegistrationsSelector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );
    final DealRegistration__c dealRegistration = dealRegistrationsSelector.selectByIdWithPriceBookName(
      new Set<Id>{ dealRegId },
      false
    )[0];
    return new Map<String, String>{
      'priceBook' => dealRegistration.PriceBook__r.Name,
      'currencyIsoCode' => dealRegistration.CurrencyIsoCode
    };
  }

  @AuraEnabled
  public static Boolean addProducts(String dealRegId, List<DealRegistrationProduct__c> dealRegProducts) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    for (DealRegistrationProduct__c dealRegProduct : dealRegProducts) {
      dealRegProduct.DealRegistration__c = dealRegId;
    }

    unitOfWork.registerNew(dealRegProducts);

    try {
      unitOfWork.commitWork();
      DealRegistrationsService_PP dealRegistrationsService = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
        DealRegistrationsService_PP.class
      );
      dealRegistrationsService.updateAmounts(new Set<Id>{ dealRegId });
      return true;
    } catch (Exception e) {
      PartnerPortalException.LogException(e, 'Creating Deal Registration', 'Error while creating Deal Registration');
      return false;
    }
  }
}