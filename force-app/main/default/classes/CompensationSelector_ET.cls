public without sharing class CompensationSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Default_Compensation__mdt.ID,
      Default_Compensation__mdt.MasterLabel,
      Default_Compensation__mdt.DeveloperName,
      Default_Compensation__mdt.Default_Percentage__c,
      Default_Compensation__mdt.Role_In_Territory__c,
      Default_Compensation__mdt.Status__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Default_Compensation__mdt.sObjectType;
  }

  public List<Default_Compensation__mdt> selectAll() {
    return (List<Default_Compensation__mdt>) Database.query(newQueryFactory(false, false, true).toSOQL());
  }
}