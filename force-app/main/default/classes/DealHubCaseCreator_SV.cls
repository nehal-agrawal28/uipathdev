public without sharing class DealHubCaseCreator_SV {
  @AuraEnabled
  public static String submitCase(Case caseData) {
    try {
      Id contactId = getContactIdFromEmail(caseData.SuppliedEmail);
      if (contactId == null) {
        Account account = getAccount(caseData.accountId);
        contactId = createContactFromName(caseData.SuppliedName, caseData.SuppliedEmail, account);
      }

      caseData.ContactId = contactId;

      Database.DMLOptions dmlOptions = new Database.DMLOptions();
      dmlOptions.EmailHeader.TriggerAutoResponseEmail = true;
      dmlOptions.AssignmentRuleHeader.UseDefaultRule = true;
      caseData.setOptions(dmlOptions);

      insert caseData;
    } catch (Exception e) {
      System.debug('$$$ Exception: ' + e);
      throw new AuraHandledException(e.getMessage());
    }
    return caseData.Id;
  }

  public static Id getContactIdFromEmail(String suppliedEmail) {
    Contact contact;
    try {
      contact = [SELECT Id FROM Contact WHERE Email = :suppliedEmail];
    } catch (Exception e) {
      return null;
    }
    return contact.Id;
  }

  public static Account getAccount(Id accountId) {
    return [SELECT Id, OwnerId FROM Account WHERE Id = :accountId];
  }

  public static Id createContactFromName(String suppliedName, String SuppliedEmail, Account account) {
    Integer spacePosition = suppliedName.indexOf(' ');

    Contact contact = new Contact();
    contact.OwnerId = account.OwnerId;
    contact.FirstName = suppliedName.left(spacePosition);
    contact.LastName = suppliedName.remove(contact.FirstName);
    contact.Email = SuppliedEmail;
    contact.Autocreated__c = true;
    contact.AccountId = account.Id;
    contact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
      .get('Contact')
      .getRecordTypeId();
    contact.Department__c = 'Other';
    insert contact;
    return contact.Id;
  }
}