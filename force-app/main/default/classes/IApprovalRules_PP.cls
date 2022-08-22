public interface IApprovalRules_PP extends fflib_ISObjects {
  Set<Id> getApproverIds();
  List<sbaa__ApprovalRule__c> getApprovalRules_PP();
  IApprovalRules_PP selectById(Set<Id> ids);
}