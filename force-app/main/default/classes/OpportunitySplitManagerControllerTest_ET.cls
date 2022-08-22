@isTest
public class OpportunitySplitManagerControllerTest_ET {
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
      Opportunity_Split__c split = new Opportunity_Split__c();
      split.User__c = objUser.Id;
      split.Opportunity__c = objOpp.Id;
      split.Percentage__c = 100;
      split.TeamMemberRole__c = 'Sales Representative';
      insert split;
    }
  }

  @isTest
  public static void testFetchSplits() {
    User objUser = [SELECT Id FROM User WHERE Email = 'test839734@uiath.com' LIMIT 1];
    Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
    System.runAs(objUser) {
      Test.startTest();
      OpportunitySplitManagerController_ET.SplitWrapper wrapper = new OpportunitySplitManagerController_ET.SplitWrapper();
      wrapper = OpportunitySplitManagerController_ET.getOppSplits(oppId);
      Test.stopTest();
      System.assert(wrapper.listOfOppSplit != null);
    }
  }

  @isTest
  public static void testDeleteSplits() {
    User objUser = [SELECT Id FROM User WHERE Email = 'test839734@uiath.com' LIMIT 1];
    Id splitId = [SELECT Id FROM Opportunity_Split__c LIMIT 1].Id;
    Boolean isException = false;
    System.runAs(objUser) {
      Test.startTest();
      try {
        OpportunitySplitManagerController_ET.deleteOppSplits(new List<Id>{ splitId });
      } catch (Exception ex) {
        isException = true;
      }
      Test.stopTest();
      List<Opportunity_Split__c> splits = [SELECT Id FROM Opportunity_Split__c];
      System.assert(splits.size() == 0);
      System.assertEquals(false, isException);
    }
  }
}