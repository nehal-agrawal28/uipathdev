public with sharing class QuickQuoteController_SL {
  private static final String DEFAULT_PACKAGE = 'UICPNPS0000';

  private QuickQuoteController_SL() {
  }

  @AuraEnabled(Cacheable=true)
  public static AddProductsResultWrapper addProductsToQuote(
    Id quoteId,
    List<Id> productIds,
    Double targetCustomerAmount
  ) {
    try {
      IQuoteService_SL quoteService = (IQuoteService_SL) Application_SL.Service.newInstance(IQuoteService_SL.class);
      //      quoteService.addProductsToQuote(quoteId, productIds, targetCustomerAmount);
      quoteService.addPackageWithOptions(
        quoteId,
        [SELECT Id FROM Product2 WHERE ProductCode = :DEFAULT_PACKAGE LIMIT 1]
        .Id,
        productIds,
        targetCustomerAmount
      );

      return new AddProductsResultWrapper(true, 'Success', 'Added Products Successfully');
    } catch (Exception e) {
      System.debug(e.getMessage());
      return new AddProductsResultWrapper(false, 'Unable to add Products to Quote', e.getMessage());
    }
  }

  public class AddProductsResultWrapper {
    @AuraEnabled
    public Boolean isSuccess { get; set; }
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public String message { get; set; }
    public AddProductsResultWrapper(Boolean isSuccess, String title, String message) {
    }
  }

  @InvocableMethod(label='Add Products to Quote' description='Add Products to Quote and optionally set a target amount')
  public static void addProductsToQuote(List<AddProductToQuoteRequest> addProductsToQuoteRequests) {
    for (AddProductToQuoteRequest addProductToQuoteRequest : addProductsToQuoteRequests) {
      addProductsToQuote(
        addProductToQuoteRequest.quoteid,
        addProductToQuoteRequest.productIds.split(','),
        addProductToQuoteRequest.targetCustomerAmount
      );
    }
  }

  public class AddProductToQuoteRequest {
    @InvocableVariable(required=true)
    public Id quoteid;
    @InvocableVariable(required=true)
    public String productIds;
    @InvocableVariable(required=false)
    public Double targetCustomerAmount;
  }
}