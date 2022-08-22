@isTest
public with sharing class AccountRelatedEmailDomainsTest_PP {
  @testSetup
  static void setup() {
    Account acc = new Account(
      Name = 'Test Unique Account Email Domain',
      BillingCountryCode = 'BE',
      Industry = 'Healthcare'
    );
    insert acc;
    EmailDomain__c ed = new EmailDomain__c(EmailDomainName__c = 'testUniqueuipath.com');
    insert ed;
  }

  @isTest
  public static void itShouldFillInUniqueField() {
    Account acc = [SELECT Id FROM Account WHERE Name = 'Test Unique Account Email Domain'][0];
    EmailDomain__c ed = [SELECT Id FROM EmailDomain__c WHERE EmailDomainName__c = 'testUniqueuipath.com'][0];

    //given two Account-Related Email Domains
    AccountRelatedEmailDomain__c accEd = new AccountRelatedEmailDomain__c(EmailDomain__c = ed.Id, Account__c = acc.Id);
    //when inserted or updated
    AccountRelatedEmailDomains_PP accEds = new AccountRelatedEmailDomains_PP(
      new List<AccountRelatedEmailDomain__c>{ accEd }
    );
    accEds.updateUniqueId();

    //the unique field should be filled in and it must be unique
    accEd = (AccountRelatedEmailDomain__c) accEds.getRecords()[0];
    System.assertEquals(
      accEd.Account__c.to15() +
      '' +
      accEd.EmailDomain__c.to15(),
      accEd.Account_Domain_Unique_Id__c,
      'The unique id is not in the correct value'
    );
  }

  // @isTest
  // public static void itShouldBeUnique() {
  // 	Account acc = [SELECT Id FROM Account WHERE Name = 'Test Unique Account Email Domain'][0];
  // 	EmailDomain__c ed = [SELECT Id FROM EmailDomain__c WHERE EmailDomainName__c = 'testUniqueuipath.com'][0];

  // 	//given two Account-Related Email Domains
  // 	AccountRelatedEmailDomain__c accEd1 = new AccountRelatedEmailDomain__c(EmailDomain__c=ed.Id, Account__c=acc.Id);
  // 	AccountRelatedEmailDomain__c accEd2 = new AccountRelatedEmailDomain__c(EmailDomain__c=ed.Id, Account__c=acc.Id);
  // 	//when inserted or updated
  // 	try {
  // 		insert accEd1;
  // 		System.assert(accEd1.Id != null);
  // 		insert accEd2;
  // 		System.assert(accEd2.Id == null, 'This should always throw error. There can not be email domain duplicates for one account.');
  // 	} catch (DmlException e) {
  // 		//the unique field should be filled in and it must be unique
  // 		System.debug(e);
  // 		System.assert(e.getMessage().contains('DUPLICATE_VALUE'));
  // 	}

  // }
}