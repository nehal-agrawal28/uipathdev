public with sharing class AccountSetLegalComplianceFunction implements SObjectToSObjectFunction {
  /**
   * Set Legal_Compliance_Status__c = 'Restricted'
   * if Country = Zimbabwe and Industry= 'Public Sector'
   */
  public SObject apply(Account acc) {
    if ((acc.Country__c == 'Zimbabwe' || acc.BillingCountryCode == 'ZW') && acc.Industry == 'Public Sector') {
      acc.Legal_Compliance_Status__c = 'Restricted';
    }

    return acc;
  }

  public SObject apply(SObject record) {
    return apply((Account) record);
  }

  /**
   * On Account Insert, Sets Legal_Compliance_Status__c to 'Restricted' based on Account Country and Industry
   */
  public static void setStatusOnInsert(List<Account> records) {
    Collection.of(records).mapAll(new AccountSetLegalComplianceFunction());
  }

  /**
   * On Account Update, Sets Legal_Compliance_Status__c to 'Restricted' based on Account Country and Industry
   */
  public static void setStatusOnUpdate(List<Account> accounts, Map<Id, SObject> existingAccounts) {
    SObjectPredicate haveFieldsChanged = new HasRecordChanged(
      new Set<SObjectField>{ Account.Industry, Account.Country__c, Account.BillingCountryCode },
      accounts,
      existingAccounts
    );

    Collection.of(accounts).filter(haveFieldsChanged).mapAll(new AccountSetLegalComplianceFunction());
  }
}