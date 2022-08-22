public interface IQuoteService_SL {
  Map<Id, SBQQ__Quote__c> syncFieldOnCancelledQuotes(Set<Id> replacementQuoteIds, SObjectField field);
  SBQQ__Quote__c createQuoteForOpportunity(Date startDate, Date endDate, Id opportunityId);
  SBQQ__Quote__c createQuoteForOpportunity(
    Date startDate,
    Date endDate,
    Id opportunityId,
    Boolean replacementTransaction
  );
  void quoteUpdater(Id quoteId);
  void addProductsToQuote(Id quoteId, List<Id> productIds, Double targetCustomerAmount);
  void addPackageWithOptions(Id quoteId, Id packageProductId, List<Id> optionProductIds, Double targetCustomerAmount);
}