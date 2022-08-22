public inherited sharing class ApprovalRules_PP extends fflib_SObjects2 implements IApprovalRules_PP {
  public static IApprovalRules_PP newInstance(List<sbaa__ApprovalRule__c> records) {
    return (IApprovalRules_PP) Application_PP.Domain.newInstance(records, Schema.sbaa__ApprovalRule__c.SObjectType);
  }

  public static IApprovalRules_PP newInstance(Set<Id> ids) {
    return (IApprovalRules_PP) Application_PP.Domain.newInstance(ids, Schema.sbaa__ApprovalRule__c.SObjectType);
  }

  public ApprovalRules_PP(List<sbaa__ApprovalRule__c> records) {
    super(records, Schema.sbaa__ApprovalRule__c.SObjectType);
  }

  public Set<Id> getApproverIds() {
    return getIdFieldValues(sbaa__ApprovalRule__c.sbaa__Approver__c).getIds();
  }

  public List<sbaa__ApprovalRule__c> getApprovalRules_PP() {
    return (List<sbaa__ApprovalRule__c>) getRecords();
  }

  public IApprovalRules_PP selectById(Set<Id> ids) {
    return new ApprovalRules_PP(getRecords(ids));
  }

  private IApprovalRules_PP selectBy(fflib_Criteria criteria) {
    return new ApprovalRules_PP(getRecords(criteria));
  }

  private IApprovalRules_PP selectBlank(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalRule__c> result = new List<sbaa__ApprovalRule__c>();
    for (sbaa__ApprovalRule__c record : getApprovalRules_PP()) {
      if (String.isNotBlank((String) record.get(sObjectField)))
        continue;

      result.add(record);
    }
    return new ApprovalRules_PP(result);
  }

  private IApprovalRules_PP selectNonBlank(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalRule__c> result = new List<sbaa__ApprovalRule__c>();
    for (sbaa__ApprovalRule__c record : getApprovalRules_PP()) {
      if (String.isBlank((String) record.get(sObjectField)))
        continue;

      result.add(record);
    }
    return new ApprovalRules_PP(result);
  }

  private IApprovalRules_PP selectNull(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalRule__c> result = new List<sbaa__ApprovalRule__c>();
    for (sbaa__ApprovalRule__c record : getApprovalRules_PP()) {
      if (record.get(sObjectField) != null)
        continue;

      result.add(record);
    }
    return new ApprovalRules_PP(result);
  }

  private IApprovalRules_PP selectWith(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalRule__c> result = new List<sbaa__ApprovalRule__c>();
    for (sbaa__ApprovalRule__c record : getApprovalRules_PP()) {
      if (record.get(sObjectField) == null)
        continue;

      result.add(record);
    }
    return new ApprovalRules_PP(result);
  }

  private IApprovalRules_PP selectWithout(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalRule__c> result = new List<sbaa__ApprovalRule__c>();
    for (sbaa__ApprovalRule__c record : getApprovalRules_PP()) {
      if (record.get(sObjectField) != null)
        continue;

      result.add(record);
    }
    return new ApprovalRules_PP(result);
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_SObjects construct(List<Object> records) {
      return new ApprovalRules_PP((List<SObject>) records);
    }
  }
}