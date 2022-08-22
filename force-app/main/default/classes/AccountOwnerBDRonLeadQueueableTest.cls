@isTest
private class AccountOwnerBDRonLeadQueueableTest {

  @testSetup
  private static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', false);
    insert testAccount;

    List<Lead> accLeads = new List<Lead>();
    for(Integer i=0; i<10; i++) {
      Lead l = new Lead();
      l.Account__c = testAccount.Id;
      l.Overwrite_Account_Match__c = true;
      l.Country = 'United States';
      l.LastName = 'Test Lead' + String.valueOf(i);
      l.Email = 'testleademail' + String.valueOf(i) + '@testemail.com';
      l.Company = 'Company' + String.valueOf(i);
      accLeads.add(l);
    }
    
    insert accLeads;
  }
      
  @isTest
  public static void testAccountChangedBDR() {
    
    // Query Account
    List<Account> acc = [SELECT Id, OwnerId, PG_Legacy__c FROM Account LIMIT 1];

    // Query User
    List<User> u2 = [SELECT Id FROM User WHERE LastName = 'Test2' LIMIT 1];

    Account newAcc = acc.get(0).clone();
    newAcc.Id = acc.get(0).Id;
    newAcc.EDR__c = UserInfo.getUserId();
    update newAcc;

    AccountSetContactOwnerQueueable accountSetContactOwnerQueueable = new AccountSetContactOwnerQueueable(
      new List<Account>{ newAcc },
      new Map<Id, SObject>{ acc.get(0).Id => acc.get(0) }
    );
    accountSetContactOwnerQueueable.execute(null);
    
    List<Lead> relatedLeads = [SELECT Id, OwnerId FROM Lead WHERE Account__c =: newAcc.Id LIMIT 10];
    for(Lead l: relatedLeads) {
      System.assertEquals(UserInfo.getUserId(), l.OwnerId);
    }
    
  }
}