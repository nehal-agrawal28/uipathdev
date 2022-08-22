public without sharing class AccountController_PP {
  @AuraEnabled(cacheable=true)
  public static List<AccountUserTerritory2View> getContacts(String accountId) {
    return [
      SELECT User.Email, User.Name, RoleInTerritory2
      FROM AccountUserTerritory2View
      WHERE AccountId = :accountId AND RoleInTerritory2 LIKE '% Partner Manager'
    ];
  }
}