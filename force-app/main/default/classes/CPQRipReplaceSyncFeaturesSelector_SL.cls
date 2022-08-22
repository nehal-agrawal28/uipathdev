public with sharing class CPQRipReplaceSyncFeaturesSelector_SL extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      CPQ_RR_Sync_Feature__mdt.DeveloperName,
      CPQ_RR_Sync_Feature__mdt.Is_Active__c,
      CPQ_RR_Sync_Feature__mdt.Sync_Target_Object__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return CPQ_RR_Sync_Feature__mdt.SObjectType;
  }

  public List<CPQ_RR_Sync_Feature__mdt> getAll() {
    return CPQ_RR_Sync_Feature__mdt.getAll().values();
  }
}