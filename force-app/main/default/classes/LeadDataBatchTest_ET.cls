@isTest
public class LeadDataBatchTest_ET {
  @testSetup
  static void setup() {
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

    Territory2 regionTerr = TestFactory_ET.getTerritoryId('AMER Enterprise Midwest');
    Territory2 salesTerr = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory');

    TestFactory_ET.createUserTerritoryAssociation(salesTerr.Id, objUser.Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
    List<Account> accountList;

    System.runAs(new User(Id = userinfo.getUserId())) {
      accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory', false);
      accountList[0].Name = 'Google';
      accountList[0].Website = 'http://www.google.com';
      accountList[0].BillingCountry = 'United States';
      accountList[0].BillingCountryCode = 'US';
      accountList[0].BillingState = 'Idaho';
      accountList[0].Industry = 'Technology';
      accountList[0].ownerId = UserInfo.getUserId();
      accountList[0].Email_Domain__c = 'gmail1.com';
      accountList[0].DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz123';
      insert accountList;
    }
    System.runAs(new User(Id = userinfo.getUserId())) {
      Lead le = new Lead(
        LastName = 'Test',
        Company = 'Google',
        Country = 'United States',
        CountryCode = 'US',
        Industry = 'Insurance',
        Status = 'New',
        Email = 'joe@NOT.com',
        Website = 'http://www.google.com',
        Tier__c = '1',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz123',
        Account__c = accountList[0].Id,
        Overwrite_Account_Match__c = true
      );
      insert le;
    }

    System.runAs(new User(Id = userinfo.getUserId())) {
      insert new ObjectTerritory2Association(
        ObjectId = accountList[0].Id,
        Territory2Id = salesTerr.Id,
        AssociationCause = 'Territory2Manual'
      );
      UserTerritory2Association RVPUTA = TestFactory_ET.createUserTerritoryAssociation(
        salesTerr.Id,
        Userinfo.getUserId(),
        ETMConstant.PRIMARY_ACCOUNT_MANAGER
      );
      UserTerritory2Association RVPUTA2 = TestFactory_ET.createUserTerritoryAssociation(
        salesTerr.Id,
        Userinfo.getUserId(),
        ETMConstant.SALES_DEVELOPMENT_REP
      );
    }

  }

  private static testMethod void updateLead() {
    Test.startTest();
    LeadDataBatch_ET batch = new LeadDataBatch_ET();
    batch.execute(
      null,
      [SELECT Id, OwnerId, Account__c, Territory_Id__c, Territory_Name__c, Geo__c, Area__c, Region_Text__c FROM Lead]
    );
    Test.stopTest();
    List<Lead> lead = [
      SELECT Id, OwnerId, Account__c, Territory_Id__c, Territory_Name__c, Geo__c, Area__c, Region_Text__c
      FROM Lead
    ];
    system.debug('lead' + lead[0].Territory_Name__c);
    //System.assertEquals('Test Sales Territory', lead[0].Territory_Name__c, 'Territory details associated to Lead');
  }
}