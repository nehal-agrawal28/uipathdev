public without sharing class CorruptionPerceptionsIndexSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ CPI__c.Id, CPI__c.ISO3__c, CPI__c.Name, CPI__c.Score__c };
  }

  public static CorruptionPerceptionsIndexSelector_PP newInstance() {
    return (CorruptionPerceptionsIndexSelector_PP) Application_PP.Selector.newInstance(Schema.CPI__c.SObjectType);
  }

  public CorruptionPerceptionsIndexSelector_PP() {
    super(true, false, false);
  }

  public Schema.SObjectType getSObjectType() {
    return CPI__c.SObjectType;
  }

  public List<CPI__c> selectById(Set<Id> idSet) {
    return (List<CPI__c>) selectSObjectsById(idSet);
  }

  public List<CPI__c> selectByName(Set<String> names) {
    return (List<CPI__c>) Database.query(newQueryFactory().setCondition('Name IN :names').toSOQL());
  }
}