public with sharing class QuoteSubmitForApprovalController {
  public class QuoteSubmitForApprovalWrapper {
    @AuraEnabled
    public List<MessageWrapper> errors { get; set; }
    @AuraEnabled
    public List<MessageWrapper> warnings { get; set; }
    @AuraEnabled
    public String submitPageUrl { get; set; }
  }

  public class MessageWrapper {
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public String message { get; set; }
  }

  @AuraEnabled
  public static QuoteSubmitForApprovalWrapper validateQuote(String quoteId) {
    try {
      SBQQ__Quote__c quote = [SELECT Id, General_Comments__c FROM SBQQ__Quote__c WHERE Id = :quoteId];
      QuoteSubmitForApprovalWrapper wrapper = new QuoteSubmitForApprovalWrapper();
      wrapper.errors = new List<MessageWrapper>();
      wrapper.warnings = new List<MessageWrapper>();

      // Warning - General Comments guideline
      if (String.isNotBlank(quote.General_Comments__c)) {
        MessageWrapper genCommentWarning = new MessageWrapper();
        genCommentWarning.title = 'Alert for using General Comments';
        genCommentWarning.message = 'Please note that General Comments (Special Requirements) section can include only references to the following items: Executed MSA, Customer PO number, Customer business unit/end user reference, MYD annual amounts, indication of Quote to be added on PO, legal languages provided by legal team to support certain processes (ex: Quote Cancellation Language).<br/><br/>Any wording in the Special Requirements box on the quote added without Deal Desk/Legal approval can be considered side agreement.<br/><br/>If you are not sure about the wordings being used in general comments and want them to be reviewed, please open a deal hub/legal case for help.';
        wrapper.warnings.add(genCommentWarning);
      }

      PageReference submitPage = new PageReference('/apex/SubmitQuote');
      submitPage.getParameters().put('Id', quoteId);
      wrapper.submitPageUrl = submitPage.getUrl();

      return wrapper;
    } catch (Exception e) {
      AuraHandledException ax = new AuraHandledException(e.getMessage());
      ax.setMessage(e.getMessage());
      throw ax;
    }
  }
}