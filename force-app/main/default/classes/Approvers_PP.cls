public inherited sharing class Approvers_PP extends fflib_SObjects2 implements IApprovers_PP {
  public static IApprovers_PP newInstance(List<sbaa__Approver__c> records) {
    return (IApprovers_PP) Application_PP.Domain.newInstance(records, Schema.sbaa__Approver__c.SObjectType);
  }

  public static IApprovers_PP newInstance(Set<Id> ids) {
    return (IApprovers_PP) Application_PP.Domain.newInstance(ids, Schema.sbaa__Approver__c.SObjectType);
  }

  public Approvers_PP(List<sbaa__Approver__c> records) {
    super(records, Schema.sbaa__Approver__c.SObjectType);
  }

  public List<sbaa__Approver__c> getApprovers() {
    return (List<sbaa__Approver__c>) getRecords();
  }

  public Set<Id> getGroupIds() {
    return getIdFieldValues(sbaa__Approver__c.sbaa__GroupId__c).getIds();
  }

  public Set<Id> getUserIds() {
    return getIdFieldValues(sbaa__Approver__c.sbaa__User__c).getIds();
  }

  public IApprovers_PP selectById(Set<Id> ids) {
    return new Approvers_PP(getRecords(ids));
  }

  private IApprovers_PP selectBy(fflib_Criteria criteria) {
    return new Approvers_PP(getRecords(criteria));
  }

  private IApprovers_PP selectBlank(Schema.SObjectField sObjectField) {
    List<sbaa__Approver__c> result = new List<sbaa__Approver__c>();
    for (sbaa__Approver__c record : getApprovers()) {
      if (String.isNotBlank((String) record.get(sObjectField)))
        continue;

      result.add(record);
    }
    return new Approvers_PP(result);
  }

  private IApprovers_PP selectNonBlank(Schema.SObjectField sObjectField) {
    List<sbaa__Approver__c> result = new List<sbaa__Approver__c>();
    for (sbaa__Approver__c record : getApprovers()) {
      if (String.isBlank((String) record.get(sObjectField)))
        continue;

      result.add(record);
    }
    return new Approvers_PP(result);
  }

  private IApprovers_PP selectNull(Schema.SObjectField sObjectField) {
    List<sbaa__Approver__c> result = new List<sbaa__Approver__c>();
    for (sbaa__Approver__c record : getApprovers()) {
      if (record.get(sObjectField) != null)
        continue;

      result.add(record);
    }
    return new Approvers_PP(result);
  }

  private IApprovers_PP selectWith(Schema.SObjectField sObjectField) {
    List<sbaa__Approver__c> result = new List<sbaa__Approver__c>();
    for (sbaa__Approver__c record : getApprovers()) {
      if (record.get(sObjectField) == null)
        continue;

      result.add(record);
    }
    return new Approvers_PP(result);
  }

  private IApprovers_PP selectWithout(Schema.SObjectField sObjectField) {
    List<sbaa__Approver__c> result = new List<sbaa__Approver__c>();
    for (sbaa__Approver__c record : getApprovers()) {
      if (record.get(sObjectField) != null)
        continue;

      result.add(record);
    }
    return new Approvers_PP(result);
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_SObjects construct(List<Object> records) {
      return new Approvers_PP((List<SObject>) records);
    }
  }
}