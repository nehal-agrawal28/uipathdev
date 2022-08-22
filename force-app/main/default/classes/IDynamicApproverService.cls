public interface IDynamicApproverService {
  List<SBQQ__Quote__c> populateDynamicApprovers(List<Id> quoteIdList);
  SBQQ__Quote__c populateDynamicApprover(Id quoteId);
}