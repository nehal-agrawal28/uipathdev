@isTest
public class OpportunityDataBatchTest_ET {
  @testSetup
  static void setup() {
    Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    List<User> userList = new List<User>();

    for (Integer i = 1; i < 3; i++) {
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

    TestFactory_ET.createUserTerritoryAssociation(terr1.Id, userList[0].Id, ETMConstant.INTERIM_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr2.Id, userList[0].Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
    TestFactory_ET.createUserTerritoryAssociation(terr3.Id, userList[1].Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
  }

  public static testMethod void oppTerrSyncWithOwnerTerr() {
    List<User> userList = [SELECT id FROM user WHERE username IN ('test839734@1uiath.com', 'test839734@2uiath.com')];
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 3', true);
    Territory2 terr3 = TestFactory_ET.getTerritoryId('Test Sales Territory 3');

    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = terr3.Id,
        AssociationCause = 'Territory2Manual'
      );
    }

    List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', false);
    oppList[0].OwnerId = userList[1].Id;
    oppList[1].OwnerId = userList[1].Id;
    insert oppList;
    oppList[1].StageName = 'Closed Won Booked';
    update oppList[1];

    Opportunity_Split__c split = new Opportunity_Split__c();
    split.Opportunity__c = oppList[1].Id;
    split.User__c = userList[1].Id;
    insert split;

    Test.startTest();
    OpportunityDataBatch_ET batch = new OpportunityDataBatch_ET();
    batch.execute(null, oppList);
    Test.stopTest();
    system.assertNotEquals(
      null,
      [SELECT Territory_Reason__c FROM Opportunity_Split__c WHERE Id = :split.Id LIMIT 1][0]
      .Territory_Reason__c,
      'Territory Reason is not update in Opportunity Split'
    );
    //system.assertEquals([Select Territory2Id from Opportunity  LIMIT 1][0].Territory2Id, terr3.Id, 'Territory associated to Opportunity');
  }

  public static testMethod void oppsplitNoTerrTerr() {
    List<User> userList = [SELECT id FROM user WHERE username IN ('test839734@1uiath.com', 'test839734@2uiath.com')];
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 3', true);
    Territory2 terr3 = TestFactory_ET.getTerritoryId('Test Sales Territory 3');

    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = terr3.Id,
        AssociationCause = 'Territory2Manual'
      );
    }

    List<Opportunity> oppList = TestFactory_ET.createOpportunities(2, accountList[0].Id, 'CPQ_Default', false);
    oppList[0].OwnerId = userList[1].Id;
    oppList[1].OwnerId = userList[1].Id;
    insert oppList;
    oppList[1].StageName = 'Closed Won Booked';
    update oppList[1];

    Opportunity_Split__c split = new Opportunity_Split__c();
    split.Opportunity__c = oppList[1].Id;
    split.User__c = userList[0].Id;
    insert split;

    Test.startTest();
    OpportunityDataBatch_ET batch = new OpportunityDataBatch_ET();
    batch.execute(null, oppList);
    Test.stopTest();
    system.assertEquals(
      null,
      [SELECT Territory_Id__c FROM Opportunity_Split__c WHERE Id = :split.Id LIMIT 1][0]
      .Territory_Id__c,
      'Territory Id should be blank'
    );
    //system.assertEquals([Select Territory2Id from Opportunity  LIMIT 1][0].Territory2Id, terr3.Id, 'Territory associated to Opportunity');
  }
}