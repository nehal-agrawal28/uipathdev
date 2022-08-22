public with sharing class CPQProductManager_SL {
  public CPQModel_Quote_SL addProduct(CPQModel_Quote_SL quote, CPQModel_Product_SL[] products, Integer groupKey) {
    AddProductContext ctx = new AddProductContext(quote, products, groupKey);
    String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, JSON.serialize(ctx));
    return (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
  }

  public CPQModel_Product_SL readProduct(Id productId, Id pricebookId, String currencyCode) {
    ProductReaderContext ctx = new ProductReaderContext(pricebookId, currencyCode);
    String productJSON = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', productId, JSON.serialize(ctx));
    return (CPQModel_Product_SL) JSON.deserialize(productJSON, CPQModel_Product_SL.class);
  }

  public List<String> validate(CPQModel_Quote_SL quote) {
    String res = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteValidator', null, JSON.serialize(quote));
    return (List<String>) JSON.deserialize(res, List<String>.class);
  }

  public CPQModel_Quote_SL load(String contractId) {
    String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
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