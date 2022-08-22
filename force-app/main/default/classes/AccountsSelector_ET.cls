public without sharing class AccountsSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Account.Id,
      Account.Name,
      Account.ParentId,
      Account.BillingCountryCode,
      Account.BillingPostalCode,
      Account.Ultimate_Parent_Id__c,
      Account.Is_Domestic_Child__c,
      Account.Territory_Postal_Code_Mapping__c,
      Account.Named_List_Assignment__c,
      Account.Parent_Territory_Override__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Account.sObjectType;
  }

  public List<Account> selectById(Set<Id> ids) {
    return (List<Account>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('OwnerId')
        .selectField('Owner.Email')
        .selectField('Owner.Name')
        .selectField('Geo__c')
        .selectField('Name')
        .selectField('CSM__r.Name')
        .selectField('Classification__c')
        .selectField('Billing_Postal_Code_Static__c')
        .selectField('Billing_Country_Code_Static__c')
        .selectField('Billing_State_Code_Static__c')
        .selectField('Partner_Named_List_Assignment__c')
        .setCondition('Id IN :ids')
        .toSOQL()
    );
  }

  public List<Account> selectByUltimateParentId(Set<String> ids) {
    return (List<Account>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Owner.Email')
        .selectField('Classification__c')
        .selectField('Parent_Territory_Override__c')
        .setCondition('Ultimate_Parent_Id__c IN :ids')
        .toSOQL()
    );
  }
}