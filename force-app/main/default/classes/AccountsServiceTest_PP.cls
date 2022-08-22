/**
 * File Name: AccountsServiceTest_PP
 * Description:
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer | wvelzebo@its.jnj.com
 */
@IsTest
private class AccountsServiceTest_PP {
  @isTest
  static void itShouldActivateTheRightAccounts() {
    // Given two partner accounts; A more than a year old, B a recent account
    Account accountA = TestFactory_PP.buildPartnerAccount('Test Partner A', UserInfo.getUserId(), false);
    Account accountB = TestFactory_PP.buildPartnerAccount('Test Partner B', UserInfo.getUserId(), false);
    accountA.Date_Joined_Program__c = Date.today().addDays(-400);
    accountB.Date_Joined_Program__c = Date.today().addDays(-30);
    insert new Accounts_PP(new List<Account>{ accountA, accountB })
      .setPartnerContributingStatus('Inactive')
      .setPartnerBuysThroughDisti(true)
      .getRecords();

    // WHEN
    List<Account> accounts = new List<Account>{ accountA, accountB };
    new AccountsService_PP().setPartnerContributingStatusToActiveAfterOneYear(accounts);

    // THEN - only account A should be updated
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Account WHERE Id = :accountA.Id AND PartnerContributingStatus__c = 'Active']
    );
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Account WHERE Id = :accountB.Id AND PartnerContributingStatus__c = 'InActive']
    );
  }
}