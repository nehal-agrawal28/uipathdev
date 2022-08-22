public without sharing class BudgetQuoteController_SL {
  public class BudgetQuoteWrapper {
    @AuraEnabled
    public List<ProductOption> productOptions { get; set; }
  }

  public class ProductOption {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }
  }

  @AuraEnabled
  public static BudgetQuoteWrapper getBudgetQuoteProducts() {
    BudgetQuoteWrapper wrapper = new BudgetQuoteWrapper();
    wrapper.productOptions = new List<ProductOption>();

    CPQ_Config__c cs = CPQ_Config__c.getOrgDefaults();
    if (cs != null && cs.Budget_Quote_Products__c != null) {
      for (Product2 product : [
        SELECT Id, Name
        FROM Product2
        WHERE ProductCode IN :cs.Budget_Quote_Products__c.split(',') AND IsActive = TRUE
        ORDER BY Category__c DESC
      ]) {
        ProductOption option = new ProductOption();
        option.label = product.Name;
        option.value = product.Id;
        wrapper.productOptions.add(option);
      }
    }

    return wrapper;
  }
}