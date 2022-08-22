@isTest(isParallel=false)
public with sharing class LeadIntegrationServiceTest {
    public static final String CONFIRMATION_MESSAGE = 'There should be a publish attempt in the logs';

    @isTest
    public static void testpublishNewLeadToOrchestrator() {
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Status = 'New',
            Company = 'Test Company',
            Country = 'Japan',
            Email = 'joe.test@test.com',
            Industry = 'Automotive'
        );
        OrchestratorNotifierQueueable.forceSyncMode = true;
        Test.startTest();
        insert lead;
        Test.stopTest();

        List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();
        // prettier-ignore
        for (UiPath__UiPathLog__c log : [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c WHERE CreatedDate = TODAY]) {
            if (log.Uipath__Details__c.contains(CommonsConstants.LD_TEAMS_MEMBER_UIPATH_SF_CONNECTOR_TEMPLATE)) {
            logList.add(log);
          }
        }
        System.assertEquals(true, !logList.isEmpty(), CONFIRMATION_MESSAGE);
    }

    // TODO: Revisit given validation rule changes
    // @isTest
    // public static void testPublishLeadOwnerUpdatesToOrchestrator() {
    //     Lead lead = new Lead(
    //         FirstName = 'Test',
    //         LastName = 'Lead',
    //         Status = 'Suspect',
    //         Company = 'Test Company',
    //         Country = 'Japan',
    //         Email = 'joe.test@test.com',
    //         Industry = 'Automotive'
    //     );
    //     insert lead;

    //     User u1 = DataFactory_CM.createUser('testooo', 'OtherTest', 'System Administrator', false);
    //     insert u1;
    //     OrchestratorNotifierQueueable.forceSyncMode = true;
    //     Test.startTest();
    //     lead.OwnerId = u1.Id;
    //     update lead;
    //     Test.stopTest();

    //     List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();
    //     // prettier-ignore
    //     for (UiPath__UiPathLog__c log : [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c WHERE CreatedDate = TODAY]) {
    //             if (log.Uipath__Details__c.contains(CommonsConstants.LD_TEAMS_MEMBER_UIPATH_SF_CONNECTOR_TEMPLATE)) {
    //             logList.add(log);
    //           }
    //         }
    //     System.assertEquals(true, !logList.isEmpty(), CONFIRMATION_MESSAGE);
    // }
}