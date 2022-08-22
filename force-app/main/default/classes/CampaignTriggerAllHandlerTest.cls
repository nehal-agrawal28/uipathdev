@isTest
private class CampaignTriggerAllHandlerTest {
  static testMethod void CampaignSetGeoRegion() {
    Campaign campaign_1 = new Campaign();
    campaign_1.Name = 'TestCampaign';
    campaign_1.Type = 'Social Media';
    campaign_1.Campaign_Country__c = 'France';
    campaign_1.Campaign_City__c = 'Paris';
    campaign_1.Campaign_Name_Text__c = 'Test';

    test.StartTest();
    insert campaign_1;

    Campaign c = [SELECT Id, Campaign_Country__c, Campaign_Geo__c, Region__c FROM Campaign LIMIT 1];
    System.AssertEquals('EMEA', c.Campaign_Geo__c);

    c.Campaign_Country__c = 'Canada';
    update c;

    Campaign c1 = [SELECT Id, Campaign_Country__c, Campaign_Geo__c, Region__c FROM Campaign LIMIT 1];
    System.AssertEquals('AMER', c1.Campaign_Geo__c);

    test.StopTest();
  }
}