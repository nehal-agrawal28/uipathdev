public interface IApprovalChains_PP extends fflib_ISObjects {
  List<sbaa__ApprovalChain__c> getApprovalChains();
  IApprovalChains_PP selectById(Set<Id> ids);
  IApprovalChains_PP selectNonJapan();
}