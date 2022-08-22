global with sharing class CPQQuoteCalculator_SL implements SBQQ.CalculateCallback {
  public CPQModel_Quote_SL calculate(CPQModel_Quote_SL quote) {
    QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote);
    String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));
    return (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
  }
  public CPQModel_Quote_SL read(String quoteId) {
    String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
    return (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
  }

  public CPQModel_Quote_SL save(CPQModel_Quote_SL quote) {
    String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
    return (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
  }

  public void calculate(CPQModel_Quote_SL quote, String callbackClass) {
    QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote, callbackClass);
    SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));
  }

  public with sharing class QuoteCalculatorContext {
    public CPQModel_Quote_SL quote;
    public String callbackClass;
    public QuoteCalculatorContext(CPQModel_Quote_SL quote, String callbackClass) {
      this.quote = quote;
      this.callbackClass = callbackClass;
    }

    public QuoteCalculatorContext(CPQModel_Quote_SL quote) {
      this.quote = quote;
      this.callbackClass = null;
    }
  }

  global void callback(String quote) {
    // save the quote
    SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quote);
    System.debug(LoggingLevel.INFO, 'CPQQuoteCalculator_SL:callback executed');
  }
}