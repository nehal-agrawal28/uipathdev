/**
 * Contract fflib selector layer
 */
public with sharing class ContractsSelector_SL extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Contract.AccountId,
      Contract.ActivatedDate,
      Contract.ARR_to_Renew__c,
      Contract.Billing_Frequency__c,
      Contract.EndDate,
      Contract.Deal_Type__c,
      Contract.SBQQ__Quote__c,
      Contract.SBQQ__RenewalForecast__c,
      Contract.SBQQ__RenewalQuoted__c,
      Contract.SBQQ__RenewalUpliftRate__c,
      Contract.Status,
      Contract.StartDate
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Contract.SObjectType;
  }

  public List<Contract> selectById(Set<Id> ids, Boolean enforceSecurity) {
    if (enforceSecurity) {
      return (List<Contract>) selectSObjectsById(ids);
    } else {
      return (List<Contract>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
    }
  }

  public List<Contract> selectContractsForUplift(Set<Id> idSet) {
    return Database.query(
      newQueryFactory(true)
        .selectField('ARR_to_Renew_USD__c')
        .selectField('Account.SBQQ__RenewalPricingMethod__c')
        .selectField('Account.Geo__c')
        .selectField('Account.Area__c')
        .selectField('SBQQ__Opportunity__r.Deal_Type__c')
        .selectField('SBQQ__Opportunity__r.Sold_to_Partner__c')
        .setCondition('id in :idSet')
        .toSOQL()
    );
  }

  //TODO convert to idiomatic fflib Selector
  /**
   * Returns a list of contracts that are related to a giving account
   *
   * @param  accountIds the accounts that the contracts are related to
   * @param amountOfRecords Can pass a specific amount of records to get, or pass 'All'.
   * @return List<Contract> a list of contracts linked to an account
   */
  public List<Contract> getActiveContractsByAccount(List<String> accountIds, String amountOfRecords) {
    String query = 'SELECT Id, AccountId, Account.Name, ContractNumber, StartDate, EndDate, ContractTerm';
    query += ' FROM Contract';
    query += ' WHERE Status = \'Activated\' AND AccountId in :accountIds AND EndDate > TODAY';
    query += ' WITH SECURITY_ENFORCED';
    // Only going to use amountOfRecords if it is numeric, if its not we are assuming we want all records returned
    if (String.isNotBlank(amountOfRecords) && amountOfRecords.isNumeric()) {
      query += ' LIMIT ' + integer.valueof(amountOfRecords);
    }

    System.debug('getActiveContractsByAccount:' + amountOfRecords);

    return (List<Contract>) Database.query(query);
  }
}