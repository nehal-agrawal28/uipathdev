public class Accounts_PP extends fflib_SObjects {
  public Accounts_PP(List<Account> records) {
    super(records, Schema.Account.SObjectType);
  }

  public static Accounts_PP newInstance(List<SObject> records) {
    return (Accounts_PP) Application_PP.Domain.newInstance(records, Schema.Account.SObjectType);
  }

  public List<Account> getAccounts() {
    return (List<Account>) getRecords();
  }

  public Map<Id, String> getBillingCountryById() {
    Map<Id, String> result = new Map<Id, String>();
    for (Account record : getAccounts()) {
      result.put(record.Id, record.BillingCountry);
    }
    return result;
  }

  public Accounts_PP selectByBuysThroughDistributor() {
    List<Account> result = new List<Account>();
    for (Account record : getAccounts()) {
      if (record.Partner_Buys_Through_Disti__c) {
        result.add(record);
      }
    }
    return new Accounts_PP(result);
  }

  public Accounts_PP selectByDateJoinedProgramOlderThanYears(Integer numberOfYears) {
    Date yearsOld = System.today().addYears(numberOfYears * -1);

    List<Account> result = new List<Account>();
    for (Account record : getAccounts()) {
      if (record.Date_Joined_Program__c < yearsOld) {
        result.add(record);
      }
    }
    return new Accounts_PP(result);
  }

  public Accounts_PP setPartnerContributingStatus(String status) {
    for (Account record : getAccounts()) {
      record.PartnerContributingStatus__c = status;
    }
    return this;
  }

  public Accounts_PP setPartnerBuysThroughDisti(Boolean buysThroughDisti) {
    for (Account record : getAccounts()) {
      record.Partner_Buys_Through_Disti__c = buysThroughDisti;
    }
    return this;
  }

  public Accounts_PP setAccountRtype(Id recordTypeId) {
    for (Account record : getAccounts()) {
      record.recordTypeId = recordTypeId;
    }
    return this;
  }

  public Accounts_PP setAccountPartnerApplicationForm(Id pafId) {
    for (Account record : getAccounts()) {
      record.Partner_Application_Form__c = pafId;
    }
    return this;
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_IDomain construct(List<Object> objects) {
      return new Accounts_PP((List<SObject>) objects);
    }
  }
}