@isTest
public with sharing class LeadOwnerSyncBatchTest {
  @TestSetup
  static void makeData() {
    Account acc = new account(
      Name = 'Google',
      Website = 'http://www.google.com',
      BillingCountry = 'United States',
      BillingCountryCode = 'US',
      BillingState = 'Idaho',
      Industry = 'Technology',
      ownerId = UserInfo.getUserId(),
      Email_Domain__c = 'gmail1.com',
      DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz123'
    );
    insert acc;
    Territory2 territory;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      User objUser = new User();
      objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
      objUser.Username = 'test839734@uiath.com';
      objUser.LastName = 'Test';
      objUser.Email = 'test839734@uiath.com';
      objUser.Alias = 't839734';
      objUser.TimeZoneSidKey = 'America/Los_Angeles';
      objUser.LocaleSidKey = 'en_US';
      objUser.EmailEncodingKey = 'UTF-8';
      objUser.LanguageLocaleKey = 'en_US';
      insert objUser;
      Territory2Type territoryType = [SELECT Id FROM Territory2Type LIMIT 1];

      Territory2Model territoryModel = new Territory2Model();
      territoryModel.DeveloperName = 'UnitTest';
      territoryModel.Name = 'UnitTest';
      insert territoryModel;

      territory = new Territory2(
        Sales_Territory__c = true,
        DeveloperName = 'TestTerritory',
        Territory2ModelId = territoryModel.Id,
        Name = 'Test Territory',
        Territory2TypeId = territoryType.Id
      );
      insert territory;

      ObjectTerritory2Association tAsoc = new ObjectTerritory2Association(
        ObjectId = acc.id,
        Territory2Id = territory.Id,
        AssociationCause = 'Territory2Manual'
      );
      insert tAsoc;
    }

    Lead le = new Lead(
      LastName = 'Test',
      RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId(),
      Company = 'Google',
      Country = 'United States',
      CountryCode = 'US',
      Industry = 'Insurance',
      Status = 'MQL',
      Email = 'joe@NOT.com',
      Website = 'http://www.google.com',
      Tier__c = '1',
      DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz123',
      Account__c = acc.Id,
      Territory_Id__c = territory.Id
    );

    insert le;
  }

  @isTest
  private static void runBatch() {
    Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
    Id territoryId = [SELECT Id FROM Territory2 WHERE Name = 'Test Territory' LIMIT 1].Id;
    Id userId = [SELECT id FROM user WHERE username = 'test839734@uiath.com'][0].Id;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      UserTerritory2Association uAsoc = new UserTerritory2Association(
        Territory2Id = territoryId,
        UserId = userId,
        RoleInTerritory2 = 'Sales Development Rep'
      );
      insert uAsoc;
    }
    Test.startTest();
    database.executeBatch(new LeadOwnerSyncBatch());
    Test.stopTest();
    // Assert
    Lead leadRecord = [SELECT Id, OwnerId, Owner.Name FROM Lead LIMIT 1];
    System.assertEquals(userId, leadRecord.OwnerId);
  }

  @isTest
  private static void runBatchIAM() {
    Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
    Id territoryId = [SELECT Id FROM Territory2 WHERE Name = 'Test Territory' LIMIT 1].Id;
    Id userId = [SELECT id FROM user WHERE username = 'test839734@uiath.com'][0].Id;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      UserTerritory2Association uAsoc = new UserTerritory2Association(
        Territory2Id = territoryId,
        UserId = userId,
        RoleInTerritory2 = ETMConstant.INTERIM_ACCOUNT_MANAGER
      );
      insert uAsoc;
    }
    Test.startTest();
    database.executeBatch(new LeadOwnerSyncBatch());
    Test.stopTest();
    // Assert
    Lead leadRecord = [SELECT Id, OwnerId, Owner.Name FROM Lead LIMIT 1];
    System.assertEquals(userId, leadRecord.OwnerId);
  }
}