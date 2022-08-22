public class Cases_PP extends fflib_SObjects {
  public Cases_PP(List<Case> records) {
    super(records, Schema.Case.SObjectType);
  }

  public static Cases_PP newInstance(List<Case> records) {
    return (Cases_PP) Application_PP.Domain.newInstance(records, Schema.Case.SObjectType);
  }

  public Set<Id> getAccountIds() {
    Set<Id> result = new Set<Id>();
    for (Case record : getCases()) {
      if (record.AccountId == null)
        continue;

      result.add(record.AccountId);
    }
    return result;
  }

  public List<Case> getCases() {
    return (List<Case>) getRecords();
  }

  public Cases_PP selectByDocumentType(Set<String> documentTypes) {
    List<Case> result = new List<Case>();
    for (Case record : getCases()) {
      if (documentTypes.contains(record.Document_Type__c) == false)
        continue;

      result.add(record);
    }
    return new Cases_PP(result);
  }

  public Cases_PP selectByRecordTypeId(Set<Id> recordTypeIds) {
    List<Case> result = new List<Case>();
    for (Case record : getCases()) {
      if (recordTypeIds.contains(record.RecordTypeId) == false)
        continue;

      result.add(record);
    }
    return new Cases_PP(result);
  }

  public Cases_PP selectByStatus(Set<String> values) {
    List<Case> result = new List<Case>();
    for (Case record : getCases()) {
      if (values.contains(record.Status) == false)
        continue;

      result.add(record);
    }
    return new Cases_PP(result);
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_IDomain construct(List<Object> objects) {
      return new Cases_PP((List<SObject>) objects);
    }
  }
}