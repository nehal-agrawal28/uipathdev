@IsTest
public with sharing class CaseValidateAutoReplyFunctionTest_SV {
  @IsTest
  private static void checkForRestrictedSubjects() {
    Case newRecord = DataFactory_SV.createIncidentCase(false);
    newRecord.Subject = 'Automatic reply - The user is out of office';

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ newRecord });
    fflib_SObjectDomain.triggerHandler(Cases_SV.class);

    System.assertNotEquals(null, newRecord.getErrors(), 'No error is thrown');
  }

  @IsTest
  private static void restrictPtoAsWordInSubject() {
    Case newRecord = DataFactory_SV.createIncidentCase(false);
    newRecord.Subject = 'I am on PTO - from jan 1 to jan 2';

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ newRecord });
    fflib_SObjectDomain.triggerHandler(Cases_SV.class);

    System.assertNotEquals(null, newRecord.getErrors(), 'No error is thrown');
  }

  // @IsTest
  // private static void donotRestrictIfPtoInSubject() {
  //   Case newRecord = DataFactory_SV.createIncidentCase(false);
  //   newRecord.Subject = 'Descriptor or zaptos or laptop';

  //   fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ newRecord });
  //   fflib_SObjectDomain.triggerHandler(Cases_SV.class);

  //   System.assertEquals(null, newRecord.getErrors(), 'Error should not be thrown');
  // }
}