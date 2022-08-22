/**
 * @AUTHOR: UIPath
 * @DATE: 03/12/2021
 * @DESCRIPTION: Test class of ETMSystemNotificationService
 */
@isTest
public class ETMSystemNotificationServiceTest {
  @testSetup
  static void setup() {
    Id csmUserId;
    try {
      csmUserId = [SELECT Id FROM User WHERE Profile.Name = 'Customer Success Manager' AND IsActive = TRUE LIMIT 1].Id;
    } catch (Exception e) {
      csmUserId = UserInfo.getUserId();
    }

    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');

    Territory2 terr1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');
    terr1.Ultimate_Geo__c = 'AMER';
    update terr1;

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
    System.runAs(objUser) {
      List<Account> listOfAccount = new List<Account>();
      Id customerRecTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer')
        .getRecordTypeId();
      Id recordTypeId = Schema.SobjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('UiPath_Standard')
        .getRecordTypeId();
      Account objAccount1 = new Account(
        Industry = 'Engineering',
        BillingCountry = 'United Kingdom',
        BillingPostalCode = '012345',
        Name = 'Account 1',
        Geo__c = 'AMER',
        CSM__c = csmUserId,
        RecordTypeId = customerRecTypeId
      );
      listOfAccount.add(objAccount1);
      Account objAccount2 = new Account(
        Industry = 'Engineering',
        BillingCountry = 'United Kingdom',
        BillingPostalCode = '012345',
        Name = 'Account 2',
        Geo__c = 'AMER',
        CSM__c = csmUserId,
        RecordTypeId = customerRecTypeId
      );
      listOfAccount.add(objAccount2);
      insert listOfAccount;

      List<Opportunity> listOfOpportunity = new List<Opportunity>();
      for (Account objAccount : listOfAccount) {
        Opportunity objOpp = new Opportunity();
        objOpp.Name = 'testOppName';
        objOpp.RecordTypeId = recordTypeId;
        objOpp.AccountId = objAccount.Id;
        objOpp.StageName = 'Discovery';
        objOpp.CloseDate = Date.today();
        objOpp.CurrencyIsoCode = 'USD';
        objOpp.LeadSource = 'Webinar';
        listOfOpportunity.add(objOpp);
      }
      insert listOfOpportunity;

      List<Account> objAccount = [SELECT Id, Name, Geo__c, CSM__r.Name FROM Account];

      List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, objAccount[0].Id, 'UiPath_Standard', false);
      oppList[0].LeadSource = 'Webinar';

      insert oppList;
    }
  }

  public static testMethod void testAccountOwnerSyncException() {
    Test.startTest();
    ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
    etmSystem.accountOwnerSyncException([SELECT Id, Name, Geo__c FROM Account]);
    Integer invocations = Limits.getEmailInvocations();
    Test.stopTest();
    System.assertEquals(
      1,
      invocations,
      'Email triggered to user email address present in Primary Email field of ETM System Notifications custom metadata'
    );
  }

  public static testMethod void testaccountCSMTerritoryException() {
    Test.startTest();
    ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
    etmSystem.accountCSMTerritoryException([SELECT Id, Name, Geo__c, CSM__r.Name FROM Account]);
    Integer invocations = Limits.getEmailInvocations();
    Test.stopTest();
    System.assertEquals(
      1,
      invocations,
      'Email triggered to user email address present in Primary Email field of ETM System Notifications custom metadata'
    );
  }

  public static testMethod void testoppPartnerTerritoryException() {
    User objUser = [SELECT Id FROM User WHERE Email = 'test839734@uiath.com' LIMIT 1];
    System.runAs(objUser) {
      Territory2 terr = TestFactory_ET.getTerritoryId('Test Sales Territory 1');

      List<Opportunity> updatedOppList = [
        SELECT
          Id,
          Name,
          Territory2.Sales_Territory__c,
          OwnerId,
          Territory2.Primary_Account_Manager_Id__c,
          Is_Partner_Sourced__c,
          BPO_MS_End_Customer__c,
          Territory2.Interim_Account_Manager_Id__c,
          Deal_Type__c,
          Territory2Id,
          AccountId,
          Account.RecordTypeId,
          Territory_Geo__c,
          Owner_Sync_Status__c,
          Account_Geo__c
        FROM Opportunity
      ];
      updatedOppList[0].Territory2 = terr;
      updatedOppList[0].Territory2Id = terr.Id;
      Test.startTest();
      update updatedOppList[0];
      ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
      etmSystem.oppPartnerTerritoryException([SELECT Id, Name, Territory_Geo__c, Territory2.Name FROM Opportunity]);
      Integer invocations = Limits.getEmailInvocations();
      Test.stopTest();
      System.assertEquals(
        1,
        invocations,
        'Email triggered to user email address present in Primary Email field of ETM System Notifications custom metadata'
      );
    }
  }

  public static testMethod void testOpportunityOwnerSyncException() {
    User objUser = [SELECT Id FROM User WHERE Email = 'test839734@uiath.com' LIMIT 1];
    // List<Account> objAccount = [SELECT Id, Name, Geo__c,CSM__r.Name FROM Account];
    System.runAs(objUser) {
      //List<Opportunity> listOfOpportunity = [SELECT Id, Name, Deal_Type__c, Account_Geo__c FROM Opportunity];

      List<Account> accountList = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 1', false);
      accountList[0].Geo__c = 'AMER';
      insert accountList;
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[0].Id, 'UiPath_Standard', false);
      oppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_NFR;
      oppList[0].LeadSource = 'Webinar';
      oppList[0].StageName = 'Discovery';
      oppList[0].CloseDate = date.newInstance(2160, 2, 17);
      insert oppList;
      Test.startTest();
      List<Opportunity> listOfOpp = [
        SELECT Id, Account_Geo__c, Name, AccountId, Deal_Type__c, Territory_Name__c
        FROM Opportunity
      ];
      ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
      etmSystem.opportunityOwnerSyncException(listOfOpp);
      Integer invocations = Limits.getEmailInvocations();
      Test.stopTest();
      System.assertEquals(
        2,
        invocations,
        'Email triggered to user email address present in Primary Email field of ETM System Notifications custom metadata'
      );
    }
  }

  public static testMethod void testSecondaryTerritoryRemovalNotification() {
    Test.startTest();
    Map<Id, Set<String>> mapOfAccountIdToTerritoriesName = new Map<Id, Set<String>>();
    for (Account objAccount : [SELECT Id, Name FROM Account]) {
      mapOfAccountIdToTerritoriesName.put(objAccount.Id, new Set<String>{ objAccount.Name + ' First Territory' });
      mapOfAccountIdToTerritoriesName.get(objAccount.Id).add(objAccount.Name + ' Second Territory');
    }
    ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
    etmSystem.secondaryTerritoryRemovalNotification(mapOfAccountIdToTerritoriesName);
    Integer invocations = Limits.getEmailInvocations();
    Test.stopTest();
    System.assertEquals(
      1,
      invocations,
      'Email triggered to user email address present in Primary Email field of ETM System Notifications custom metadata'
    );
  }
}