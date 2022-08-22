public class CorruptionPerceptionsIndexes_PP extends fflib_SObjects {
  public CorruptionPerceptionsIndexes_PP(List<CPI__c> records) {
    super(records, Schema.CPI__c.SObjectType);
  }

  public static CorruptionPerceptionsIndexes_PP newInstance(List<CPI__c> records) {
    return (CorruptionPerceptionsIndexes_PP) Application_PP.Domain.newInstance(records, Schema.CPI__c.SObjectType);
  }

  public Map<String, Integer> getScoreByName() {
    Map<String, Integer> result = new Map<String, Integer>();
    for (CPI__c record : (List<CPI__c>) getRecords()) {
      result.put(record.Name, Integer.valueOf(record.Score__c));
    }
    return result;
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_IDomain construct(List<Object> objects) {
      return new CorruptionPerceptionsIndexes_PP((List<SObject>) objects);
    }
  }
}