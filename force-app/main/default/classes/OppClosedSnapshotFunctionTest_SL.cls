@IsTest(IsParallel=false)
public with sharing class OppClosedSnapshotFunctionTest_SL {
  @IsTest
  private static void onUpdate_deriveOwnerRole() {
    UserRole testRole = new UserRole(Name = 'Testing Role', DeveloperName = 'Testing_Role');
    insert testRole;

    User testUser = DataFactory_CM.createUser('John', 'Doe', 'Standard User', false);
    testUser.UserRoleId = testRole.Id;
    insert testUser;

    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id opportunityId = fflib_IDGenerator.generate(Opportunity.SObjectType);

    Opportunity opp = DataFactory_SL.createOpportunity(accountId, false);
    opp.Id = opportunityId;
    opp.Owner_Role_Snapshot__c = null;

    Opportunity newOpp = DataFactory_SL.createOpportunity(accountId, false);
    newOpp.Id = opportunityId;
    newOpp.Owner_Role_Snapshot__c = null;
    newOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_BOOKED;
    newOpp.OwnerId = testUser.Id;

    Test.startTest();
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ newOpp },
      new Map<Id, Opportunity>{ opportunityId => opp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);
    Test.stopTest();

    System.assertEquals('Testing Role', newOpp.Owner_Role_Snapshot__c, 'Owner Role Snapshot not set on update');
  }
}