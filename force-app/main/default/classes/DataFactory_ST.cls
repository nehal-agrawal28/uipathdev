@IsTest(isParallel=true)
public with sharing class DataFactory_ST {
  public static Sales_Technology_Idea__c createIdea(String applicationArea, Boolean insertFlag) {
    Sales_Technology_Idea__c newIdea = new Sales_Technology_Idea__c();
    newIdea.name = 'TestIdea';
    newIdea.Application_Area__c = applicationArea;
    newIdea.Description__c = 'This is a description that meets the minimmum 20 char requirements';
    newIdea.Benefit__c = 'This is a benefit that meets the minimmum 20 char requirements';

    if (insertFlag) {
      insert newIdea;
    }

    return newIdea;
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
}