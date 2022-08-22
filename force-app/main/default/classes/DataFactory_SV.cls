@IsTest(isParallel=true)
public with sharing class DataFactory_SV {
  public static Case createAcademyCase(Boolean insertFlag) {
    return createCase(CaseMetadata_SV.AcademyRecordType, insertFlag);
  }
  public static Case createIncidentCase(Boolean insertFlag) {
    return createCase(CaseMetadata_SV.IncidentRecordType, insertFlag);
  }

  public static Case createServiceIncidentCase(Boolean insertFlag) {
    return createCase(CaseMetadata_SV.ServiceIncidentRecordType, insertFlag);
  }

  public static Case createCloudElementCase(Boolean insertFlag) {
    return createCase(CaseMetadata_SV.CloudElementsRecordType, insertFlag);
  }

  public static Case createCase(Id recordTypId, Boolean insertFlag) {
    Case newCase = new Case();
    newCase.RecordTypeId = recordTypId;
    newCase.Subject = 'Test';
    newCase.Status = 'New';
    newCase.SuppliedEmail = 'caseemail@dummydomain.com';
    newCase.Problem__c = 'Some Problem';
    newCase.Cause__c = 'Some Cause';
    newCase.Origin = 'Web';

    if (insertFlag) {
      insert newCase;
    }

    return newCase;
  }

  public static User createUser(String firstName, String lastName, String profileName, Boolean insertFlag) {
    User newUser = new User();

    newUser.ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
    newUser.firstName = firstName;
    newUser.lastName = lastName;
    newUser.Email = String.valueOf(firstName + lastName + '@test.uipath').replaceAll('\\s+', '');
    newUser.Username = String.valueOf(firstName + lastName + '@test.uipath').replaceAll('\\s+', '');
    newUser.CompanyName = 'Test';
    newUser.Title = 'Title';
    newUser.Alias = 'Alias';
    newUser.TimeZoneSidKey = 'America/Los_Angeles';
    newUser.EmailEncodingKey = 'UTF-8';
    newUser.LanguageLocaleKey = 'en_US';
    newUser.LocaleSidKey = 'en_US';

    if (insertFlag) {
      insert newUser;
    }

    return newUser;
  }

  public static Account createAccount(
    String name,
    String billingStreet,
    String billingCity,
    String billingPostalCode,
    String billingCountry,
    String phone,
    String industry,
    Boolean insertFlag
  ) {
    Account newAccount = new Account();
    newAccount.Name = name;
    newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Customer')
      .getRecordTypeId();
    newAccount.BillingStreet = billingStreet;
    newAccount.BillingCity = billingCity;
    newAccount.BillingPostalCode = billingPostalCode;
    newAccount.BillingCountry = billingCountry;
    newAccount.Phone = phone;
    newAccount.Industry = industry;
    if (insertFlag) {
      insert newAccount;
    }

    return newAccount;
  }

  public static Contact createContact(
    Id accountId,
    String firstName,
    String lastName,
    String email,
    String title,
    Boolean insertFlag
  ) {
    Contact newContact = new Contact();
    newContact.AccountId = accountId;
    newContact.FirstName = firstName;
    newContact.LastName = lastName;
    newContact.Email = email;
    newContact.Title = title;
    newContact.Department__c = 'IT';
    if (insertFlag) {
      insert newContact;
    }

    return newContact;
  }

  public static Attachment createAttachment(Id parentId) {
    Attachment att = new Attachment();
    att.parentId = parentId;
    att.Name = 'Test';
    att.Body = Blob.valueOf('test');
    insert att;
    return att;
  }
}