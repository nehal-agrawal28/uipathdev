@isTest
public class DataTeam_SyncTeamMemberSplitsTest {
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

    User u1 = new User(
      Alias = 'newdeut',
      Email = 'newdetestusername@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'newdLastName',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'newdetestusername@testorg.com'
    );

    insert u1;

    Account acc = new Account();
    acc.Name = 'testAccName';
    acc.Industry = 'Healthcare';
    acc.BillingCountry = 'India';
    insert acc;

    Account accSold = new Account();
    accSold.Name = 'Sold Acc Name';
    accSold.Industry = 'Healthcare';
    accSold.BillingCountry = 'India';
    System.runAs(u1) {
      insert accSold;
    }

    Opportunity opp = new Opportunity();
    opp.StageName = 'Close Won';
    opp.CloseDate = Date.today();
    opp.Type = 'Upsell';
    opp.AccountId = acc.Id;
    opp.Name = 'testOppName';
    opp.LeadSource = 'Advertisement';
    opp.Sold_To_Partner__c = accSold.Id;
    insert opp;

    OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
    oppTeamMember1.UserId = u.Id;
    oppTeamMember1.OpportunityId = opp.Id;
    oppTeamMember1.TeamMemberRole = 'Partner Account Manager';
    insert oppTeamMember1;

    List<Opportunity_Split__c> osToDel = [SELECT Id FROM Opportunity_Split__c WHERE User__c = :u1.Id LIMIT 1];
    delete osToDel;

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

    DataTeam_SyncTeamMemberSplits OTMOS = new DataTeam_SyncTeamMemberSplits();
    PageReference pageRef = Page.DataTeam_SyncTeamMemberSplits;
    Test.setCurrentPage(pageRef);

    Test.startTest();
    //String csvStringOTM = 'Opportunity Id Long,User Id Long,Team Member Role\n';
    //csvStringOTM += opp.Id+',,\n';
    String csvStringOTM = 'OpportunityID,UserID,Role\r\n';
    csvStringOTM += opp.Id + ', ' + ', \r\n';

    OTMOS.csvAsString = csvStringOTM;
    OTMOS.csvFileBody = Blob.valueOf(csvStringOTM);
    OTMOS.readCSVData();
    OTMOS.setOpportunityTeamMember();
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

    User u1 = new User(
      Alias = 'newdeut',
      Email = 'newdetestusername@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'newdLastName',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'newdetestusername@testorg.com'
    );

    insert u1;

    Account acc = new Account();
    acc.Name = 'testAccName';
    acc.Industry = 'Healthcare';
    acc.BillingCountry = 'France';
    insert acc;

    Account accSold = new Account();
    accSold.Name = 'Sold Acc Name';
    accSold.Industry = 'Healthcare';
    accSold.BillingCountry = 'France';
    System.runAs(u1) {
      insert accSold;
    }

    Opportunity opp = new Opportunity();
    opp.StageName = 'Close Won';
    opp.CloseDate = Date.today();
    opp.Type = 'Upsell';
    opp.AccountId = acc.Id;
    opp.Name = 'testOppName';
    opp.LeadSource = 'Advertisement';
    opp.Sold_To_Partner__c = accSold.Id;
    insert opp;

    OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
    oppTeamMember1.UserId = u.Id;
    oppTeamMember1.OpportunityId = opp.Id;
    oppTeamMember1.TeamMemberRole = 'Sales Representative';
    insert oppTeamMember1;

    List<Opportunity_Split__c> osToDel = [SELECT Id FROM Opportunity_Split__c WHERE User__c = :u.Id LIMIT 1];
    delete osToDel;

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

    DataTeam_SyncTeamMemberSplits OTMOS = new DataTeam_SyncTeamMemberSplits();
    PageReference pageRef = Page.DataTeam_SyncTeamMemberSplits;
    Test.setCurrentPage(pageRef);

    Test.startTest();
    //String csvStringOTM = 'Opportunity Id Long,User Id Long,Team Member Role\r\n';
    //csvStringOTM += opp.Id+',,\r\n';
    String csvStringOTM = 'OpportunityID,UserID,Role\r\n';
    csvStringOTM += opp.Id + ', ' + ', \r\n';

    OTMOS.csvAsString = csvStringOTM;
    OTMOS.csvFileBody = Blob.valueOf(csvStringOTM);
    OTMOS.readCSVData();
    OTMOS.setOpportunityTeamMember();
    OTMOS.Cancel();

    Test.stopTest();
  }

  @isTest
  static void test_method_three() {
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

    User u1 = new User(
      Alias = 'newdeut',
      Email = 'newdetestusername@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'newdLastName',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'newdetestusername@testorg.com'
    );

    insert u1;

    Account acc = new Account();
    acc.Name = 'testAccName';
    acc.Industry = 'Healthcare';
    acc.BillingCountry = 'France';
    insert acc;

    Account accSold = new Account();
    accSold.Name = 'Sold Acc Name';
    accSold.Industry = 'Healthcare';
    accSold.BillingCountry = 'France';
    System.runAs(u1) {
      insert accSold;
    }

    Opportunity opp = new Opportunity();
    opp.StageName = 'Close Won';
    opp.CloseDate = Date.today();
    opp.Type = 'Upsell';
    opp.AccountId = acc.Id;
    opp.Name = 'testOppName';
    opp.LeadSource = 'Advertisement';
    opp.Sold_To_Partner__c = accSold.Id;
    insert opp;

    OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
    oppTeamMember1.UserId = u.Id;
    oppTeamMember1.OpportunityId = opp.Id;
    oppTeamMember1.TeamMemberRole = 'Sales Representative';
    insert oppTeamMember1;

    List<Opportunity_Split__c> osToDel = [SELECT Id FROM Opportunity_Split__c WHERE User__c = :u.Id LIMIT 1];
    delete osToDel;

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

    DataTeam_SyncTeamMemberSplits OTMOS = new DataTeam_SyncTeamMemberSplits();
    PageReference pageRef = Page.DataTeam_SyncTeamMemberSplits;
    Test.setCurrentPage(pageRef);

    Test.startTest();
    //String csvStringOTM = 'Opportunity Id Long,User Id Long,Team Member Role\r\n';
    //csvStringOTM += opp.Id+',,\r\n';
    String csvStringOTM = 'OpportunityID,UserID,Role\r\n';
    csvStringOTM += opp.Id + ',' + u2.Id + ',Partner Account Manager\r\n';

    OTMOS.csvAsString = csvStringOTM;
    OTMOS.csvFileBody = Blob.valueOf(csvStringOTM);
    OTMOS.readCSVData();
    OTMOS.setOpportunityTeamMember();
    OTMOS.Cancel();

    Test.stopTest();
  }
}