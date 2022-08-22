public with sharing class TerritoryPostalCodeMappingsSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Territory_Postal_Code_Mapping__c.Postal_Code__c,
      Territory_Postal_Code_Mapping__c.Territory_1__c,
      Territory_Postal_Code_Mapping__c.Territory_2__c,
      Territory_Postal_Code_Mapping__c.External_Id__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Territory_Postal_Code_Mapping__c.sObjectType;
  }

  public List<Territory_Postal_Code_Mapping__c> selectById(Set<Id> ids, Boolean withSharing) {
    return (List<Territory_Postal_Code_Mapping__c>) Database.query(
      newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
    );
  }

  public List<Territory_Postal_Code_Mapping__c> selectByPostalCode(Set<String> postalCodes) {
    return (List<Territory_Postal_Code_Mapping__c>) Database.query(
      newQueryFactory(false, false, true).setCondition('External_Id__c  in: postalCodes').toSOQL()
    );
  }

  public Map<String, Territory_Postal_Code_Mapping__c> selectMapByPostalCode(Set<String> postalCodes) {
    List<Territory_Postal_Code_Mapping__c> terrPostalcodeList = selectByPostalCode(postalCodes);
    Map<String, Territory_Postal_Code_Mapping__c> postalCodeTerrMapping = new Map<String, Territory_Postal_Code_Mapping__c>();
    for (Territory_Postal_Code_Mapping__c postalCodeMapping : terrPostalcodeList) {
      postalCodeTerrMapping.put(postalCodeMapping.External_Id__c, postalCodeMapping);
    }
    return postalCodeTerrMapping;
  }
}