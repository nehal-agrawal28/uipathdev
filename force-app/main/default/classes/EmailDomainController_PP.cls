public without sharing class EmailDomainController_PP {
  @AuraEnabled
  public static List<String> getEmailDomainsFromId(String accountId) {
    Set<String> domains = new Set<String>();
    List<Contact> contacts = [SELECT Email FROM Contact WHERE AccountId = :accountId];
    for (Contact con : contacts) {
      // Split the email field (test@uipath.com) where @ is the splitter
      // get(0) is everything that comes before the @, get(1) everything after.
      String emailDomain = con.Email.split('@').get(1);
      domains.add(emailDomain);
    }

    List<String> result = new List<String>(domains);

    return result;
  }

  @InvocableMethod
  public static void createDomains(List<DomainInput> request) {
    Set<String> domains = new Set<String>(request[0].domains);
    String accountId = request[0].accountId;

    List<EmailDomain__c> emailDomains = createDomains(domains);

    upsert createAccountRelatedEmailDomains(accountId, emailDomains);
  }

  private static List<AccountRelatedEmailDomain__c> createAccountRelatedEmailDomains(
    String accountId,
    List<EmailDomain__c> emailDomains
  ) {
    AccountRelatedEmailDomainsSelector_PP aredSelector = (AccountRelatedEmailDomainsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelatedEmailDomain__c.SObjectType
    );
    List<AccountRelatedEmailDomain__c> areds = aredSelector.selectByAccountIds(new List<Id>{ accountId }, false);
    AccountRelatedEmailDomains_PP aredDomain = (AccountRelatedEmailDomains_PP) Application_PP.Domain.newInstance(
      areds,
      AccountRelatedEmailDomain__c.SObjectType
    );
    Map<Id, AccountRelatedEmailDomain__c> aredByDomainId = aredDomain.getAccountRelatedEmailDomainByDomainId();

    for (EmailDomain__c emailDomain : emailDomains) {
      if (aredByDomainId.get(emailDomain.Id) == null) {
        AccountRelatedEmailDomain__c accountDomain = new AccountRelatedEmailDomain__c();
        accountDomain.Account__c = accountId;
        accountDomain.EmailDomain__c = emailDomain.Id;

        areds.add(accountDomain);
      }
    }

    return areds;
  }

  private static List<EmailDomain__c> createDomains(Set<String> domains) {
    List<EmailDomain__c> emailDomains = [
      SELECT Id, EmailDomainName__c
      FROM EmailDomain__c
      WHERE EmailDomainName__c IN :domains
    ];
    List<EmailDomain__c> newEmailDomains = new List<EmailDomain__c>();
    for (String domain : domains) {
      Boolean isPresent = false;
      for (EmailDomain__c dom : emailDomains) {
        if (domain == dom.EmailDomainName__c) {
          isPresent = true;
          break;
        }
      }
      if (!isPresent) {
        EmailDomain__c emailDomain = new EmailDomain__c();
        emailDomain.EmailDomainName__c = domain;
        newEmailDomains.add(emailDomain);
      }
    }

    upsert newEmailDomains;
    return [SELECT Id FROM EmailDomain__c WHERE EmailDomainName__c IN :domains];
  }

  public class DomainInput {
    @InvocableVariable
    public String accountId;

    @InvocableVariable
    public List<String> domains;
  }
}