@IsTest
public with sharing class CaseCloudElementsFunctionTest_SV {
  @IsTest
  private static void testCheckForRestrictedSubject() {
    Case urgentPriority = DataFactory_SV.createCloudElementCase(false);
    urgentPriority.Subject = 'some random case with very high priority';

    Case lowPriority = DataFactory_SV.createCloudElementCase(false);
    lowPriority.Subject = 'some random case with low priority';

    Case highPriority = DataFactory_SV.createCloudElementCase(false);
    highPriority.Subject = 'some random case with high priority';

    Case mediumPrority = DataFactory_SV.createCloudElementCase(false);
    mediumPrority.Subject = 'some random case with default priority';

    fflib_SObjectDomain.Test.Database.onInsert(
      new List<Case>{ urgentPriority, lowPriority, highPriority, mediumPrority }
    );
    fflib_SObjectDomain.triggerHandler(Cases_SV.class);

    System.assertEquals(CaseMetadata_SV.URGENT, urgentPriority.Priority, 'Urgent Priority is not set');
    System.assertEquals(CaseMetadata_SV.LOW, lowPriority.Priority, 'Low Priority is not set');
    System.assertEquals(CaseMetadata_SV.HIGH, highPriority.Priority, 'High Priority is not set');
    System.assertEquals(CaseMetadata_SV.MEDIOUM, mediumPrority.Priority, 'Medium Priority is not set');
  }
}