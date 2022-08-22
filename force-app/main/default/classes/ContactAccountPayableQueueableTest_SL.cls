@isTest
private class ContactAccountPayableQueueableTest_SL {
  @testSetup
  static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Contact testContact = DataFactory_CM.createContact(testAccount.Id, true);
    // AccountContactRelation testAccountContactRelation = new AccountContactRelation(
    //   AccountId = testAccount.Id,
    //   ContactId = testContact.Id
    // );
    // insert testAccountContactRelation;
  }

  @isTest
  private static void testUpdateAPContactOnAccounts() {
    Test.startTest();
    Contact contact = [SELECT Id, Role__c FROM Contact LIMIT 1];
    contact.Role__c = 'Accounts Payable';
    update contact;
    Test.stopTest();

    AccountContactRelation updatedAccountContactRelation = [
      SELECT Id, ContactId, Account.AP_Contact__c
      FROM AccountContactRelation
      WHERE ContactId = :contact.Id
      LIMIT 1
    ];
    System.assertEquals(
      updatedAccountContactRelation.ContactId,
      updatedAccountContactRelation.Account.AP_Contact__c,
      'AP Contact was not set up correctly'
    );
  }
}