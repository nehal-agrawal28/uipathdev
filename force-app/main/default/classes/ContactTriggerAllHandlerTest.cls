@isTest
private class ContactTriggerAllHandlerTest {
  static testMethod void AccountSetEmailDomain() {
    Account accRec = new Account(
      Name = 'Test' + String.valueOf(System.now()),
      BillingCountryCode = 'US',
      BillingCountry = 'United States',
      BillingStateCode = 'SD',
      Industry = 'Others',
      Legal__c = 'Test' + String.valueOf(System.now()),
      DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567',
      //Default_Payment_Terms__c = '30 Days Net',
      Primary_Subsidiary__c = 'UiPath SRL',
      Channel_Tier__c = 'Reseller'
    );
    insert accRec;

    List<Contact> accRecContacts = new List<Contact>();
    Contact contRec1 = new Contact(
      LastName = 'contRec1',
      AccountId = accRec.Id,
      Email = 'contRec.Test11@emailDomain.com',
      Department__c = 'IT'
    );
    accRecContacts.add(contRec1);
    Contact contRec2 = new Contact(
      LastName = 'contRec2',
      AccountId = accRec.Id,
      Email = 'contRec.Test12@emailDomain.com',
      Department__c = 'IT'
    );
    accRecContacts.add(contRec2);
    Contact contRec3 = new Contact(
      LastName = 'contRec3',
      AccountId = accRec.Id,
      Email = 'contRec.Test13@emailDomain3.com',
      Department__c = 'IT'
    );
    accRecContacts.add(contRec3);
    Contact contRec4 = new Contact(
      LastName = 'contRec4',
      AccountId = accRec.Id,
      Email = 'contRec.Test14@gmail.com',
      Department__c = 'IT'
    );
    accRecContacts.add(contRec4);

    Account accRec1 = new Account(
      Name = 'Test' + String.valueOf(System.now()),
      BillingCountryCode = 'US',
      BillingCountry = 'United States',
      BillingStateCode = 'SD',
      Industry = 'Others',
      Legal__c = 'Test' + String.valueOf(System.now()),
      DNBoptimizer__DNB_D_U_N_S_Number__c = '324365364',
      //Default_Payment_Terms__c = '30 Days Net',
      Primary_Subsidiary__c = 'UiPath SRL',
      Channel_Tier__c = 'Reseller'
    );
    insert accRec1;

    List<Contact> accRec1Contacts = new List<Contact>();
    Contact contRec11 = new Contact(
      LastName = 'contReca',
      AccountId = accRec1.Id,
      Email = 'contRec.Test21@emailDomain11.com',
      Department__c = 'IT'
    );
    accRecContacts.add(contRec11);

    test.StartTest();
    insert accRecContacts;

    Contact c = [SELECT Id, Email FROM Contact WHERE LastName = 'contReca' LIMIT 1];
    c.Email = 'contRec.Test21@newemailDomain11.com';
    update c;

    delete c;

    test.StopTest();
    List<Account> allAccountsDelete = [SELECT Id, Name, Email_Domain__c FROM Account];
    for (Account acc : allAccountsDelete) {
      if (acc.Name == 'Account name1')
        System.AssertEquals(null, acc.Email_Domain__c);
    }
  }
  @IsTest
  public static void populateAPContactOnAccountTest() {
    List<Account> accToInsert = new List<Account>();
    Account testAccountInsert = new Account(
      Name = 'Test Accounts Payable 1',
      Country__c = 'Austria',
      BillingCountryCode = 'AT',
      Industry = 'Others',
      Legal__c = 'Test' + String.valueOf(System.now())
    );

    Account testAccountUpdate = new Account(
      Name = 'Test Accounts Payable 2',
      Country__c = 'France',
      BillingCountryCode = 'FR',
      Industry = 'Others',
      Legal__c = 'Test' + String.valueOf(System.now())
    );

    accToInsert.add(testAccountInsert);
    accToInsert.add(testAccountUpdate);

    insert accToInsert;

    List<Contact> contactsToInsert = new List<Contact>();
    Contact con1 = new Contact(
      LastName = 'contAccPayable1',
      AccountId = testAccountInsert.Id,
      Email = 'cont1.Test21@emailDomain11.com',
      Role__c = 'Accounts Payable',
      Department__c = 'IT'
    );

    Contact con2 = new Contact(
      LastName = 'contAccPayable2',
      AccountId = testAccountUpdate.Id,
      Email = 'cont2.Test21@emailDomain11.com',
      Department__c = 'IT'
    );

    contactsToInsert.add(con1);
    contactsToInsert.add(con2);

    test.StartTest();
    insert contactsToInsert;

    Contact c = [SELECT Id, Email FROM Contact WHERE LastName = 'contAccPayable2' LIMIT 1];
    c.Role__c = 'Accounts Payable';
    update c;
    test.StopTest();

    List<Account> updatedAccounts = new List<Account>(
      [SELECT Id, AP_Contact__c FROM Account WHERE AP_Contact__c != NULL]
    );

    System.assertEquals(2, updatedAccounts.size());
  }
}