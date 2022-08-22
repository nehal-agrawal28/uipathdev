public inherited sharing class DefaultApplicationManagers_PP extends fflib_SObjectDomain implements IDefaultApplicationManagers_PP {
  public static IDefaultApplicationManagers_PP newInstance(List<Default_Application_Manager_PP__mdt> records) {
    return (IDefaultApplicationManagers_PP) Application_PP.Domain.newInstance(
      records,
      Schema.Default_Application_Manager_PP__mdt.SObjectType
    );
  }

  public static IDefaultApplicationManagers_PP newInstance(Set<Id> ids) {
    return (IDefaultApplicationManagers_PP) Application_PP.Domain.newInstance(ids);
  }

  public DefaultApplicationManagers_PP(List<Default_Application_Manager_PP__mdt> records) {
    super(records, Schema.Default_Application_Manager_PP__mdt.SObjectType);
  }

  public Map<String, Id> getManagerIdByCountry() {
    return getIdFieldByStringField(
      Schema.Default_Application_Manager_PP__mdt.Manager__c,
      Schema.Default_Application_Manager_PP__mdt.Country__c
    );
  }

  public List<Default_Application_Manager_PP__mdt> getDefaultApplicationManagers() {
    return (List<Default_Application_Manager_PP__mdt>) getRecords();
  }

  // todo - remove this method when fflib-apex-extensions is installed
  private Map<String, Id> getIdFieldByStringField(Schema.SObjectField valueField, Schema.SObjectField keyField) {
    Map<String, Id> result = new Map<String, Id>();
    for (SObject record : getRecords()) {
      if (record.get(keyField) == null)
        continue;

      result.put((String) record.get(keyField), (Id) record.get(valueField));
    }
    return result;
  }

  // todo - remove this method when fflib-apex-extensions is installed
  private Map<Object, Object> getFieldByField(Schema.SObjectField valueField, Schema.SObjectField keyField) {
    Map<Object, Object> result = new Map<Object, Object>();
    for (SObject record : getRecords()) {
      if (record.get(keyField) == null)
        continue;

      result.put(record.get(keyField), record.get(valueField));
    }
    return result;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new DefaultApplicationManagers_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new DefaultApplicationManagers_PP(sObjectList);
    }
  }
}