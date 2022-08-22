@isTest
public class AccountsServiceTest_ET {
  @testSetup
  static void setup() {
    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 salesTerr1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1');
    Territory2 salesTerr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 2');
  }

  public static testMethod void accountTriggerTest() {
    TestFactory_ET.createTerritoryPostalCodeMapping(
      new Map<String, String>{ 'US-012345' => 'Test Sales Territory 1', 'US-012346' => 'Test Sales Territory 2' },
      false
    );

    List<Account> acc = TestFactory_ET.createAccounts(2, 'Customer', 'Test Sales Territory 1', false);
    insert acc[0];

    acc[1].ParentId = acc[0].Id;
    acc[1].Name = 'Child Account';
    acc[1].BillingPostalCode = '012346';
    acc[1].BillingCountry = 'United States';
    acc[1].BillingCountryCode = 'US';
    insert acc[1];

    Test.startTest();
    acc[1].BillingPostalCode = '012345';
    acc[1].Sync_Static_Fields__c = true;
    update acc[1];

    Test.stopTest();
    // It should be same as parent's territory mapping
    System.assertEquals(
      [SELECT Territory_Postal_Code_Mapping__c FROM Account WHERE Id = :acc[0].Id][0]
      .Territory_Postal_Code_Mapping__c,
      null
    );
  }

  public static testMethod void accountTriggerParentOverridetrueTest() {
    String classification = 'Test Sales Territory 1';

    TestFactory_ET.createTerritoryPostalCodeMapping(
      new Map<String, String>{ 'US-012345' => 'Test Sales Territory 1', 'US-012346' => 'Test Sales Territory 2' },
      false
    );
    System.runAs(new User(Id = Userinfo.getUserId())) {
      TestFactory_ET.createUserTerritoryAssociation(
        TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id,
        UserInfo.getUserId(),
        ''
      );
    }
    List<Account> acc = TestFactory_ET.createAccounts(2, 'Customer', classification, false);
    insert acc[0];

    acc[1].ParentId = acc[0].Id;
    acc[1].Name = 'Child Account';
    acc[1].BillingPostalCode = '012346';
    acc[1].BillingCountry = 'United States';
    acc[1].BillingCountryCode = 'US';
    acc[1].Parent_Territory_Override__c = true;

    Test.startTest();
    insert acc[1];
    ObjectTerritory2Association objTerrAss = new ObjectTerritory2Association();
    objTerrAss.ObjectId = acc[1].Id;
    objTerrAss.AssociationCause = 'Territory2Manual';
    objTerrAss.Territory2Id = TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id;
    insert objTerrAss;
    AccountsService_ET accountService = (AccountsService_ET) Application_ET.Service.newInstance(
      AccountsService_ET.class
    );
    accountService.getValidAccountTerritory(new Set<Id>{ acc[1].Id });
    accountService.getAccountSalesTerritories(new Set<Id>{ acc[1].Id });
    accountService.getAccountTerritories(new Set<Id>{ acc[1].Id });
    Test.stopTest();
    // It should be of child territory mapping
    System.assertEquals(
      [SELECT Territory_Postal_Code_Mapping__c FROM Account WHERE Id = :acc[1].Id][0]
      .Territory_Postal_Code_Mapping__c,
      null
    );
  }

  public static testMethod void accountTriggerTwoTerritoryforCreatorTest() {
    System.runAs(new User(Id = Userinfo.getUserId())) {
      TestFactory_ET.createUserTerritoryAssociation(
        TestFactory_ET.getTerritoryId('Test Sales Territory 1').Id,
        UserInfo.getUserId(),
        ''
      );
      TestFactory_ET.createUserTerritoryAssociation(
        TestFactory_ET.getTerritoryId('Test Sales Territory 2').Id,
        UserInfo.getUserId(),
        ''
      );
    }
    List<Account> acc = TestFactory_ET.createAccounts(2, 'Customer', '', false);
    acc[0].BillingCountry = 'United States';
    acc[0].BillingCountryCode = 'US';
    insert acc[0];

    acc[1].ParentId = acc[0].Id;
    acc[1].Name = 'Child Account';
    acc[1].BillingPostalCode = '012346';
    acc[1].BillingCountry = 'United States';
    acc[1].BillingCountryCode = 'US';
    acc[1].Parent_Territory_Override__c = false;

    Test.startTest();
    insert acc[1];

    Test.stopTest();
    // It should be of child territory mapping
    System.assertEquals(
      [SELECT Named_List_Assignment__c FROM Account WHERE Id = :acc[1].Id][0]
      .Named_List_Assignment__c,
      ETMConstant.UNABLE_TO_DEFAULT_NAMED_LIST_ASSIGNMENT
    );
  }
}