public with sharing class CPQServiceRouter_SL {
  public CPQModel_Quote_SL addProductsToQuote(
    CPQModel_Quote_SL quote,
    CPQModel_Product_SL[] products,
    Integer groupKey
  ) {
    AddProductContext ctx = new AddProductContext(quote, products, groupKey);
    String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, JSON.serialize(ctx));
    //    System.debug(quoteJSON);
    return (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
  }

  public CPQModel_Product_SL loadProductModel(Id productId, Id pricebookId, String currencyCode) {
    ProductReaderContext ctx = new ProductReaderContext(pricebookId, currencyCode);
    String productJSON = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', productId, JSON.serialize(ctx));
    //    System.debug('productJSON:    ' + productJSON);
    return (CPQModel_Product_SL) JSON.deserialize(productJSON, CPQModel_Product_SL.class);
  }

  public static CPQModel_Product_SL setOptionsConfigured(CPQModel_Product_SL productModel) {
    if (productModel.configuration != null) {
      productModel.configuration.configured = true;
      productModel.configuration.configurationEntered = true;
      for (CPQModel_Configuration_SL nestedModel : productModel.configuration.optionConfigurations) {
        nestedModel.configured = true;
        nestedModel.configurationEntered = true;
      }
      return productModel;
    } else {
      return productModel;
    }
  }

  public List<String> validate(CPQModel_Quote_SL quote) {
    String res = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteValidator', null, JSON.serialize(quote));
    return (List<String>) JSON.deserialize(res, List<String>.class);
  }

  public CPQModel_Quote_SL loadContract(String contractId) {
    String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
    return (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
  }

  public CPQModel_Quote_SL readQuote(String quoteId) {
    String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
    return (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
  }

  public CPQModel_Quote_SL saveQuote(CPQModel_Quote_SL quote) {
    String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
    return (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
  }

  public class AddProductContext {
    public CPQModel_Quote_SL quote;
    public CPQModel_Product_SL[] products;
    public Integer groupKey;
    public final Boolean ignoreCalculate = true; //Must be hardcoded to true

    public AddProductContext(CPQModel_Quote_SL quote, CPQModel_Product_SL[] products, Integer groupKey) {
      this.quote = quote;
      this.products = products;
      this.groupKey = groupKey;
    }
  }

  public class ProductReaderContext {
    public Id pricebookId;
    public String currencyCode;
    public ProductReaderContext(Id pricebookId, String currencyCode) {
      this.pricebookId = pricebookId;
      this.currencyCode = currencyCode;
    }
  }
}