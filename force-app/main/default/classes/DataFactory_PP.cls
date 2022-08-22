@isTest
public with sharing class DataFactory_PP {
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