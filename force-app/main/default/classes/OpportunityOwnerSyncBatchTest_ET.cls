/**
 * @AUTHOR: UIPath
 * @DATE: 12/11/2021
 * @DESCRIPTION: Test class of OpportunityOwnerSyncBatch_ET
 */
@isTest
public class OpportunityOwnerSyncBatchTest_ET {
  @testSetup
  static void setup() {
    Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    List<User> userList = new List<User>();

    for (Integer i = 1; i < 5; i++) {
      User objUser = new User();
      objUser.ProfileId = systemAdminProfileId;
      objUser.Username = 'test839734@' + i + 'uiath.com';
      objUser.LastName = 'Test';
      objUser.Email = 'test839734@uiath.com';
      objUser.Alias = 't839734';
      objUser.TimeZoneSidKey = 'America/Los_Angeles';
      objUser.LocaleSidKey = 'en_US';
      objUser.EmailEncodingKey = 'UTF-8';
      objUser.LanguageLocaleKey = 'en_US';
      userList.add(objUser);
    }
    insert userList;

    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');

    Territory2 terr1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');
    Territory2 terr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 2');
    Territory2 terr3 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 3');
    Territory2 terr4 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 4');

    //Create Partner Territories
    Territory2Type partnerTerrType = [
      SELECT Id, DeveloperName
      FROM Territory2Type
      WHERE MasterLabel = :ETMConstant.PARTNER_MANAGEMENT
    ];
    List<Territory2> partnerTerrList = new List<Territory2>();
    Territory2 partnerterr1 = TestFactory_ET.createNonSalesTerritory(regionTerr, 'Test Partner Territory 1', false);
    Territory2 partnerterr2 = TestFactory_ET.createNonSalesTerritory(regionTerr, 'Test Partner Territory 2', false);
    Territory2 partnerterr3 = TestFactory_ET.createNonSalesTerritory(regionTerr, 'Test Partner Territory 3', false);
    partnerterr1.Territory2TypeId = partnerTerrType.id;
    partnerTerrList.add(partnerterr1);
    partnerterr2.Territory2TypeId = partnerTerrType.id;
    partnerTerrList.add(partnerterr2);
    partnerterr3.Territory2TypeId = partnerTerrType.id;
    partnerTerrList.add(partnerterr3);
    insert partnerTerrList;

    TestFactory_ET.createUserTerritoryAssociation(
      partnerterr1.Id,
      userList[2].Id,
      ETMConstant.DISTRIBUTION_PARTNER_MANAGER
    );
    TestFactory_ET.createUserTerritoryAssociation(
      partnerterr2.Id,
      userList[3].Id,
      ETMConstant.STRATEGIC_PARTNER_MANAGER
    );

    TestFactory_ET.createUserTerritoryAssociation(terr1.Id, userList[0].Id, ETMConstant.INTERIM_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr2.Id, userList[0].Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr3.Id, userList[1].Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr4.Id, userList[0].Id, ETMConstant.REGION_PARTNER_MANAGER);
  }

  public static testMethod void opportunityOwnerSyncWithPAM() {
    Territory2 terr = TestFactory_ET.getTerritoryId('Test Sales Territory 3');
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 3', true);
    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = terr.Id,
        AssociationCause = 'Territory2Manual'
      );
    }
    List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', false);
    insert oppList;
    List<Opportunity> updatedOppList = [
      SELECT
        Id,
        Territory2.Primary_Account_Manager_Id__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        AccountId,
        Owner_Sync_Status__c,
        Lead_Sales_Engineer__c
      FROM Opportunity
    ];
    updatedOppList[0].Territory2 = terr;
    updatedOppList[0].Territory2Id = terr.Id;
    Test.startTest();
    OpportunityOwnerSyncBatch_ET batch = new OpportunityOwnerSyncBatch_ET();
    batch.execute(null, updatedOppList);
    Test.stopTest();
    System.assertEquals(
      'Synched: Opportunity Territory Update / New',
      [SELECT Owner_Sync_Status__c FROM Opportunity LIMIT 1][0]
      .Owner_Sync_Status__c
    );
  }

  public static testMethod void opportunityOwnerSyncWithNonSalesNFR() {
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 1', true);
    Territory2 terr1 = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    Territory2 partterr1 = TestFactory_ET.getTerritoryId('Test Partner Territory 1');
    Territory2 partterr2 = TestFactory_ET.getTerritoryId('Test Partner Territory 2');

    System.runAs(new User(Id = userinfo.getUserId())) {
      List<ObjectTerritory2Association> objList = new List<ObjectTerritory2Association>();

      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = partterr1.Id,
          AssociationCause = 'Territory2Manual'
        )
      );

      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = partterr2.Id,
          AssociationCause = 'Territory2Manual'
        )
      );

      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = terr1.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert objList;
    }
    List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', false);
    oppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_NFR;
    oppList[0].LeadSource = 'Webinar';
    oppList[0].StageName = 'Discovery';
    oppList[0].CloseDate = date.newInstance(2160, 2, 17);
    insert oppList;
    List<Opportunity> updatedOppList = [
      SELECT
        Id,
        Territory2.Primary_Account_Manager_Id__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        Account.RecordTypeId,
        AccountId,
        Owner_Sync_Status__c,
        Lead_Sales_Engineer__c
      FROM Opportunity
    ];
    updatedOppList[0].Territory2 = partterr2;
    updatedOppList[0].Territory2Id = partterr2.Id;
    Test.startTest();
    OpportunityOwnerSyncBatch_ET batch = new OpportunityOwnerSyncBatch_ET();
    batch.execute(null, updatedOppList);
    Test.stopTest();
    System.assertEquals(
      'Synched: Opportunity Territory Update / New',
      [SELECT Owner_Sync_Status__c FROM Opportunity LIMIT 1][0]
      .Owner_Sync_Status__c
    );
  }

  public static testMethod void opportunityOwnerSyncWithRPM() {
    Territory2 terr = TestFactory_ET.getTerritoryId('Test Sales Territory 4');
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 4', true);
    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = terr.Id,
        AssociationCause = 'Territory2Manual'
      );
    }
    List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', false);
    oppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_NFR;
    oppList[0].LeadSource = 'Webinar';
    oppList[0].StageName = 'Discovery';
    oppList[0].CloseDate = date.newInstance(2160, 2, 17);
    insert oppList;
    List<Opportunity> updatedOppList = [
      SELECT
        Id,
        Territory2.Primary_Account_Manager_Id__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        Account.RecordTypeId,
        AccountId,
        Owner_Sync_Status__c,
        Lead_Sales_Engineer__c
      FROM Opportunity
    ];
    updatedOppList[0].Territory2 = terr;
    updatedOppList[0].Territory2Id = terr.Id;
    Test.startTest();
    OpportunityOwnerSyncBatch_ET batch = new OpportunityOwnerSyncBatch_ET();
    batch.execute(null, updatedOppList);
    Test.stopTest();
    System.assertEquals(
      'Synched: Opportunity Territory Update / New',
      [SELECT Owner_Sync_Status__c FROM Opportunity LIMIT 1][0]
      .Owner_Sync_Status__c
    );
  }

  public static testMethod void opportunityOwnerSyncWithIAM() {
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 1', true);
    Territory2 terr = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = terr.Id,
        AssociationCause = 'Territory2Manual'
      );
    }
    List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', false);
    insert oppList;
    List<Opportunity> updatedOppList = [
      SELECT
        Id,
        Territory2.Primary_Account_Manager_Id__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        AccountId,
        Owner_Sync_Status__c,
        Lead_Sales_Engineer__c
      FROM Opportunity
    ];
    updatedOppList[0].Territory2 = terr;
    updatedOppList[0].Territory2Id = terr.Id;
    Test.startTest();
    OpportunityOwnerSyncBatch_ET batch = new OpportunityOwnerSyncBatch_ET();
    batch.execute(null, updatedOppList);
    Test.stopTest();
    System.assertEquals(
      'Synched: Opportunity Territory Update / New',
      [SELECT Owner_Sync_Status__c FROM Opportunity LIMIT 1][0]
      .Owner_Sync_Status__c
    );
  }

  public static testMethod void oppSyncWithAccountSecondTerr() {
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 1', true);
    Territory2 terr1 = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    Territory2 terr2 = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    System.runAs(new User(Id = userinfo.getUserId())) {
      List<ObjectTerritory2Association> objList = new List<ObjectTerritory2Association>();
      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = terr1.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = terr2.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert objList;
    }
    List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', false);
    insert oppList;
    Test.startTest();
    List<Opportunity> updatedOppList = [
      SELECT
        Id,
        Territory2.Primary_Account_Manager_Id__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        AccountId,
        Owner_Sync_Status__c,
        Lead_Sales_Engineer__c
      FROM Opportunity
    ];
    updatedOppList[0].Territory2 = terr2;
    updatedOppList[0].Territory2Id = terr2.Id;

    OpportunityOwnerSyncBatch_ET batch = new OpportunityOwnerSyncBatch_ET();
    batch.execute(null, updatedOppList);
    Test.stopTest();
    System.assertEquals(
      'Synched: Opportunity Territory Update / New',
      [SELECT Owner_Sync_Status__c FROM Opportunity LIMIT 1][0]
      .Owner_Sync_Status__c
    );
  }

  public static testMethod void oppSyncWithAccountFinish() {
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 1', true);
    Territory2 terr1 = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    Territory2 terr2 = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    System.runAs(new User(Id = userinfo.getUserId())) {
      List<ObjectTerritory2Association> objList = new List<ObjectTerritory2Association>();
      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = terr1.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = terr2.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert objList;
    }
    List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', false);
    insert oppList;
    Test.startTest();
    OpportunityOwnerSyncBatch_ET batch = new OpportunityOwnerSyncBatch_ET();
    batch.listOfExceptionOpportunities.addAll([SELECT Id, Account_Geo__c, Deal_Type__c, Name FROM Opportunity]);
    batch.finish(null);
    Test.stopTest();
  }
}