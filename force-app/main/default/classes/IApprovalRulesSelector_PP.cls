public interface IApprovalRulesSelector_PP extends fflib_ISObjectSelector {
  List<sbaa__ApprovalRule__c> selectById(Set<Id> idSet);

  List<sbaa__ApprovalRule__c> selectByChainId(Set<Id> chainIds);
}