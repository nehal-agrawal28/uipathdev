@IsTest
public class LeadTriggerAllHandlerTest {
  @testSetup
  private static void setup() {
    Profile standard = [SELECT Id FROM profile WHERE Name = 'Standard User' LIMIT 1];
    User newUser = new User(
      profileId = standard.Id,
      username = 'testUser0@mail.com',
      email = 'pb@ff.com',
      emailencodingkey = 'UTF-8',
      localesidkey = 'en_US',
      languagelocalekey = 'en_US',
      timezonesidkey = 'America/Los_Angeles',
      alias = 'nuser',
      lastname = 'lastname',
      isactive = true
    );
    insert newUser;

    Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();

    // create accounts
    List<Account> accounts = new List<Account>{
      new account(
        Name = 'Google',
        Website = 'http://www.google.com',
        RecordTypeId = recordTypes.get('Customer').getRecordTypeId(),
        BillingCountry = 'United States',
        BillingCountryCode = 'US',
        BillingState = 'Idaho',
        Industry = 'Technology',
        ownerId = newUser.Id,
        Email_Domain__c = 'gmail1.com',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz123',
        Type = 'Business Partner',
        Business_Partner_Type__c = 'GSI'
      ),
      new account(
        Name = 'Google2',
        Website = 'http://www.google.com',
        BillingCountry = 'United States',
        BillingCountryCode = 'US',
        BillingState = 'Idaho',
        Industry = 'Technology',
        ownerId = newUser.Id,
        Email_Domain__c = 'gmail2.com',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz123',
        Type = 'Business Partner',
        Business_Partner_Type__c = 'VAR',
        RecordTypeId = recordTypes.get('Prospect').getRecordTypeId()
      ),
      new account(
        Name = 'Apple',
        Website = 'www.apple.com/ro',
        BillingCountry = 'United States',
        BillingCountryCode = 'US',
        BillingState = 'Idaho',
        Industry = 'Technology',
        Email_Domain__c = 'apple.com',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz213',
        Type = 'Business Partner',
        Business_Partner_Type__c = 'VAR',
        RecordTypeId = recordTypes.get('Prospect').getRecordTypeId()
      ),
      new account(
        Name = 'Facebook',
        BillingCountry = 'United States',
        BillingCountryCode = 'US',
        Industry = 'Technology',
        BillingState = 'Idaho',
        Email_Domain__c = 'facebook.com',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz312'
      ),
      new account(
        Name = 'NewTest',
        BillingCountry = 'United States',
        BillingCountryCode = 'US',
        BillingState = 'Idaho',
        Industry = 'Technology',
        Email_Domain__c = 'nt.com',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'zyx123'
      ),
      new account(
        Name = 'NewTest2',
        BillingCountry = 'China',
        BillingCountryCode = 'CN',
        BillingState = 'Hubei',
        Website = 'http://www.test2new.com',
        Industry = 'Technology',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz1231'
      )
    };
    insert accounts;

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Territory2Type territoryType = [SELECT Id FROM Territory2Type LIMIT 1];

      Territory2Model territoryModel = new Territory2Model();
      territoryModel.DeveloperName = 'UnitTest';
      territoryModel.Name = 'UnitTest';
      insert territoryModel;

      Territory2 territory = new Territory2(
        Sales_territory__c = true,
        DeveloperName = 'TestTerritory',
        Territory2ModelId = territoryModel.Id,
        Name = 'Test Territory',
        Territory2TypeId = territoryType.Id,
        Region__c = 'AMER Emerging Enterprise Region I'
      );
      insert territory;

      List<ObjectTerritory2Association> objectJunctions = new List<ObjectTerritory2Association>();
      for (Account recordContext : accounts) {
        objectJunctions.add(
          new ObjectTerritory2Association(
            ObjectId = recordContext.Id,
            Territory2Id = territory.Id,
            AssociationCause = 'Territory2Manual'
          )
        );
      }
      insert objectJunctions;

      UserTerritory2Association uAsoc = new UserTerritory2Association(
        Territory2Id = territory.Id,
        UserId = UserInfo.getUserId(),
        RoleInTerritory2 = 'Sales Development Rep'
      );
      insert uAsoc;
    }
    Id BusinessPartner = SObjectType.Lead.getRecordTypeInfosByDeveloperName()
      .get('Business_Partner_Onboarding')
      .getRecordTypeId();
    //create leads
    List<Lead> leads = new List<Lead>{
      new Lead(
        LastName = 'Test',
        Company = 'Google',
        Country = 'United States',
        CountryCode = 'US',
        Industry = 'Insurance',
        Status = 'New',
        Email = 'joe@NOT.com',
        Tier__c = '1',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz123'
      ),
      new Lead(
        LastName = 'Test Apple',
        Company = 'Apple',
        Country = 'United States',
        CountryCode = 'US',
        Industry = 'Insurance',
        Email = 'joe@apple.com',
        Status = 'Working',
        Tier__c = '1',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz213'
      ),
      new Lead(
        LastName = 'Test',
        Company = 'Dummy',
        Country = 'United States',
        CountryCode = 'US',
        Industry = 'Insurance',
        Email = 'new3.test@nt.com',
        Status = 'New',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz312'
      ),
      new Lead(
        LastName = 'Test',
        Company = 'NewT',
        Country = 'United States',
        CountryCode = 'US',
        Industry = 'Insurance',
        Status = 'Suspect',
        Email = 'new2.test@nt.com',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'zyx123'
      ),
      new Lead(
        LastName = 'Test2',
        Company = 'NewS',
        Country = 'China',
        CountryCode = 'CN',
        Industry = 'Insurance',
        Status = 'Suspect',
        Email = 'newtest@testnnew.com',
        RecordTypeId = BusinessPartner,
        Website = 'http://www.testnnew.com/ro/longurl',
        DNBoptimizer__DNB_D_U_N_S_Number__c = 'xyz1231'
      ),
      new Lead(
        LastName = 'TestLead',
        Company = 'Currency',
        Country = 'France',
        CountryCode = 'FR',
        Area__c = 'Southern Europe',
        Industry = 'Insurance',
        Status = 'New',
        Email = 'newtestcurrency@testnnew.com',
        RecordTypeId = BusinessPartner
      )
    };

    //inserting three at a time to check bulk logic
    insert leads;
  }

  @isTest
  public static void testSetOriginalMQLOwnerGroup() {
    Profile LeadDevelopmentProfile = [SELECT Id FROM profile WHERE Name = 'Lead Development' LIMIT 1];
    User newUserlDev = new User(
      profileId = LeadDevelopmentProfile.Id,
      username = 'testUserLeadDev0@mail.com',
      email = 'testUserLeadDev0@email.com',
      emailencodingkey = 'UTF-8',
      localesidkey = 'en_US',
      languagelocalekey = 'en_US',
      timezonesidkey = 'America/Los_Angeles',
      alias = 'ldev',
      lastname = 'Lead Development',
      isactive = true
    );
    insert newUserlDev;

    Profile SalesRepCPQProfile = [SELECT Id FROM profile WHERE Name = 'Sales Representative CPQ' LIMIT 1];
    User newUsersrep = new User(
      profileId = SalesRepCPQProfile.Id,
      username = 'testUserSalesRep0@mail.com',
      email = 'testUserSalesRep0@email.com',
      emailencodingkey = 'UTF-8',
      localesidkey = 'en_US',
      languagelocalekey = 'en_US',
      timezonesidkey = 'America/Los_Angeles',
      alias = 'srep',
      lastname = 'Sales Rep',
      isactive = true
    );
    insert newUsersrep;

    Id StandardRT = SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();

    Lead ldevLead = new Lead(
      LastName = 'LeadDev',
      Company = 'Lead Development',
      Country = 'China',
      CountryCode = 'CN',
      Industry = 'Insurance',
      Status = 'New',
      Email = 'newtestleaddev@testnnew.com',
      RecordTypeId = StandardRT
    );
    System.runAs(newUserlDev) {
      insert ldevLead;
    }

    Lead srepLead = new Lead(
      LastName = 'SalesRep',
      Company = 'Sales Representative',
      Country = 'China',
      CountryCode = 'CN',
      Industry = 'Insurance',
      Status = 'New',
      Email = 'newtestsalesRep@testnnew.com',
      RecordTypeId = StandardRT
    );
    System.runAs(newUsersrep) {
      insert srepLead;
    }

    Lead otherLead = new Lead(
      LastName = 'NormalUser',
      Company = 'Company',
      Country = 'China',
      CountryCode = 'CN',
      Industry = 'Insurance',
      Status = 'New',
      Email = 'newtestUser@testnnew.com',
      RecordTypeId = StandardRT
    );
    insert otherLead;
    Set<String> LastNameSet = new Set<String>{ 'NormalUser', 'SalesRep', 'LeadDev' };
    List<Lead> leads = [
      SELECT Id, LastName, OwnerId, Owner.Profile.Name, Original_MQL_Owner_Group__c
      FROM Lead
      WHERE LastName IN :LastNameSet
    ];
    for (Lead l : leads) {
      l.Status = 'MQL';
    }

    update leads;

    List<Lead> allleads = [
      SELECT Id, LastName, OwnerId, Owner.Profile.Name, Original_MQL_Owner_Group__c
      FROM Lead
      WHERE Id IN :leads
    ];
    for (Lead l : allleads) {
      if (l.Owner.Profile.Name == 'Lead Development') {
        system.assertEquals('BDR', l.Original_MQL_Owner_Group__c);
      } /*else {
          if(l.Owner.Profile.Name == 'Sales Representative CPQ') {
            system.assertEquals('Sales', l.Original_MQL_Owner_Group__c);
          } else {
            if((String.valueOf(l.OwnerId)).substring(0,3) != '00G') {
              system.assertEquals('Other', l.Original_MQL_Owner_Group__c);
            } else {
              system.assertEquals('Queue', l.Original_MQL_Owner_Group__c);
            }
          }
        }*/
    }
  }

  /* @isTest
  public static void testSetCurrencyToEuro() {
    Lead currencyLead = [SELECT Id, CurrencyIsoCode FROM Lead WHERE Company = 'Currency' LIMIT 1];
    system.assertEquals('EUR', currencyLead.CurrencyIsoCode);
  } */

  @isTest
  public static void testSetExistingAccount() {
    Set<Id> accountIds = new Set<Id>();

    for (Account recordContext : [SELECT id FROM account]) {
      accountIds.add(recordContext.Id);
    }
    Type accTerritoryTypeInstance = Type.forName('AccountsService_ET');
    IAccountTerritory accountTerritoryService = (IAccountTerritory) accTerritoryTypeInstance.newInstance();
    Map<Id, Territory2> account_RelatedTerritories = accountTerritoryService.getAccountPrimarySalesTerritory(
      accountIds
    );

    Account google = [
      SELECT Id, BillingCountry, BillingCountryCode, Geo__c, Region__c
      FROM Account
      WHERE name = 'Google'
      LIMIT 1
    ];
    Account apple = [
      SELECT Id, BillingCountry, BillingCountryCode, Geo__c, Region__c
      FROM Account
      WHERE name = 'Apple'
      LIMIT 1
    ];

    Lead googleLead = [
      SELECT Id, Account__c, Country, CountryCode, Website, Geo__c, Region_Text__c, Territory__c
      FROM Lead
      WHERE Company = 'Google'
      LIMIT 1
    ];

    //test where there is a domain and country match
    googleLead.Website = 'www.google.com';
    update googleLead;
    googleLead = [SELECT Id, Account__c, Country, Region_Text__c FROM Lead WHERE Id = :googleLead.Id];
    system.assertEquals(googleLead.Account__c, google.Id);

    // Ensure the matching region is Amer
    system.assertEquals(
      account_RelatedTerritories.get(googleLead.Account__c).Region__c.left(4),
      googleLead.Region_Text__c.left(4)
    );

    //test matching name but different country
    Lead appleLead = [
      SELECT Id, Account__c, Account__r.Name, Country, CountryCode, Region_Text__c, Territory__c, Territory_Id__c
      FROM Lead
      WHERE Company = 'Apple'
      LIMIT 1
    ];

    system.assertEquals(
      account_RelatedTerritories.get(appleLead.Account__c).Region__c.left(4),
      appleLead.Region_Text__c.left(4)
    );
    system.assertEquals(account_RelatedTerritories.get(appleLead.Account__c).Id, appleLead.Territory_Id__c);

    //test full match
    /*appleLead.Country = 'Canada';
     appleLead.CountryCode = 'CA';*/
    update appleLead;
    appleLead = [
      SELECT Id, Account__c, Country, Region_Text__c, Territory__c
      FROM Lead
      WHERE Company = 'Apple'
      LIMIT 1
    ];
    //system.assertEquals(apple.Id, appleLead.Account__c);

    //test where only email matches, company name was changed to Booble
    googleLead.Website = '';
    googleLead.email = 'henry@gmail1.com';
    update googleLead;
    googleLead = [SELECT Id, Account__c, Country FROM Lead WHERE Id = :googleLead.Id];
    system.assertEquals(google.Id, googleLead.Account__c);

    //test partial domain match
    googleLead.email = 'henry@oogle.com';
    googleLead.Website = '';
    update googleLead;
    googleLead = [SELECT Id, Account__c, Country FROM Lead WHERE Id = :googleLead.Id];
    //system.assertEquals(null, googleLead.Account__c);

    //test with inactive owner
    Test.startTest();
    deactivateUser();
    Test.stopTest();
  }

  @isTest
  static void testSetLeadNewToWorkingDuration() {
    string userTimezone = UserInfo.getTimeZone().getID();
    BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsActive = TRUE AND TimeZoneSidKey = :userTimezone LIMIT 1];
    system.assertNotEquals(bh, null);

    Lead googleLead = [SELECT Id, Status, New_Date_Time__c FROM Lead WHERE Company = 'Google' LIMIT 1];
    system.debug('googleLead ===> ' + googleLead.Status);
    googleLead.Status = 'New';
    update googleLead;

    googleLead = [SELECT Id, New_Date_Time__c FROM Lead WHERE Company = 'Google' LIMIT 1];
    system.debug('googleLead ===> ' + googleLead.New_Date_Time__c);
    test.startTest();
    googleLead.Working_Date_Time__c = BusinessHours.add(bh.Id, googleLead.New_Date_Time__c, 3600000);
    update googleLead;

    googleLead = [SELECT Id, Lead_New_To_Working_Duration_Hours__c FROM Lead WHERE Company = 'Google' LIMIT 1];
    System.assertEquals(math.round(googleLead.Lead_New_To_Working_Duration_Hours__c), 1);

    googleLead.Working_Date_Time__c = null;
    update googleLead;

    googleLead = [SELECT Id, Lead_New_To_Working_Duration_Hours__c FROM Lead WHERE Company = 'Google' LIMIT 1];
    System.assertEquals(googleLead.Lead_New_To_Working_Duration_Hours__c, null);

    test.stopTest();
  }

  @isTest
  static void testSetLeadWorkingToOtherDuration() {
    string userTimezone = UserInfo.getTimeZone().getID();
    BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsActive = TRUE AND TimeZoneSidKey = :userTimezone LIMIT 1];
    system.assertNotEquals(bh, null);

    Lead googleLead = [SELECT Id, CreatedDate FROM Lead WHERE Company = 'Google' LIMIT 1];

    test.startTest();
    googleLead.Working_Date_Time__c = System.now();
    googleLead.Working_To_Other_Status_Date_Time__c = BusinessHours.add(
      bh.Id,
      googleLead.Working_Date_Time__c,
      7200000
    );
    update googleLead;

    googleLead = [SELECT Id, Lead_Working_Duration_Business_Hours__c FROM Lead WHERE Company = 'Google' LIMIT 1];
    System.assertEquals(Math.round(googleLead.Lead_Working_Duration_Business_Hours__c), 2);

    googleLead.Working_To_Other_Status_Date_Time__c = null;
    update googleLead;

    googleLead = [SELECT Id, Lead_Working_Duration_Business_Hours__c FROM Lead WHERE Company = 'Google' LIMIT 1];
    System.assertEquals(googleLead.Lead_Working_Duration_Business_Hours__c, null);

    test.stopTest();
  }

  @isTest
  public static void testmoveLeadStatusToNew() {
    Lead NewLead2 = [SELECT Id, Tier__c, Status, Email FROM Lead WHERE Status IN ('New', 'Partner New') LIMIT 1];

    NewLead2.Progressed_to_MQL__c = true;
    update NewLead2;

    Lead newLead0 = [SELECT Id, Tier__c, Status, Email FROM Lead WHERE Id = :NewLead2.Id];
    system.assertEquals(newLead0.Status, 'New');
    newLead0.Status = 'Working';
    newLead0.Last_Change_Status_Date__c = Date.Today();
    update newLead0;

    Lead newLead1 = [SELECT Id, Tier__c, Status, Email FROM Lead WHERE Id = :NewLead2.Id];

    newLead1.Recycled_Reason__c = 'Not able to Contact';
    newLead1.Status = 'Recycle';
    update newLead1;

    newLead1.Disqualified_Reason__c = 'Unable to make contact';
    newLead1.Status = 'Disqualified';
    update newLead1;
  }

  @future
  private static void deactivateUser() {
    User testUser = [SELECT Id, IsActive FROM User WHERE UserName = 'testUser0@mail.com' LIMIT 1];
    testUser.isactive = false;
    update testUser;
  }

  @isTest
  public static void testSetRegionLead() {
    //setup data
    list<Lead> leadList = new List<Lead>();

    Lead l0 = new Lead(
      LastName = 'Test',
      Company = 'Tester',
      Email = 'test1@test.com',
      CountryCode = 'US',
      Industry = 'Insurance'
    );

    leadList.add(l0);

    Lead l1 = new Lead(
      LastName = 'Test',
      Company = 'Tester',
      Email = 'test2@test.com',
      CountryCode = 'US',
      StateCode = 'SD'
    );

    leadList.add(l1);

    Lead l2 = new Lead(
      LastName = 'Test',
      Company = 'Tester',
      Email = 'test3@test.com',
      CountryCode = 'US',
      PostalCode = '15001'
    );

    leadList.add(l2);

    Lead l3 = new Lead(LastName = 'Test', Company = 'Tester', Email = 'test4@test.com', CountryCode = 'US');

    leadList.add(l3);

    Lead l4 = new Lead(LastName = 'Test', Company = 'Tester', Email = 'test5@test.com', CountryCode = 'PK');

    leadList.add(l4);

    Lead l5 = new Lead(LastName = 'Test', Company = 'Tester', Email = 'test6@test.com', CountryCode = 'PK');

    leadList.add(l5);

    Lead l6 = new Lead(
      LastName = 'Test',
      Company = 'Tester',
      Email = 'test7@test.com',
      CountryCode = 'US',
      Industry = 'Insurance'
    );

    leadList.add(l6);

    Lead l7 = new Lead(
      LastName = 'Test',
      Company = 'Tester',
      Email = 'test8@test.com',
      CountryCode = 'JP',
      Industry = 'Insurance'
    );

    leadList.add(l7);

    //do the tests
    test.startTest();

    insert leadList;

    Lead lTmp = [SELECT id, CountryCode FROM Lead WHERE id = :l5.Id];

    lTmp.CountryCode = 'US';
    lTmp.Industry = 'Insurance';
    update lTmp;

    test.stopTest();

    //verify the results
    list<Lead> leadListNew = [SELECT id, Geo__c, Region_Text__c, Territory__c, Area__c FROM Lead WHERE id IN :leadList];
    map<Id, Lead> leadMapNew = new Map<Id, Lead>(leadListNew);

    System.assertEquals(8, leadListNew.size());
    System.assertEquals('AMER', leadMapNew.get(l0.Id).Geo__c);
    System.assertEquals('Pacific Northwest', leadMapNew.get(l1.Id).Region_Text__c);
    System.assertEquals('Pacific Northwest', leadMapNew.get(l1.Id).Territory__c);
    System.assertEquals('NorthCentral East', leadMapNew.get(l2.Id).Region_Text__c);
    System.assertEquals('Territory Unknown', leadMapNew.get(l3.Id).Region_Text__c);
    System.assertEquals('Territory Unknown', leadMapNew.get(l3.Id).Region_Text__c);
    System.assertEquals('EMEA', leadMapNew.get(l4.Id).Geo__c);
    System.assertEquals('AMER', leadMapNew.get(l5.Id).Geo__c);
    System.assertEquals('East', leadMapNew.get(l6.Id).Area__c);
  }

  // ==================================================================================
  // testing LeadSetAccountFunction.cls =================================
  // ==================================================================================
  @isTest
  private static void LeadSetAccountFunctionOnUpdateTest() {
    Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Lead.getRecordTypeInfosByName();
    Lead l = new Lead(
      RecordTypeId = recordTypes.get('Standard').getRecordTypeId(),
      LastName = 'Test',
      Country = 'United States',
      CountryCode = 'US',
      Company = 'Google',
      Status = 'Sales Generated',
      OwnerId = UserInfo.getUserId(),
      Website = 'www.google2.com',
      Email = 'test@google1.com'
    );
    insert l;

    l.Website = 'www.google.com';
    update l;

    List<Lead> lead = [SELECT Id, Account__c, Account__r.Name FROM Lead WHERE Id = :l.Id LIMIT 1];
    system.assertEquals('Google', lead[0].Account__r.Name);
  }
}