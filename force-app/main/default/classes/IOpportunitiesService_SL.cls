public interface IOpportunitiesService_SL {
  Opportunity createOpportunity(
    String accountId,
    String opportunityName,
    String stageName,
    String dealType,
    Date startDate,
    String currencyCode,
    String soldToPartnerId
  );
  Opportunity createOpportunity(
    String accountId,
    String opportunityName,
    String stageName,
    String dealType,
    Date startDate,
    String currencyCode,
    String soldToPartnerId,
    Boolean replacementTransaction
  );
  Opportunity createOpportunity(
    String accountId,
    String opportunityName,
    String stageName,
    String dealType,
    Date startDate,
    String currencyCode,
    String soldToPartnerId,
    Boolean replacementTransaction,
    String opportunityOwnerId
  );
  List<PicklistMsg_CM> getStageNamePicklistValues();
  List<PicklistMsg_CM> getDealTypePicklistValues();
  List<PicklistMsg_CM> getCurrencyPicklistValues();
  List<Opportunity> syncFieldOnCancelledOpps(Set<Id> replacementOppIds, SObjectField field);
}