public interface IApprovalChainsSelector_PP extends fflib_ISObjectSelector {
  List<sbaa__ApprovalChain__c> selectAll();
  List<sbaa__ApprovalChain__c> selectById(Set<Id> idSet);
}