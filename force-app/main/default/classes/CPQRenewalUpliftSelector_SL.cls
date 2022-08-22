public with sharing class CPQRenewalUpliftSelector_SL extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ CPQ_Renewal_Uplift__mdt.DeveloperName };
  }

  public Schema.SObjectType getSObjectType() {
    return CPQ_Renewal_Uplift__mdt.SObjectType;
  }

  public List<CPQ_Renewal_Uplift__mdt> getAll() {
    return CPQ_Renewal_Uplift__mdt.getAll().values();
  }
}