@isTest
public class WrikeTriggerTest {
  @TestSetup
  static void setup() {
    Account acc = new Account(Name = 'newAcc1', BillingCountry = 'United Kingdom', Industry = 'Others');
    insert acc;
    Opportunity o = new Opportunity();
    o.accountid = acc.id;
    o.StageName = 'Discovery';
    o.CloseDate = system.today();
    o.name = 'Test Op';
    o.Type = 'Upsell';
    o.CurrencyIsoCode = 'EUR';
    o.Led_by__c = 'Direct Led';
    o.Won_Reasons__c = 'Product Roadmap';
    o.Features_the_customer_liked_didn_t_like__c = 'The best products are here';
    o.Name_of_competition_last_round__c = 'We are our own competition';
    o.Name_of_our_partner__c = 'The best partner';
    o.UiPath_team_part_of_the_bid_process__c = 'The whole company';
    o.Closeout_Reason__c = 'We Won the account today!';
    o.LeadSource = 'Partner';
    insert o;

    User u = new User();
    u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    u.Username = 'test839734@uiath.com';
    u.LastName = 'Test';
    u.Email = 'test839734@uiath.com';
    u.Alias = 't839734';
    u.TimeZoneSidKey = 'America/Los_Angeles';
    u.LocaleSidKey = 'en_US';
    u.EmailEncodingKey = 'UTF-8';
    u.LanguageLocaleKey = 'en_US';
    insert u;

    pse__Practice__c practice = new pse__Practice__c(Name = 'Test Practice');
    insert practice;

    pse__Proj__c testProj = new Pse__Proj__c(
      Name = 'test_Project_123456',
      CurrencyIsoCode = 'USD',
      pse__Account__c = acc.id,
      pse__Practice__c = practice.Id,
      pse__Is_Active__c = true,
      pse__Start_Date__c = Date.newInstance(2019, 12, 1),
      pse__End_Date__c = Date.newInstance(2019, 12, 31)
    );
    insert testProj;
  }
  @isTest
  static void testPSOppTask() {
    Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());

    Opportunity opp = [SELECT Id FROM Opportunity];
    Test.startTest();
    Pre_Sales_Tasks__c testTask = new Pre_Sales_Tasks__c(
      Detailed_Description__c = 'Test PreSales',
      Customer_Contact_email__c = 'mail@gmail.com',
      Due_Date__c = Date.newInstance(2025, 12, 31),
      Products_in_Scope__c = 'Automation Cloud',
      Type__c = Constants.PRESALES_TASK_TYPE_1,
      Delivery_Tag__c = 'UiPath Led - partner is absent',
      Assignment_Type__c = 'Online',
      Has_an_NDA_been_signed__c = 'Yes',
      Request_Description__c = 'This is a test description',
      Demo_Audience__c = Constants.PRESALES_TASK_DEMO_AUDIENCE_1,
      Customer_familiar_with_UiPath_tools_prod__c = Constants.PRESALES_TASK_CUSTOMER_FAMILIAR_WITH_TOOLS_1,
      Opportunity__c = opp.Id
    );
    insert testTask;

    testTask = [SELECT Id, Detailed_Description__c FROM Pre_Sales_Tasks__c WHERE Id = :testTask.Id];

    System.assertEquals(testTask.Detailed_Description__c, 'Test PreSales');
    Test.stopTest();
  }

  @isTest
  static void testPSAccTask() {
    Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());

    Account acc = [SELECT Id FROM Account];
    Test.startTest();

    Pre_Sales_Tasks__c testTask = new Pre_Sales_Tasks__c(
      Detailed_Description__c = 'Test PreSales',
      Customer_Contact_email__c = 'mail@gmail.com',
      Due_Date__c = Date.newInstance(2025, 12, 31),
      Products_in_Scope__c = 'Automation Cloud',
      Type__c = Constants.PRESALES_TASK_TYPE_1,
      Delivery_Tag__c = 'UiPath Led - partner is absent',
      Assignment_Type__c = 'Online',
      Has_an_NDA_been_signed__c = 'Yes',
      Request_Description__c = 'This is a test description',
      Demo_Audience__c = Constants.PRESALES_TASK_DEMO_AUDIENCE_1,
      Customer_familiar_with_UiPath_tools_prod__c = Constants.PRESALES_TASK_CUSTOMER_FAMILIAR_WITH_TOOLS_1,
      Account__c = acc.Id
    );
    insert testTask;
    testTask = [SELECT Id, Detailed_Description__c FROM Pre_Sales_Tasks__c WHERE Id = :testTask.Id];
    System.assertEquals(testTask.Detailed_Description__c, 'Test PreSales');
    Test.stopTest();
  }

  @isTest
  static void testPSTask() {
    Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());

    Test.startTest();
    Pre_Sales_Tasks__c testTask = new Pre_Sales_Tasks__c(
      Detailed_Description__c = 'Test PreSales',
      Customer_Contact_email__c = 'mail@gmail.com',
      Due_Date__c = Date.newInstance(2025, 12, 31),
      Products_in_Scope__c = 'Automation Cloud',
      Assignment_Type__c = 'Online',
      Has_an_NDA_been_signed__c = 'Yes',
      Type__c = Constants.PRESALES_TASK_TYPE_1,
      Delivery_Tag__c = 'UiPath Led - partner is absent',
      Request_Description__c = 'This is a test description',
      Demo_Audience__c = Constants.PRESALES_TASK_DEMO_AUDIENCE_1,
      Customer_familiar_with_UiPath_tools_prod__c = Constants.PRESALES_TASK_CUSTOMER_FAMILIAR_WITH_TOOLS_1
    );
    insert testTask;
    testTask = [SELECT Id, Detailed_Description__c FROM Pre_Sales_Tasks__c WHERE Id = :testTask.Id];
    System.assertEquals(testTask.Detailed_Description__c, 'Test PreSales');
    Test.stopTest();
  }

  @isTest
  static void testCSMTask() {
    Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());

    Test.startTest();
    CSM_PS_Engagement__c testTask = new CSM_PS_Engagement__c(SKU_IDs__c = 'PSCS-6. Academy Live');
    insert testTask;
    testTask = [SELECT Id, SKU_IDs__c FROM CSM_PS_Engagement__c WHERE Id = :testTask.Id];
    System.assertEquals(testTask.SKU_IDs__c, 'PSCS-6. Academy Live');
    Test.stopTest();
  }

  @isTest
  static void testPSTeamAddTask() {
    Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
    Opportunity opp = [SELECT Id FROM Opportunity];
    User us = [SELECT id FROM User LIMIT 1];

    Pre_Sales_Tasks__c testTask = new Pre_Sales_Tasks__c(
      Detailed_Description__c = 'Test PreSales',
      Customer_Contact_email__c = 'mail@gmail.com',
      Due_Date__c = Date.newInstance(2025, 12, 31),
      Products_in_Scope__c = 'Automation Cloud',
      Type__c = Constants.PRESALES_TASK_TYPE_1,
      Delivery_Tag__c = 'UiPath Led - partner is absent',
      Assignment_Type__c = 'Online',
      Has_an_NDA_been_signed__c = 'Yes',
      Request_Description__c = 'This is a test description',
      Demo_Audience__c = Constants.PRESALES_TASK_DEMO_AUDIENCE_1,
      Customer_familiar_with_UiPath_tools_prod__c = Constants.PRESALES_TASK_CUSTOMER_FAMILIAR_WITH_TOOLS_1,
      Opportunity__c = opp.Id
    );
    insert testTask;

    Test.startTest();
    Pre_Sales_Team__c testTM = new Pre_Sales_Team__c(Pre_Sales_Tasks__c = testTask.Id, Name__c = us.Id);
    insert testTM;
    testTM = [SELECT Id, Name__C FROM Pre_Sales_Team__c WHERE Id = :testTM.Id];
    System.assertEquals(testTM.Name__c, us.Id);
    Test.stopTest();
  }

  @isTest
  static void testPSTeamDeleteTask() {
    Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());

    Opportunity opp = [SELECT Id FROM Opportunity];
    User us = [SELECT id FROM User LIMIT 1];

    Pre_Sales_Tasks__c testTask = new Pre_Sales_Tasks__c(
      Detailed_Description__c = 'Test PreSales',
      Customer_Contact_email__c = 'mail@gmail.com',
      Due_Date__c = Date.newInstance(2025, 12, 31),
      Products_in_Scope__c = 'Automation Cloud',
      Type__c = Constants.PRESALES_TASK_TYPE_1,
      Delivery_Tag__c = 'UiPath Led - partner is absent',
      Assignment_Type__c = 'Online',
      Has_an_NDA_been_signed__c = 'Yes',
      Request_Description__c = 'This is a test description',
      Demo_Audience__c = Constants.PRESALES_TASK_DEMO_AUDIENCE_1,
      Customer_familiar_with_UiPath_tools_prod__c = Constants.PRESALES_TASK_CUSTOMER_FAMILIAR_WITH_TOOLS_1,
      Opportunity__c = opp.Id
    );
    insert testTask;

    Pre_Sales_Team__c testTM = new Pre_Sales_Team__c(Pre_Sales_Tasks__c = testTask.Id, Name__c = us.Id);
    insert testTM;

    Test.startTest();
    delete testTM;
    Pre_Sales_Team__c deletedTm = [SELECT Id, IsDeleted FROM Pre_Sales_Team__c WHERE Id = :testTM.Id ALL ROWS];
    System.assertEquals(deletedTm.IsDeleted, true);
    Test.stopTest();
  }

  @isTest
  static void testAddMilestone() {
    Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());

    pse__Proj__c testProj = [SELECT Id FROM pse__Proj__c];

    Test.startTest();
    pse__Milestone__c testMS = new Pse__Milestone__c(
      Name = 'test_Milestone_123456',
      pse__Project__c = testProj.id,
      pse__Target_Date__c = Date.newInstance(2019, 12, 31),
      Billing_Milestone_Type__c = 'Prepaid Fixed Fee'
    );
    insert testMS;
    pse__Milestone__c queryMS = [SELECT Id, Name FROM pse__Milestone__c WHERE Id = :testMS.Id];
    System.assertEquals(testMS.Name, queryMS.Name);
    Test.stopTest();
  }
}