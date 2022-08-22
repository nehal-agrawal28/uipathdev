public inherited sharing class ApprovalChains_PP extends fflib_SObjects2 implements IApprovalChains_PP {
  public static IApprovalChains_PP newInstance(List<sbaa__ApprovalChain__c> records) {
    return (IApprovalChains_PP) Application_PP.Domain.newInstance(records, Schema.sbaa__ApprovalChain__c.SObjectType);
  }

  public static IApprovalChains_PP newInstance(Set<Id> ids) {
    return (IApprovalChains_PP) Application_PP.Domain.newInstance(ids, Schema.sbaa__ApprovalChain__c.SObjectType);
  }

  public ApprovalChains_PP(List<sbaa__ApprovalChain__c> records) {
    super(records, Schema.sbaa__ApprovalChain__c.SObjectType);
  }

  public List<sbaa__ApprovalChain__c> getApprovalChains() {
    return (List<sbaa__ApprovalChain__c>) getRecords();
  }

  public IApprovalChains_PP selectById(Set<Id> ids) {
    return new ApprovalChains_PP(getRecords(ids));
  }

  public IApprovalChains_PP selectNonJapan() {
    List<sbaa__ApprovalChain__c> result = new List<sbaa__ApprovalChain__c>();
    for (sbaa__ApprovalChain__c record : getApprovalChains()) {
      if (record.Name == null || record.Name.containsIgnoreCase('Japan'))
        continue;

      result.add(record);
    }
    return new ApprovalChains_PP(result);
  }

  private IApprovalChains_PP selectBy(fflib_Criteria criteria) {
    return new ApprovalChains_PP(getRecords(criteria));
  }

  private IApprovalChains_PP selectBlank(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalChain__c> result = new List<sbaa__ApprovalChain__c>();
    for (sbaa__ApprovalChain__c record : getApprovalChains()) {
      if (String.isNotBlank((String) record.get(sObjectField)))
        continue;

      result.add(record);
    }
    return new ApprovalChains_PP(result);
  }

  private IApprovalChains_PP selectNonBlank(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalChain__c> result = new List<sbaa__ApprovalChain__c>();
    for (sbaa__ApprovalChain__c record : getApprovalChains()) {
      if (String.isBlank((String) record.get(sObjectField)))
        continue;

      result.add(record);
    }
    return new ApprovalChains_PP(result);
  }

  private IApprovalChains_PP selectNull(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalChain__c> result = new List<sbaa__ApprovalChain__c>();
    for (sbaa__ApprovalChain__c record : getApprovalChains()) {
      if (record.get(sObjectField) != null)
        continue;

      result.add(record);
    }
    return new ApprovalChains_PP(result);
  }

  private IApprovalChains_PP selectWith(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalChain__c> result = new List<sbaa__ApprovalChain__c>();
    for (sbaa__ApprovalChain__c record : getApprovalChains()) {
      if (record.get(sObjectField) == null)
        continue;

      result.add(record);
    }
    return new ApprovalChains_PP(result);
  }

  private IApprovalChains_PP selectWithout(Schema.SObjectField sObjectField) {
    List<sbaa__ApprovalChain__c> result = new List<sbaa__ApprovalChain__c>();
    for (sbaa__ApprovalChain__c record : getApprovalChains()) {
      if (record.get(sObjectField) != null)
        continue;

      result.add(record);
    }
    return new ApprovalChains_PP(result);
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_SObjects construct(List<Object> records) {
      return new ApprovalChains_PP((List<SObject>) records);
    }
  }
}