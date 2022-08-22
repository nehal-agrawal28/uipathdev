public interface IApprovers_PP extends fflib_ISObjects {
  List<sbaa__Approver__c> getApprovers();
  Set<Id> getGroupIds();
  Set<Id> getUserIds();

  IApprovers_PP selectById(Set<Id> ids);
}