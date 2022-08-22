/**
 * Sets Learning Alliance Partner Type on Account level should be set to Academic Alliance if
 * Learning Alliance agreement is checked by system automatically on account level. Change made by system, not user.
 */
public with sharing class AccountAlliancePartnerTypeFunction implements SObjectToSObjectFunction {
  private Id integrationUserId;

  public AccountAlliancePartnerTypeFunction(List<Account> allAccounts) {
    if (Test.isRunningTest()) {
      integrationUserId = UserInfo.getUserId();
    } else {
      User[] intUsers = [SELECT Id FROM User WHERE Name = 'UiPath' AND Alias = 'iuipa' LIMIT 1];
      integrationUserId = intUsers.size() > 0 ? intUsers[0].Id : UserInfo.getUserId();
    }
  }

  public SObject apply(Account acc) {
    if (acc.Academic_Alliance_Agreement__c == true && integrationUserId == UserInfo.getUserId()) {
      acc.Learning_Alliance_Partner_Type__c = 'Academic Alliance';
    }
    return acc;
  }

  public SObject apply(SObject record) {
    return apply((Account) record);
  }

  /**
   * On Account Insert, sets Learning Alliance Partner Type = Academic Alliance if Academic Alliance Agreement = true
   */
  public static void setAlliancePartnerTypeOnInsert(List<Account> records) {
    List<Account> changedAccounts = Collection.of(records)
      .filter(
        Match.field(Account.Academic_Alliance_Agreement__c)
          .hasValue()
          .also(Account.Academic_Alliance_Agreement__c)
          .equals(true)
      )
      .asList();

    Collection.of(changedAccounts).mapAll(new AccountAlliancePartnerTypeFunction(changedAccounts));
  }

  /**
   * On Account Update, sets Learning Alliance Partner Type = Academic Alliance if Academic Alliance Agreement = true
   */
  public static void setAlliancePartnerTypeOnUpdate(List<Account> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasAgreementChanged = new HasRecordChanged(
      new Set<SObjectField>{ Account.Academic_Alliance_Agreement__c },
      records,
      existingRecords
    );

    List<Account> changedAccounts = Collection.of(records)
      .filter(hasAgreementChanged)
      .filter(Match.field(Account.Academic_Alliance_Agreement__c).equals(true))
      .asList();

    if (!changedAccounts.isEmpty()) {
      Collection.of(changedAccounts).mapAll(new AccountAlliancePartnerTypeFunction(changedAccounts));
    }
  }
}