public with sharing class AccountsSelector_SL extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Account.BillingCountry,
      Account.Id,
      Account.Name,
      Account.won_opportunities__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Account.SObjectType;
  }

  /**
   * Returns a set of account Ids that are in the same hierarchy as the list of account ids that are passed in.
   *
   * @param  accountIds  account ids that we are using to get related accounts, we are also ignoring retrieving accounts
   *                      that are already in this list
   * @param  maxRecords  the max amount of records we want to return in the query
   * @return Set<String> returns all related account Ids
   */
  public Set<String> getRelatedAccounts(Set<String> accountIds, Integer maxRecords) {
    Set<String> retrievedIds = new Set<String>();

    fflib_QueryFactory acctQF = newQueryFactory(false)
      .selectField(Account.Id)
      .selectField(Account.ParentId)
      .selectField('Parent.ParentId')
      .selectField('Parent.Parent.ParentId')
      .selectField('Parent.Parent.Parent.ParentId')
      .setCondition(
        '(ParentId IN :accountIds OR Parent.ParentId IN :accountIds OR Parent.Parent.ParentId IN :accountIds OR Parent.Parent.Parent.ParentId IN :accountIds) AND Id NOT IN :accountIds'
      )
      .setLimit(maxRecords);

    List<Account> accounts = Database.query(acctQF.toSOQL());

    for (Account account : accounts) {
      retrievedIds.add(account.Id);
      retrievedIds.add(account.ParentId);
      retrievedIds.add(account.Parent.ParentId);
      retrievedIds.add(account.Parent.Parent.ParentId);
      retrievedIds.add(account.Parent.Parent.Parent.ParentId);
    }
    // Removing any null values from the parent records. Saves us from doing a bunch of if checks
    retrievedIds.remove(null);
    return retrievedIds;
  }

  public List<Account> getAccountsWithWonOppsById(Set<Id> accountIds, Boolean enforceSecurity) {
    if (accountIds == null || accountIds.isEmpty()) {
      return new List<Account>();
    }
    fflib_QueryFactory acctQF = newQueryFactory(enforceSecurity, enforceSecurity, true);

    acctQF.setCondition('Id IN :accountIds AND won_opportunities__c > 0');
    return Database.query(acctQF.toSOQL());
  }
}