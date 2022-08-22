public class Contacts_PP extends fflib_SObjects {
  public Contacts_PP(List<Contact> records) {
    super(records, Schema.Contact.SObjectType);
  }

  public static Contacts_PP newInstance(List<Contact> records) {
    return (Contacts_PP) Application_PP.Domain.newInstance(records, Schema.Contact.SObjectType);
  }

  public Map<Id, Id> getAccountIdById() {
    Map<Id, Id> result = new Map<Id, Id>();
    return result;
  }

  public List<Contact> getContacts() {
    return getRecords();
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_IDomain construct(List<Object> objects) {
      return new Contacts_PP((List<SObject>) objects);
    }
  }
}