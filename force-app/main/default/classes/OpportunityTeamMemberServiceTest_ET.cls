@isTest
public class OpportunityTeamMemberServiceTest_ET {
  @TestSetup
  static void setup() {
    Account objAcc = new Account(
      Name = 'newAcc1',
      BillingCountry = 'United Kingdom',
      Industry = 'Others',
      Geo__c = 'EMEA'
    );
    insert objAcc;

    User objUser = new User(
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'test839734@uiath.com',
      LastName = 'Test',
      Email = 'test839734@uiath.com',
      Alias = 't839734',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert objUser;

    Opportunity objOpp = new Opportunity(
      accountid = objAcc.id,
      StageName = 'Proposal',
      CloseDate = system.today(),
      name = 'Test Op',
      Type = 'Upsell',
      CurrencyIsoCode = 'EUR',
      LeadSource = 'Partner'
    );
    System.runAs(objUser) {
      insert objOpp;
    }
  }

  @isTest
  public static void testCreateUpdateSplits() {
    User objUser = [SELECT Id FROM User WHERE Email = 'test839734@uiath.com' LIMIT 1];
    Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
    List<OpportunityTeamMember> oppTeamMemberToInsert = new List<OpportunityTeamMember>();
    System.runAs(objUser) {
      Test.startTest();
      OpportunityTeamMember teamMember = new OpportunityTeamMember(
        TeamMemberRole = 'Sales Representative',
        UserId = objUser.Id,
        OpportunityId = oppId,
        Create_Split__c = true,
        OpportunityAccessLevel = 'Edit'
      );
      oppTeamMemberToInsert.add(teamMember);
      OpportunityTeamMember teamMember2 = new OpportunityTeamMember(
        TeamMemberRole = 'Sales Representative',
        UserId = objUser.Id,
        OpportunityId = oppId,
        Create_Split__c = true,
        OpportunityAccessLevel = 'Edit'
      );
      oppTeamMemberToInsert.add(teamMember2);

      insert oppTeamMemberToInsert;

      OpportunityTeamMember updateTeamMember = new OpportunityTeamMember(
        Id = teamMember.Id,
        TeamMemberRole = 'Partner Account Manager'
      );
      update updateTeamMember;
      Test.stopTest();
      List<OpportunityTeamMember> oppTeamMembers = [SELECT Id, UserId, Opportunity_Split__c FROM OpportunityTeamMember];
      System.assertEquals(1, oppTeamMembers.size());
      System.assert(oppTeamMembers[0].Opportunity_Split__c != null);
    }
  }
}