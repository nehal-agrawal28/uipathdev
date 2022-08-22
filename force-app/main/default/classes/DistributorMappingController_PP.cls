public without sharing class DistributorMappingController_PP {
  @InvocableMethod(label='Convert CSV of IDs to List of Accounts' category='Account')
  public static List<List<Account>> convertCsvToList(List<String> accountIdsString) {
    List<Account> distributors = new List<Account>();
    for (String accountId : accountIdsString) {
      List<String> result = accountId.split(',');
      for (String res : result) {
        distributors.add(new Account(Id = res));
      }
    }
    List<List<Account>> result = new List<List<Account>>();
    result.add(distributors);

    return result;
  }
}