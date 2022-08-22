/**
 * @AUTHOR: UIPath
 * @DATE: 07/09/2021
 * @DESCRIPTION: This is the test class for OpportunityTerritoryAssignment
 */
@isTest
public class OpportunityTerritoryAssignmentTest {
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
    Territory2 terr5 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 5');

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

    TestFactory_ET.createUserTerritoryAssociation(terr1.Id, userList[0].Id, ETMConstant.INTERIM_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr2.Id, userList[0].Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr3.Id, userList[1].Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr4.Id, userList[0].Id, ETMConstant.REGION_PARTNER_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr5.Id, userList[1].Id, ETMConstant.REGION_PARTNER_MANAGER);

    TestFactory_ET.createUserTerritoryAssociation(
      partnerterr1.Id,
      userList[2].Id,
      ETMConstant.DISTRIBUTION_PARTNER_MANAGER
    );
    TestFactory_ET.createUserTerritoryAssociation(
      partnerterr2.Id,
      userList[2].Id,
      ETMConstant.STRATEGIC_PARTNER_MANAGER
    );
    // TestFactory_ET.createUserTerritoryAssociation(partnerterr3.Id, userList[5].Id, ETMConstant.REGION_PARTNER_MANAGER);
  }

  // Creator has one territory
  public static testMethod void oppTerrAssignmentCreatorTerr1() {
    User user = [SELECT id FROM user WHERE username = 'test839734@2uiath.com'][0];
    OpportunityTerritoryAssignment filter = new OpportunityTerritoryAssignment();
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 3', true);
    Territory2 terr3 = TestFactory_ET.getTerritoryId('Test Sales Territory 3');
    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = terr3.Id,
        AssociationCause = 'Territory2Manual'
      );
    }
    List<Id> oppIds = new List<Id>();
    System.runAs(user) {
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', true);

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
      }
    }
    Test.startTest();
    Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(oppIds);
    Test.stopTest();
    System.assertEquals(2, result.size());
  }

  public static testMethod void oppTerrAssignmentCreator0TerrTest() {
    User user1 = [SELECT id FROM user WHERE username = 'test839734@1uiath.com'][0];
    User user2 = [SELECT id FROM user WHERE username = 'test839734@2uiath.com'][0];
    OpportunityTerritoryAssignment filter = new OpportunityTerritoryAssignment();

    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 3', true);
    Territory2 terr1 = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    Territory2 terr2 = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    Territory2 terr3 = TestFactory_ET.getTerritoryId('Test Sales Territory 3');
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
    List<Id> oppIds = new List<Id>();
    System.runAs(user2) {
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', true);

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
      }
    }

    Test.startTest();
    Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(oppIds);
    Test.stopTest();
    System.assertEquals(terr1.Id, result.get(oppIds[0]));
  }

  public static testMethod void oppTerrAssignmentNFRCreatorRPMTest() {
    User user1 = [SELECT id FROM user WHERE username = 'test839734@3uiath.com'][0];
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 4', true);
    Territory2 terr1 = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    Territory2 terr4 = TestFactory_ET.getTerritoryId('Test Sales Territory 4');

    System.runAs(new User(Id = userinfo.getUserId())) {
      List<ObjectTerritory2Association> objList = new List<ObjectTerritory2Association>();
      /* objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = terr1.Id,
          AssociationCause = 'Territory2Manual'
        )
      );*/
      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = terr4.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert objList;
    }
    List<Id> oppIds = new List<Id>();
    System.runAs(user1) {
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[0].Id, 'UiPath_Standard', false);
      oppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_NFR;
      oppList[0].LeadSource = 'Webinar';
      oppList[0].StageName = 'Discovery';
      oppList[0].CloseDate = date.newInstance(2160, 2, 17);
      insert oppList;

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
      }
    }
    Test.startTest();
    OpportunityTerritoryAssignment filter = new OpportunityTerritoryAssignment();
    Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(oppIds);
    Test.stopTest();

    System.assertEquals(terr4.Id, result.get(oppIds[0]));
  }

  public static testMethod void oppTerrAssignmentNFRAccountRPMTest() {
    User user1 = [SELECT id FROM user WHERE username = 'test839734@1uiath.com'][0];
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 5', true);
    Territory2 terr1 = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    Territory2 terr5 = TestFactory_ET.getTerritoryId('Test Sales Territory 5');

    System.runAs(new User(Id = userinfo.getUserId())) {
      List<ObjectTerritory2Association> objList = new List<ObjectTerritory2Association>();

      objList.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = terr5.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert objList;
    }
    List<Id> oppIds = new List<Id>();
    System.runAs(user1) {
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[0].Id, 'UiPath_Standard', false);
      oppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_NFR;
      oppList[0].LeadSource = 'Webinar';
      oppList[0].StageName = 'Discovery';
      oppList[0].CloseDate = date.newInstance(2160, 2, 17);
      insert oppList;

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
      }
    }
    Test.startTest();
    OpportunityTerritoryAssignment filter = new OpportunityTerritoryAssignment();
    Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(oppIds);
    Test.stopTest();

    System.assertEquals(terr5.Id, result.get(oppIds[0]));
  }

  public static testMethod void oppTerrAssignmentCreatorPartnerAccountTest() {
    User user1 = [SELECT id FROM user WHERE username = 'test839734@3uiath.com'][0];
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 1', true);
    Territory2 terr1 = TestFactory_ET.getTerritoryId('Test Sales Territory 1');
    Territory2 partterr1 = TestFactory_ET.getTerritoryId('Test Partner Territory 1');

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
          Territory2Id = terr1.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert objList;
      system.debug('objList' + objList);
    }
    List<Id> oppIds = new List<Id>();
    System.runAs(user1) {
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[0].Id, 'UiPath_Standard', false);
      oppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_NFR;
      oppList[0].LeadSource = 'Webinar';
      oppList[0].StageName = 'Discovery';
      oppList[0].CloseDate = date.newInstance(2160, 2, 17);
      insert oppList;

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
      }
    }
    Test.startTest();

    OpportunityTerritoryAssignment filter = new OpportunityTerritoryAssignment();
    Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(oppIds);
    Test.stopTest();

    System.assertEquals(partterr1.Id, result.get(oppIds[0]));
  }

  public static testMethod void oppTerrAssignmentCreatorPartnerAccountMultipleTerrTest() {
    User user1 = [SELECT id FROM user WHERE username = 'test839734@3uiath.com'][0];
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
    List<Id> oppIds = new List<Id>();
    System.runAs(user1) {
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[0].Id, 'UiPath_Standard', false);
      oppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_NFR;
      oppList[0].LeadSource = 'Webinar';
      oppList[0].StageName = 'Discovery';
      oppList[0].CloseDate = date.newInstance(2160, 2, 17);
      insert oppList;

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
      }
    }
    Test.startTest();

    OpportunityTerritoryAssignment filter = new OpportunityTerritoryAssignment();
    Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(oppIds);
    Test.stopTest();

    System.assertEquals(partterr2.Id, result.get(oppIds[0]));
  }

  public static testMethod void oppTerrAssignmentPartnerAccountMultipleTerrTest() {
    User user1 = [SELECT id FROM user WHERE username = 'test839734@4uiath.com'][0];
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
    List<Id> oppIds = new List<Id>();
    System.runAs(user1) {
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[0].Id, 'UiPath_Standard', false);
      oppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_NFR;
      oppList[0].LeadSource = 'Webinar';
      oppList[0].StageName = 'Discovery';
      oppList[0].CloseDate = date.newInstance(2160, 2, 17);
      insert oppList;

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
      }
    }
    Test.startTest();

    OpportunityTerritoryAssignment filter = new OpportunityTerritoryAssignment();
    Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(oppIds);
    Test.stopTest();

    System.assertEquals(partterr2.Id, result.get(oppIds[0]));
  }

  public static testMethod void oppTerrAssignmentCreator2TerrTest() {
    User user1 = [SELECT id FROM user WHERE username = 'test839734@1uiath.com'][0];
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 3', true);
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
    List<Id> oppIds = new List<Id>();
    System.runAs(user1) {
      List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', true);

      for (Opportunity opp : oppList) {
        oppIds.add(opp.Id);
      }
    }

    Test.startTest();
    OpportunityTerritoryAssignment filter = new OpportunityTerritoryAssignment();
    Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(oppIds);
    Test.stopTest();
    System.assertEquals(terr1.Id, result.get(oppIds[0]));
  }
}