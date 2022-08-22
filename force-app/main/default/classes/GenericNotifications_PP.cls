/**
 * File Name: GenericNotifications_PP
 */
public class GenericNotifications_PP extends fflib_SObjects {
  public GenericNotifications_PP(List<GenericNotification_PP__c> records) {
    super(records, Schema.GenericNotification_PP__c.SObjectType);
  }

  public static GenericNotifications_PP newInstance(List<GenericNotification_PP__c> records) {
    return (GenericNotifications_PP) Application_PP.Domain.newInstance(
      records,
      Schema.GenericNotification_PP__c.SObjectType
    );
  }

  public static GenericNotifications_PP newInstance(Set<Id> recordIds) {
    return (GenericNotifications_PP) Application_PP.Domain.newInstance(recordIds);
  }

  public Map<Id, String> getEmailByAccountId() {
    Map<Id, String> result = new Map<Id, String>();
    for (GenericNotification_PP__c record : getGenericNotification()) {
      result.put(record.Account__c, record.Email__c);
    }
    return result;
  }

  public List<GenericNotification_PP__c> getGenericNotification() {
    return (List<GenericNotification_PP__c>) getRecords();
  }

  public GenericNotifications_PP selectByAccountId(Id id) {
    List<GenericNotification_PP__c> result = new List<GenericNotification_PP__c>();
    for (GenericNotification_PP__c record : getGenericNotification()) {
      if (record.Account__c == id) {
        result.add(record);
      }
    }
    return new GenericNotifications_PP(result);
  }

  public GenericNotifications_PP setAccountId(Id id) {
    for (GenericNotification_PP__c record : getGenericNotification()) {
      record.Account__c = id;
    }
    return this;
  }

  public GenericNotifications_PP setEmail(String email) {
    for (GenericNotification_PP__c record : getGenericNotification()) {
      record.Email__c = email;
    }
    return this;
  }

  public GenericNotifications_PP setType(String type) {
    for (GenericNotification_PP__c record : getGenericNotification()) {
      record.Type__c = type;
    }
    return this;
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_IDomain construct(List<Object> objects) {
      return new GenericNotifications_PP((List<SObject>) objects);
    }
  }
}