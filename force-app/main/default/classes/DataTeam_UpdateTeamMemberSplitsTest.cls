@isTest
public class DataTeam_UpdateTeamMemberSplitsTest {
  @isTest
  static void test_method_one() {
    // Data Setup
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    User u = new User(
      Alias = 'stadeut',
      Email = 'deutoriatestusername@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'deutLastName',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'deutoriatestusername@testorg.com'
    );

    insert u;

    Account acc = new Account();
    acc.Name = 'testAccName';
    acc.Industry = 'Healthcare';
    acc.BillingCountry = 'India';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.StageName = 'Close Won';
    opp.CloseDate = Date.today();
    opp.Type = 'Upsell';
    opp.AccountId = acc.Id;
    opp.Name = 'testOppName';
    opp.LeadSource = 'Advertisement';
    insert opp;

    OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
    oppTeamMember1.UserId = u.Id;
    oppTeamMember1.OpportunityId = opp.Id;
    oppTeamMember1.TeamMemberRole = 'Partner Account Manager';
    insert oppTeamMember1;

    User u2 = new User();
    u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    u2.Username = 'testother55666@uiath.com';
    u2.LastName = 'OtherTest';
    u2.Email = 'testother55666@uiath.com';
    u2.Alias = 'her55666';
    u2.TimeZoneSidKey = 'America/Los_Angeles';
    u2.LocaleSidKey = 'en_US';
    u2.EmailEncodingKey = 'UTF-8';
    u2.LanguageLocaleKey = 'en_US';
    insert u2;

    DataTeam_UpdateTeamMemberSplits OTMOS = new DataTeam_UpdateTeamMemberSplits();
    PageReference pageRef = Page.DataTeam_UpdateTeamMemberSplits;
    Test.setCurrentPage(pageRef);

    Test.startTest();
    String csvStringOTM = 'RecordId,OpportunityID,UserId,Role\r\n';
    csvStringOTM += ',' + opp.Id + ',' + u2.Id + ',Sales Representative\r\n';
    OTMOS.getObjectOption();
    OTMOS.selectedOption = 'OpportunityTeamMembers';
    OTMOS.csvAsString = csvStringOTM;
    OTMOS.csvFileBody = Blob.valueOf(csvStringOTM);
    OTMOS.readCSVData();
    OTMOS.updateOpportunityTeamMember();
    OTMOS.Cancel();

    String csvStringOTM2 = 'RecordID\r\n';
    csvStringOTM2 += oppTeamMember1.Id + '\r\n';
    OTMOS.getObjectOption();
    OTMOS.selectedOption = 'OpportunityTeamMembersDelete';
    OTMOS.csvAsString = csvStringOTM2;
    OTMOS.csvFileBody = Blob.valueOf(csvStringOTM2);
    OTMOS.readCSVData();
    OTMOS.deleteAllRecords();
    OTMOS.Cancel();

    Test.stopTest();
  }

  @isTest
  static void test_method_two() {
    // Data Setup
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    User u = new User(
      Alias = 'stadeut',
      Email = 'deutoriatestusername@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'deutLastName',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'deutoriatestusername@testorg.com'
    );

    insert u;

    Account acc = new Account();
    acc.Name = 'testAccName';
    acc.Industry = 'Healthcare';
    acc.BillingCountry = 'India';
    insert acc;

    Opportunity opp = new Opportunity();
    opp.StageName = 'Close Won';
    opp.CloseDate = Date.today();
    opp.Type = 'Upsell';
    opp.AccountId = acc.Id;
    opp.Name = 'testOppName';
    opp.LeadSource = 'Advertisement';
    insert opp;

    OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
    oppTeamMember1.UserId = u.Id;
    oppTeamMember1.OpportunityId = opp.Id;
    oppTeamMember1.TeamMemberRole = 'Partner Account Manager';
    insert oppTeamMember1;

    User u2 = new User();
    u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    u2.Username = 'testother55666@uiath.com';
    u2.LastName = 'OtherTest';
    u2.Email = 'testother55666@uiath.com';
    u2.Alias = 'her55666';
    u2.TimeZoneSidKey = 'America/Los_Angeles';
    u2.LocaleSidKey = 'en_US';
    u2.EmailEncodingKey = 'UTF-8';
    u2.LanguageLocaleKey = 'en_US';
    insert u2;

    DataTeam_UpdateTeamMemberSplits OTMOS = new DataTeam_UpdateTeamMemberSplits();
    PageReference pageRef = Page.DataTeam_UpdateTeamMemberSplits;
    Test.setCurrentPage(pageRef);

    Test.startTest();

    String csvStringOTM3 = 'RecordID,OpportunityID,UserID,Role,Percentage,Included In Compensation\r\n';
    csvStringOTM3 += ',' + opp.Id + ',' + u2.Id + ',Sales Representative,100,Yes\r\n';
    OTMOS.getObjectOption();
    OTMOS.selectedOption = 'OpportunitysplitsInsert';
    OTMOS.csvAsString = csvStringOTM3;
    OTMOS.csvFileBody = Blob.valueOf(csvStringOTM3);
    OTMOS.readCSVData();
    OTMOS.insertOpportunitySplits();
    OTMOS.Cancel();

    String csvStringOTM = 'RecordId,OpportunityID,UserId,Role\r\n';
    csvStringOTM += ',' + opp.Id + ',' + u2.Id + ',Sales Representative,30,Yes\r\n';
    OTMOS.getObjectOption();
    OTMOS.selectedOption = 'OpportunitysplitsUpdate';
    OTMOS.csvAsString = csvStringOTM;
    OTMOS.csvFileBody = Blob.valueOf(csvStringOTM);
    OTMOS.readCSVData();
    OTMOS.updateOpportunitySplits();
    OTMOS.Cancel();

    /* List<Opportunity_Split__c> oppSplit = [SELECT Id FROM Opportunity_Split__c];
    system.debug('oppSplit ======> ' + oppSplit);
    String csvStringOS = 'RecordID\r\n';
    csvStringOS += oppSplit[0].Id + '\r\n';
    OTMOS.getObjectOption();
    OTMOS.selectedOption = 'OpportunitysplitsDelete';
    OTMOS.csvAsString = csvStringOS;
    OTMOS.csvFileBody = Blob.valueOf(csvStringOS);
    OTMOS.readCSVData();
    OTMOS.deleteAllRecords();
    OTMOS.Cancel(); */

    Test.stopTest();
  }
}