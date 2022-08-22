@isTest
public class AccountQueueableTest_ET {
  @Testsetup
  static void setup() {
    User objUser = new User();
    objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Success Manager'].Id;
    objUser.Username = 'test839734@uiath.com';
    objUser.LastName = 'Test';
    objUser.Email = 'test839734@uiath.com';
    objUser.Alias = 't839734';
    objUser.TimeZoneSidKey = 'America/Los_Angeles';
    objUser.LocaleSidKey = 'en_US';
    objUser.EmailEncodingKey = 'UTF-8';
    objUser.LanguageLocaleKey = 'en_US';
    insert objUser;
    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 regionTerr1 = TestFactory_ET.initTerritory('Geo1', 'Area1', 'Region1');
    Territory2 salesTerr1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');
    Territory2 salesTerr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 2');

    Territory2Type CSMTerrType = [
      SELECT Id, DeveloperName
      FROM Territory2Type
      WHERE MasterLabel = :ETMConstant.CUSTOMER_SUCCESS
    ];
    regionTerr1.Territory2TypeId = CSMTerrType.Id;
    update regionTerr1;
  }

  public static testMethod void populateCSMTerritoryTest() {
    Id csmUserId;
    try {
      csmUserId = [SELECT Id FROM User WHERE Profile.Name = 'Customer Success Manager' AND IsActive = TRUE LIMIT 1].Id;
    } catch (Exception e) {
      csmUserId = UserInfo.getUserId();
    }

    Territory2 regTerr2 = TestFactory_ET.getTerritoryId('Region1');

    System.runAs(new User(Id = Userinfo.getUserId())) {
      TestFactory_ET.createUserTerritoryAssociation(regTerr2.Id, csmUserId, ETMConstant.CUSTOMER_SUCCESS_MANAGER);
    }

    Account acc = new Account();
    acc.Name = 'Child Account';
    acc.BillingPostalCode = '012346';
    acc.BillingCountry = 'United States';
    acc.BillingCountryCode = 'US';
    acc.Industry = 'Engineering';
    insert acc;

    acc.CSM__c = csmUserId;
    update acc;

    Test.startTest();
    new AccountQueueable_ET(new List<Account>{ acc }, new Map<Id, SObject>{ acc.Id => acc }).work();
    Test.stopTest();
    ObjectTerritory2Association csmOTA = [
      SELECT Id, ObjectId, Territory2Id
      FROM ObjectTerritory2Association
      WHERE Territory2Id = :regTerr2.Id
      LIMIT 1
    ];
    System.assertEquals(csmOTA.ObjectId, acc.Id);
  }

  /*public static testMethod void accountTriggerTest() {
    String classification = 'KAP I Sales 1';
    String territoryName = 'AMER KAP I Sales 1';
    TestFactory_ET.init(classification);
    List<Account> acc = TestFactory_ET.createAccounts(1, 'Customer', classification, false);
    acc[0].ParentId = [SELECT Id FROM Account LIMIT 1][0].Id;
    acc[0].Name = 'Child Account';
    insert acc;
    Test.startTest();
    AccountQueueable_ET accountQueueable = new AccountQueueable_ET(acc, null);
    accountQueueable.execute(null);
    Test.stopTest();
  }*/
}