@IsTest
private with sharing class ContractSetSupportFlagOnAccTest_SL {
  @IsTest
  private static void setClearForSuppQueueableOnUpdateTest() {
    Account acc = new Account(
      Name = 'TestAccountUK',
      Country__c = 'United Kingdom',
      BillingCountry = 'United Kingdom',
      Industry = 'Others'
    );
    insert acc;

    Contract contract = new Contract(
      Name = 'test',
      StartDate = Date.Today(),
      Status = 'Draft',
      AccountId = acc.Id,
      ContractTerm = 4
    );
    insert contract;

    contract.Status = 'Activated';
    update contract;

    ContractSetSupportFlagOnAccQueueable_SL queueable = new ContractSetSupportFlagOnAccQueueable_SL(
      new List<Contract>{ contract }
    );
    queueable.execute(null);

    Account updatedAccount = [SELECT Id, Cleared_for_Support__c FROM Account LIMIT 1];
    System.assertEquals(true, updatedAccount.Cleared_for_Support__c, 'Dirty flag was not set correctly');
  }
}