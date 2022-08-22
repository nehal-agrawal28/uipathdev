public without sharing class AccountRelatedEmailDomains_PP extends fflib_SObjectDomain {

  public AccountRelatedEmailDomains_PP(List<AccountRelatedEmailDomain__c> records) {
    super(records, AccountRelatedEmailDomain__c.SObjectType);

    Configuration.disableTriggerCRUDSecurity();
  }
  public override void onBeforeInsert() {
    updateUniqueId();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    onChangedAccountDomain().updateUniqueId();
  }

  public AccountRelatedEmailDomains_PP onChangedAccountDomain() {
    Set<Schema.SObjectField> changedFields = new Set<Schema.SObjectField>{
      AccountRelatedEmailDomain__c.Account__c,
      AccountRelatedEmailDomain__c.EmailDomain__c
    };
    List<AccountRelatedEmailDomain__c> result = (List<AccountRelatedEmailDomain__c>) getChangedRecords(changedFields);
    return new AccountRelatedEmailDomains_PP(result);
  }

  public void updateUniqueId() {
    for (AccountRelatedEmailDomain__c accRelatedDomain : (List<AccountRelatedEmailDomain__c>) getRecords()) {
      if (accRelatedDomain.Account__c == null || accRelatedDomain.EmailDomain__c == null)
        continue;

      accRelatedDomain.Account_Domain_Unique_Id__c =
        accRelatedDomain.Account__c.to15() +
        '' +
        accRelatedDomain.EmailDomain__c.to15();
    }
  }

  public Map<Id, AccountRelatedEmailDomain__c> getAccountRelatedEmailDomainByDomainId() {
    Map<Id, AccountRelatedEmailDomain__c> result = new Map<Id, AccountRelatedEmailDomain__c>();
    for (AccountRelatedEmailDomain__c record : (List<AccountRelatedEmailDomain__c>) getRecords()) {
      result.put(record.EmailDomain__c, record);
    }
    return result;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new AccountRelatedEmailDomains_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new AccountRelatedEmailDomains_PP(sObjectList);
    }
  }
}